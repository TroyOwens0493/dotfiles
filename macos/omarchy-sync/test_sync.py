import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import sync


class T3WorktreeSyncTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.remote = self.root / 'remote'
        self.local = self.root / 'local'
        self.local.mkdir()
        self.base = self.remote / 'dataThink/nomp'
        self.worktree = self.remote / '.t3/worktrees/nomp/1861'
        self.config = json.loads(Path(sync.__file__).with_name('settings.json').read_text())
        self.config['host'] = 'test-host'
        self.addCleanup(patch.stopall)
        patch.dict(os.environ, {'GIT_CONFIG_GLOBAL': os.devnull,
                                'GIT_CONFIG_NOSYSTEM': '1'}).start()
        (self.remote / 'ProgrammingDocs').mkdir(parents=True)
        self.base.mkdir(parents=True)
        self.git(self.base, 'init', '-b', 'main')
        self.git(self.base, 'config', 'user.name', 'Sync Test')
        self.git(self.base, 'config', 'user.email', 'sync@example.invalid')
        (self.base / 'frontend').mkdir()
        (self.base / 'frontend/app.txt').write_text('initial\n')
        self.commit(self.base, 'initial')
        self.worktree.parent.mkdir(parents=True)
        self.git(self.base, 'worktree', 'add', '-b', 'feature', str(self.worktree))
        self.setup_calls = []
        original_run = sync.run

        def local_run(args, **kwargs):
            if args[0] == 'firebase':
                self.setup_calls.append((args, kwargs['cwd']))
                return json.dumps({'result': 'nomp-staging'})
            # Exercise real Git transfers without SSH or a second machine.
            args = [arg.removeprefix('test-host:') for arg in args]
            return original_run(args, **kwargs)

        patch.object(sync, 'run', side_effect=local_run).start()

    def git(self, path, *args):
        return subprocess.check_output(['git', '-C', str(path), *args],
                                       text=True, stderr=subprocess.PIPE).strip()

    def commit(self, path, message):
        self.git(path, 'add', '.')
        self.git(path, 'commit', '-m', message)

    def inventory(self):
        return json.loads(subprocess.check_output(
            [sys.executable, '-', *self.config['roots']], input=sync.INVENTORY,
            text=True, env={**os.environ, 'HOME': str(self.remote)}))

    def test_paths_only_allow_configured_subtrees(self):
        relative = '.t3/worktrees/nomp/1861'
        self.assertEqual(sync.local_path(self.local, relative, self.config['roots']),
                         self.local / relative)
        for relative in ('.t3/scratch/nomp', '.t3/worktrees-other/nomp',
                         '.t3/worktrees/../private', '/tmp/nomp'):
            with self.subTest(relative=relative), self.assertRaises(sync.Skip):
                sync.local_path(self.local, relative, self.config['roots'])
        (self.local / '.t3').symlink_to(self.remote / '.t3')
        with self.assertRaisesRegex(sync.Skip, 'symbolic link'):
            sync.local_path(self.local, '.t3/worktrees/nomp/1861', self.config['roots'])

    def test_t3_worktree_creation_updates_and_local_protection(self):
        items = self.inventory()
        self.assertEqual([item['relative'] for item in items],
                         ['dataThink/nomp', '.t3/worktrees/nomp/1861'])
        self.assertEqual(items[0]['common'], items[1]['common'])
        local_base = self.local / items[0]['relative']
        local_tree = self.local / items[1]['relative']
        self.assertEqual(sync.sync_one(items[1], items, self.local, self.config, True),
                         'would create')
        self.assertFalse(local_tree.exists())
        for item in items:
            self.assertEqual(sync.sync_one(item, items, self.local, self.config), 'created')
        self.assertTrue((local_tree / '.git').is_file())
        self.assertEqual(self.git(local_tree, 'rev-parse', '--git-common-dir'),
                         str(local_base / '.git'))
        self.assertEqual(self.git(local_tree, 'symbolic-ref', '--short', 'HEAD'), 'feature')
        self.assertEqual(self.setup_calls,
                         [(['firebase', 'use', 'staging'], local_tree / 'frontend'),
                          (['firebase', 'use', '--json'], local_tree / 'frontend')])

        (self.worktree / 'frontend/app.txt').write_text('remote update\n')
        self.commit(self.worktree, 'remote update')
        items = self.inventory()
        (local_tree / 'local-only.txt').write_text('keep this\n')
        with self.assertRaisesRegex(sync.Skip, 'local changes or untracked files'):
            sync.sync_one(items[1], items, self.local, self.config)
        self.assertEqual((local_tree / 'local-only.txt').read_text(), 'keep this\n')
        (local_tree / 'local-only.txt').unlink()
        self.assertEqual(sync.sync_one(items[1], items, self.local, self.config), 'updated')
        self.assertEqual((local_tree / 'frontend/app.txt').read_text(), 'remote update\n')
        self.assertEqual(sync.sync_one(items[1], items, self.local, self.config), 'unchanged')

        self.git(local_base, 'config', 'user.name', 'Sync Test')
        self.git(local_base, 'config', 'user.email', 'sync@example.invalid')
        (local_tree / 'frontend/app.txt').write_text('local commit\n')
        self.commit(local_tree, 'local commit')
        local_commit = self.git(local_tree, 'rev-parse', 'HEAD')
        with self.assertRaisesRegex(sync.Skip, 'commits absent from Omarchy'):
            sync.sync_one(items[1], items, self.local, self.config)
        self.assertEqual(self.git(local_tree, 'rev-parse', 'HEAD'), local_commit)


if __name__ == '__main__':
    unittest.main()
