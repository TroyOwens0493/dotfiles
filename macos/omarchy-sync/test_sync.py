"""Integration checks use disposable repositories and real Git operations."""
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('omarchy_sync', Path(__file__).with_name('sync.py'))
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


class SyncTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name).resolve()
        self.remote = root / 'remote'
        self.home = root / 'home'
        self.local = self.home / 'ProgrammingDocs/project'
        self.git(None, 'init', '-b', 'main', str(self.remote))
        self.commit('first')
        self.local.parent.mkdir(parents=True)
        self.git(None, 'clone', str(self.remote), str(self.local))
        self.config = {'host': 'fixture', 'roots': ['ProgrammingDocs'], 'worktree_setup': {}}
        original_run = sync.run
        def local_transport(args, **kwargs):
            return original_run([arg.removeprefix('fixture:') for arg in args], **kwargs)
        self.transport = patch.object(sync, 'run', side_effect=local_transport)
        self.transport.start()
        self.addCleanup(self.transport.stop)

    def git(self, path, *args):
        cmd = ['git', '-c', 'user.name=Sync Test', '-c', 'user.email=sync@example.invalid',
               '-c', 'commit.gpgsign=false', '-c', 'core.hooksPath=/dev/null']
        if path:
            cmd += ['-C', str(path)]
        return subprocess.check_output(cmd + list(args), text=True, stderr=subprocess.PIPE).strip()

    def commit(self, content, path=None, filename='file.txt'):
        path = path or self.remote
        (path / filename).write_text(content)
        self.git(path, 'add', filename)
        self.git(path, 'commit', '-m', content)
        return self.git(path, 'rev-parse', 'HEAD')

    def item(self, relative='ProgrammingDocs/project'):
        return dict(relative=relative, path=str(self.remote),
                    branch=self.git(self.remote, 'branch', '--show-current'),
                    commit=self.git(self.remote, 'rev-parse', 'HEAD'),
                    common=str(self.remote / '.git'), origin='')

    def apply(self, item=None, items=None, dry=False):
        item = item or self.item()
        return sync.sync_one(item, items or [item], self.home, self.config, dry)

    def test_fast_forward_and_idempotence(self):
        tip = self.commit('second')
        self.assertEqual(self.apply(), 'updated')
        self.assertEqual(self.git(self.local, 'rev-parse', 'HEAD'), tip)
        self.assertEqual(self.apply(), 'unchanged')

    def test_new_branch_and_remote_uncommitted_changes(self):
        self.git(self.remote, 'checkout', '-b', 'feature/test')
        self.commit('branch commit')
        (self.remote / 'file.txt').write_text('not committed')
        self.apply()
        self.assertEqual(self.git(self.local, 'branch', '--show-current'), 'feature/test')
        self.assertEqual((self.local / 'file.txt').read_text(), 'branch commit')

    def test_dirty_staged_and_untracked_preserved(self):
        self.commit('second')
        for mode in ('dirty', 'staged', 'untracked'):
            with self.subTest(mode=mode):
                file = self.local / ('extra.txt' if mode == 'untracked' else 'file.txt')
                file.write_text('local work')
                if mode == 'staged':
                    self.git(self.local, 'add', 'file.txt')
                with self.assertRaisesRegex(sync.Skip, 'local changes'):
                    self.apply()
                self.assertEqual(file.read_text(), 'local work')
                self.git(self.local, 'reset', '--hard', 'HEAD')
                if mode == 'untracked':
                    file.unlink()

    def test_local_ahead_and_diverged_preserved(self):
        tip = self.commit('local commit', self.local)
        with self.assertRaisesRegex(sync.Skip, 'commits absent'):
            self.apply()
        self.commit('remote commit')
        with self.assertRaisesRegex(sync.Skip, 'commits absent'):
            self.apply()
        self.assertEqual(self.git(self.local, 'rev-parse', 'HEAD'), tip)

    def test_ignored_file_is_not_overwritten(self):
        with (self.local / '.git/info/exclude').open('a') as file:
            file.write('\nsecret.txt\n')
        (self.local / 'secret.txt').write_text('local ignored work')
        self.commit('remote file', filename='secret.txt')
        with self.assertRaises(sync.Skip):
            self.apply()
        self.assertEqual((self.local / 'secret.txt').read_text(), 'local ignored work')

    def test_missing_repository_and_linked_worktree(self):
        new = self.item('ProgrammingDocs/new-project')
        self.assertEqual(self.apply(new), 'created')
        self.git(self.remote, 'checkout', '-b', 'feature/worktree')
        self.commit('worktree commit')
        item = self.item('ProgrammingDocs/ticket')
        self.assertEqual(self.apply(item, [new, item]), 'created')
        new_common = sync.git(self.home / new['relative'], 'rev-parse', '--path-format=absolute', '--git-common-dir')
        ticket_common = sync.git(self.home / item['relative'], 'rev-parse', '--path-format=absolute', '--git-common-dir')
        self.assertEqual(new_common, ticket_common)

    def test_dry_run_does_not_fetch_or_switch(self):
        before = self.git(self.local, 'rev-parse', 'HEAD')
        self.commit('second')
        self.assertEqual(self.apply(dry=True), 'would update')
        self.assertEqual(self.git(self.local, 'rev-parse', 'HEAD'), before)
        self.assertFalse(sync.optional_git(self.local, 'rev-parse', '--verify', 'refs/remotes/omarchy-sync/main'))

    def test_reject_unsafe_path(self):
        with self.assertRaisesRegex(sync.Skip, 'invalid remote path'):
            self.apply(self.item('../outside'))

    def test_switch_to_existing_branch_preserves_other_local_branch(self):
        self.git(self.local, 'checkout', '-b', 'local-only')
        local_tip = self.commit('local branch commit', self.local)
        remote_tip = self.commit('remote main update')
        self.apply()
        self.assertEqual(self.git(self.local, 'branch', '--show-current'), 'main')
        self.assertEqual(self.git(self.local, 'rev-parse', 'HEAD'), remote_tip)
        self.assertEqual(self.git(self.local, 'rev-parse', 'local-only'), local_tip)

    def test_failed_fetch_preserves_checkout(self):
        before = self.git(self.local, 'rev-parse', 'HEAD')
        self.commit('second')
        item = self.item()
        item['path'] = str(self.remote / 'missing')
        with self.assertRaises(sync.Skip):
            self.apply(item)
        self.assertEqual(self.git(self.local, 'rev-parse', 'HEAD'), before)
        self.assertEqual(self.git(self.local, 'status', '--porcelain'), '')


if __name__ == '__main__':
    unittest.main()
