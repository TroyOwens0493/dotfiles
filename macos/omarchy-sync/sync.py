#!/usr/bin/env python3
"""Copy committed Git state from Omarchy. Never reset, stash, clean, or push."""

import argparse
import fcntl
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys

INVENTORY = r'''
import json, os, subprocess, sys
from pathlib import Path
def git(path, *args):
    return subprocess.check_output(['git', '-C', str(path), *args], text=True).strip()
items = []
for root in sys.argv[1:]:
    base = Path.home() / root
    if not base.is_dir():
        raise RuntimeError('Missing remote directory: ' + str(base))
    for path, dirs, files in os.walk(base):
        dirs[:] = sorted(d for d in dirs if not d.startswith('.') and d not in {'node_modules', 'vendor', 'artifacts'})
        path = Path(path)
        if not (path / '.git').exists():
            continue
        dirs[:] = []
        branch = subprocess.run(['git', '-C', str(path), 'symbolic-ref', '--quiet', '--short', 'HEAD'], text=True, capture_output=True).stdout.strip()
        origin = subprocess.run(['git', '-C', str(path), 'remote', 'get-url', 'origin'], text=True, capture_output=True).stdout.strip()
        items.append(dict(relative=str(path.relative_to(Path.home())), path=str(path), branch=branch,
                          commit=git(path, 'rev-parse', '--verify', 'HEAD'), origin=origin,
                          common=git(path, 'rev-parse', '--path-format=absolute', '--git-common-dir')))
print(json.dumps(items))
'''

SSH_OPTIONS = ['-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
               '-o', 'ServerAliveInterval=15', '-o', 'ServerAliveCountMax=2']


class Skip(Exception):
    pass


def run(args, *, cwd=None, input=None):
    result = subprocess.run(args, cwd=cwd, input=input, text=True, capture_output=True,
                            timeout=180)
    if result.returncode:
        raise Skip((result.stderr or result.stdout or 'Command failed').strip())
    return result.stdout.strip()


def git(path, *args):
    # Disable automatic stashing and repository hooks for unattended updates.
    return run(['git', '-c', 'core.hooksPath=/dev/null', '-c', 'merge.autoStash=false',
                '-c', 'submodule.recurse=false', '-C', str(path), *args])


def optional_git(path, *args):
    try:
        return git(path, *args)
    except Skip:
        return ''


