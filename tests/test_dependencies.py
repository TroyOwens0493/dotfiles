"""Check dependency retries without downloading software or touching real configs."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DependencyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.repo = self.base / 'repo with spaces'
        self.lock = self.repo / 'shared/nvim/lazy-lock.json'
        self.lock.parent.mkdir(parents=True)
        self.original = '{"example":{"branch":"main","commit":"original"}}\n'
        self.lock.write_text(self.original)
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        self.env = dict(os.environ, REPO_DIR=str(self.repo),
                        CONFIG_DIR=str(self.base / 'config with spaces'),
                        PATH=f'{self.bin}:{os.environ["PATH"]}',
                        CALL_LOG=str(self.base / 'calls'), TEST_LOCK=str(self.lock))

    def run_helper(self, script, expression, check=True):
        return subprocess.run(['bash', '-euc', f'source "$1"; {expression}',
                               'test', str(ROOT / 'scripts' / script)],
                              env=self.env, capture_output=True, text=True, check=check)

    def test_nvim_preserves_input_lock_on_success_and_failure(self):
        """Startup mutation must not become the restore input or dirty the repo."""
        nvim = self.bin / 'nvim'
        nvim.write_text('''#!/bin/bash
set -e
cmp "$DOTFILES_NVIM_LOCK_SNAPSHOT" "$TEST_LOCK"
printf 'startup replaced the lock\n' > "$DOTFILES_NVIM_LOCKFILE"
exit "${TEST_NVIM_STATUS:-0}"
''')
        nvim.chmod(0o755)
        for status in (0, 7):
            with self.subTest(status=status):
                self.env['TEST_NVIM_STATUS'] = str(status)
                result = self.run_helper('install-shared.sh', 'restore_nvim_plugins', check=False)
                self.assertEqual(result.returncode, status, result.stderr)
                self.assertEqual(self.lock.read_text(), self.original)

    def test_system_pulse_install_is_idempotent_and_does_not_enable(self):
        """The existing tracked bar layout enables the widget without CLI edits."""
        omarchy = self.bin / 'omarchy'
        omarchy.write_text('''#!/bin/bash
set -e
printf '%s\n' "$*" >> "$CALL_LOG"
if [[ "$1 $2" == "plugin add" ]]; then
  mkdir -p "$CONFIG_DIR/omarchy/plugins/lucas.system-pulse"
  printf '{"id":"lucas.system-pulse"}\n' > "$CONFIG_DIR/omarchy/plugins/lucas.system-pulse/manifest.json"
fi
''')
        omarchy.chmod(0o755)
        self.run_helper('install-omarchy.sh', 'sync_platform_dependencies; sync_platform_dependencies')
        calls = Path(self.env['CALL_LOG']).read_text().splitlines()
        self.assertEqual(sum(line.startswith('plugin add ') for line in calls), 1)
        self.assertEqual(sum(line.startswith('plugin validate ') for line in calls), 2)
        self.assertNotIn('--enable', '\n'.join(calls))

    @unittest.skipUnless(shutil.which('nvim'), 'Neovim is required for the shallow-cache regression')
    def test_nvim_fetches_old_pin_from_shallow_cache(self):
        """Use real Git history and Neovim to restore a pin absent from an ISO cache."""
        origin = self.base / 'origin with spaces'
        subprocess.run(['git', 'init', '-q', '-b', 'main', str(origin)], check=True)

        def git(directory, *args, check=True):
            return subprocess.run(['git', '-C', str(directory), *args], check=check,
                                  capture_output=True, text=True)

        git(origin, 'config', 'user.name', 'Installer Test')
        git(origin, 'config', 'user.email', 'installer@example.invalid')
        for content in ('locked', 'newer'):
            (origin / 'plugin.lua').write_text(content)
            git(origin, 'add', '.')
            git(origin, '-c', 'commit.gpgsign=false', 'commit', '-qm', content)
            if content == 'locked':
                pinned = git(origin, 'rev-parse', 'HEAD').stdout.strip()

        self.original = json.dumps({'example': {'branch': 'main', 'commit': pinned}}) + '\n'
        self.lock.write_text(self.original)
        (self.repo / 'scripts').mkdir()
        shutil.copy2(ROOT / 'scripts/restore-nvim.lua', self.repo / 'scripts/restore-nvim.lua')
        init = self.base / 'init.lua'
        init.write_text('''
local plugin = { dir = vim.env.TEST_PLUGIN_DIR, _ = { is_local = false } }
package.preload["lazy.core.config"] = function() return { plugins = { example = plugin } } end
package.preload["lazy.manage.lock"] = function() return { lock = {}, _loaded = false } end
package.preload["lazy.core.plugin"] = function() return { has_errors = function() return false end } end
package.preload["lazy"] = function()
  return { restore = function()
    local pin = require("lazy.manage.lock").lock.example.commit
    vim.fn.system({ "git", "-C", plugin.dir, "checkout", "--detach", pin })
  end }
end
''')
        nvim = self.bin / 'nvim'
        nvim.write_text('''#!/bin/bash
exec "$REAL_NVIM" -u "$TEST_NVIM_INIT" -i NONE --noplugin "$@"
''')
        nvim.chmod(0o755)
        home = self.base / 'isolated home'
        home.mkdir()
        self.env.update(HOME=str(home), REAL_NVIM=shutil.which('nvim'),
                        TEST_NVIM_INIT=str(init), GIT_CONFIG_GLOBAL=os.devnull,
                        GIT_CONFIG_SYSTEM=os.devnull)
        for reachable in (True, False):
            with self.subTest(origin_reachable=reachable):
                cache = self.base / f'cache-{reachable}'
                subprocess.run(['git', 'clone', '-q', '--depth=1', origin.as_uri(), str(cache)], check=True)
                self.assertNotEqual(git(cache, 'cat-file', '-e', pinned, check=False).returncode, 0)
                before = git(cache, 'rev-parse', 'HEAD').stdout.strip()
                if not reachable:
                    git(cache, 'remote', 'set-url', 'origin', (self.base / 'missing').as_uri())
                self.env['TEST_PLUGIN_DIR'] = str(cache)
                result = self.run_helper('install-shared.sh', 'restore_nvim_plugins', check=False)
                self.assertEqual(result.returncode, 0 if reachable else 1, result.stderr)
                self.assertEqual(git(cache, 'rev-parse', 'HEAD').stdout.strip(), pinned if reachable else before)
                self.assertEqual(self.lock.read_text(), self.original)

        # A Lua exception must also fail the installer; Neovim otherwise exits
        # successfully after reporting a command-line error and running +qa.
        (self.repo / 'scripts/restore-nvim.lua').write_text('error("forced restore failure")\n')
        result = self.run_helper('install-shared.sh', 'restore_nvim_plugins', check=False)
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn('forced restore failure', result.stderr)
        self.assertEqual(self.lock.read_text(), self.original)


if __name__ == '__main__':
    unittest.main()
