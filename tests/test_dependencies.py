"""Check dependency retries without downloading software or touching real configs."""
import os
from pathlib import Path
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


if __name__ == '__main__':
    unittest.main()