def ancestor(path, old, new):
    return subprocess.run(['git', '-C', str(path), 'merge-base', '--is-ancestor', old, new],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def clean(path):
    if git(path, 'status', '--porcelain', '--untracked-files=all'):
        raise Skip('local changes or untracked files')
    for name in ('MERGE_HEAD', 'CHERRY_PICK_HEAD', 'REVERT_HEAD', 'rebase-merge', 'rebase-apply', 'BISECT_START'):
        marker = Path(git(path, 'rev-parse', '--git-path', name))
        if not marker.is_absolute():
            marker = path / marker
        if marker.exists():
            raise Skip('a Git operation is in progress')


def local_path(home, relative, roots):
    rel = Path(relative)
    if rel.is_absolute() or '..' in rel.parts or not rel.parts or rel.parts[0] not in roots:
        raise Skip('invalid remote path')
    path = home / rel
    if path.resolve() != path:
        raise Skip('local path contains a symbolic link')
    return path


def check_target(path, branch, commit):
    if not branch:
        raise Skip('remote checkout has detached HEAD')
    git(path, 'check-ref-format', '--branch', branch)
    previous = optional_git(path, 'rev-parse', '--verify', 'refs/heads/' + branch)
    if previous and not ancestor(path, previous, commit):
        raise Skip('local target branch has commits absent from Omarchy')
    return previous


def update(path, branch, commit):
    clean(path)
    if not optional_git(path, 'merge-base', 'HEAD', commit):
        raise Skip('local checkout and Omarchy have unrelated histories')
    previous = check_target(path, branch, commit)
    current = optional_git(path, 'symbolic-ref', '--quiet', '--short', 'HEAD')
    if not current and not ancestor(path, git(path, 'rev-parse', 'HEAD'), commit):
        raise Skip('local detached HEAD has commits absent from Omarchy')
    if current != branch:
        if previous:
            git(path, 'checkout', '--no-overwrite-ignore', branch, '--')
        else:
            git(path, 'checkout', '--no-overwrite-ignore', '--no-track', '-b', branch, commit, '--')
    git(path, 'merge', '--ff-only', '--no-overwrite-ignore', commit)
    if git(path, 'rev-parse', 'HEAD') != commit:
        raise Skip('checkout did not reach the remote commit')


def sync_one(item, items, home, config, dry_run=False):
    path = local_path(home, item['relative'], config['roots'])
    branch, commit = item['branch'], item['commit']
    if not branch:
        raise Skip('remote checkout has detached HEAD')
    exists = (path / '.git').exists()
    if path.exists() and not exists:
        raise Skip('local path already exists without a Git checkout')
    if exists:
        if Path(git(path, 'rev-parse', '--show-toplevel')).resolve() != path:
            raise Skip('local path is not the repository root')
        clean(path)
        if (optional_git(path, 'symbolic-ref', '--quiet', '--short', 'HEAD') == branch
                and git(path, 'rev-parse', 'HEAD') == commit):
            return 'unchanged'
    if dry_run:
        return 'would update' if exists else 'would create'
    source = config['host'] + ':' + item['path']
    base = None
    if not exists:
        for peer in items:
            candidate = local_path(home, peer['relative'], config['roots'])
            if peer['common'] == item['common'] and (candidate / '.git').exists():
                base = candidate
                break
        if base is None:
            path.parent.mkdir(parents=True, exist_ok=True)
            run(['git', '-c', 'core.hooksPath=/dev/null', 'clone', '--no-checkout',
                 '--origin', 'omarchy-sync', source, str(path)])
            if item['origin']:
                git(path, 'remote', 'add', 'origin', item['origin'])
            check_target(path, branch, commit)
            git(path, 'checkout', '--no-overwrite-ignore', '-B', branch, commit, '--')
    fetch_path = base or path
    git(fetch_path, 'fetch', '--no-tags', '--no-recurse-submodules', source,
        '+refs/heads/*:refs/remotes/omarchy-sync/*')
    git(fetch_path, 'cat-file', '-e', commit + '^{commit}')
    if base:
        previous = check_target(base, branch, commit)
        path.parent.mkdir(parents=True, exist_ok=True)
        if previous:
            git(base, 'worktree', 'add', str(path), branch)
        else:
            git(base, 'worktree', 'add', '-b', branch, str(path), commit)
    update(path, branch, commit)
    if not exists:
        for prefix, setup in config.get('worktree_setup', {}).items():
            if item['relative'].startswith(prefix + '/'):
                cwd = path / setup['cwd']
                run(setup['command'], cwd=cwd)
                if json.loads(run(setup['verify'], cwd=cwd)).get('result') != setup['expected']:
                    raise Skip('checkout created, but project setup verification failed')
    return 'updated' if exists else 'created'


def sync(config, dry_run=False):
    home = Path.home().resolve()
    state = home / '.local/state/omarchy-sync'
    state.mkdir(parents=True, exist_ok=True)
    with (state / 'lock').open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print('Omarchy sync is already running.', file=sys.stderr)
            return 1
        command = shlex.join(['python3', '-', *config['roots']])
        items = json.loads(run(['ssh', *SSH_OPTIONS, config['host'], command], input=INVENTORY))
        if not items:
            raise Skip('no remote Git checkouts found')
        os.environ['GIT_SSH_COMMAND'] = shlex.join(['ssh', *SSH_OPTIONS])
        os.environ['GIT_TERMINAL_PROMPT'] = '0'
        counts = {}
        for item in items:
            try:
                result = sync_one(item, items, home, config, dry_run)
                print(f"{result.upper()}: {item['relative']} ({item['branch']} @ {item['commit'][:8]})", flush=True)
            except (Skip, OSError, ValueError, subprocess.TimeoutExpired) as error:
                result = 'skipped'
                print(f"SKIPPED: {item['relative']}: {error}", flush=True)
            counts[result] = counts.get(result, 0) + 1
        print('Omarchy sync: ' + ', '.join(f'{v} {k}' for k, v in counts.items()) + '.', flush=True)
        return int(bool(counts.get('skipped')))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['connect', 'sync'])
    parser.add_argument('session', nargs='?', help='tmux session (default: nomp)')
    parser.add_argument('--dry-run', action='store_true', help='inspect without fetching or changing checkouts')
    args = parser.parse_args()
    config = json.loads(Path(__file__).with_name('settings.json').read_text())
    if args.action == 'connect':
        command = shlex.join(['tmux', '-u', 'new-session', '-A', '-s', args.session or config['session']])
        code = subprocess.call(['ssh', '-t', '-o', 'ConnectTimeout=10', '-o', 'ServerAliveInterval=15',
                                '-o', 'ServerAliveCountMax=2', config['host'], command])
        if code:
            print('SSH did not exit normally. Run omarchy-sync when the connection is available.', file=sys.stderr)
            return code
    try:
        return sync(config, args.dry_run)
    except (Skip, OSError, ValueError, subprocess.TimeoutExpired) as error:
        print(f'Omarchy sync failed: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print('\nStopped. Run omarchy-sync to retry.', file=sys.stderr)
        sys.exit(130)
