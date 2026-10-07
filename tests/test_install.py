"""Exercise fresh installs, preservation, platform isolation, and restoration."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    """Use a checkout and home with spaces so tests never modify real settings."""

    def setUp(self):
        """Copy the reviewed source and isolate the Git and desktop environment."""
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.repo = self.base / 'repo with spaces'
        self.repo.mkdir()
        # The live checkout can be ~/.config; never copy unrelated app state.
        for name in ['shared', 'macos', 'omarchy', 'scripts']:
            shutil.copytree(ROOT / name, self.repo / name,
                            ignore=shutil.ignore_patterns('node_modules', '__pycache__', '*.bak.*'),
                            symlinks=True)
        shutil.copy2(ROOT / 'install.sh', self.repo / 'install.sh')
        self.home = self.base / 'home with spaces'
        self.home.mkdir()
        self.env = os.environ.copy()
        for key in ['HYPRLAND_INSTANCE_SIGNATURE', 'GIT_CONFIG_GLOBAL', 'GIT_CONFIG_COUNT', 'PI_CODING_AGENT_DIR']:
            self.env.pop(key, None)
        self.env.update(HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / '.config'))

    def install(self, platform='omarchy', *args):
        """Run config-only installation and expose unexpected failures."""
        return subprocess.run(['bash', str(self.repo / 'install.sh'), '--platform', platform, '--configs-only', *args], env=self.env, capture_output=True, text=True, check=True)

    def test_dry_run_has_no_side_effects(self):
        """A preview creates no targets, backups, or Git preferences."""
        for platform in ['macos', 'omarchy']:
            result = self.install(platform, '--dry-run')
            self.assertIn('Dry run', result.stdout)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_omarchy_preserves_state_and_is_idempotent(self):
        """Install tracked links while retaining private state and local overrides."""
        config = self.home / '.config'
        (config / 'nvim').mkdir(parents=True)
        (config / 'nvim/init.lua').write_text('-- previous editor')
        (config / 'pi/skills/stock').mkdir(parents=True)
        (config / 'pi/auth.json').write_text('private credential fixture')
        (config / 'pi/sessions').mkdir()
        (config / 'pi/sessions/local.jsonl').write_text('private session fixture')
        (config / 'pi/extensions/private-extension').mkdir(parents=True)
        (config / 'pi/extensions/private-extension/index.ts').write_text('// local extension')
        (config / 'pi/node_modules').mkdir()
        (config / 'pi/node_modules/local-package.txt').write_text('existing dependency')
        (config / 'hypr').mkdir()
        (config / 'hypr/monitors.lua').write_text('-- this machine')
        (config / 'hypr/local.lua').write_text('-- local settings')
        (self.home / '.gitconfig').write_text('[user]\n\tname = Existing User\n')
        self.install()
        self.assertEqual((config / 'nvim').resolve(), self.repo / 'shared/nvim')
        self.assertEqual((config / 'hypr/aerospace.lua').resolve(), self.repo / 'omarchy/hypr/aerospace.lua')
        self.assertEqual((config / 'pi/extensions/ask-user/index.ts').resolve(), self.repo / 'shared/pi/extensions/ask-user/index.ts')
        self.assertEqual((config / 'pi/auth.json').read_text(), 'private credential fixture')
        self.assertEqual((config / 'pi/sessions/local.jsonl').read_text(), 'private session fixture')
        self.assertTrue((config / 'pi/skills/stock').is_dir())
        self.assertEqual((config / 'pi/extensions/private-extension/index.ts').read_text(), '// local extension')
        self.assertEqual((self.repo / 'shared/pi/node_modules/local-package.txt').read_text(), 'existing dependency')
        self.assertEqual((config / 'hypr/monitors.lua').read_text(), '-- this machine')
        self.assertEqual((config / 'hypr/local.lua').read_text(), '-- local settings')
        self.assertIn('Existing User', (self.home / '.gitconfig').read_text())
        self.assertFalse((config / 'aerospace').exists())
        backups = list((self.home / '.dotfiles-backup').iterdir())
        self.install()
        self.assertEqual(list((self.home / '.dotfiles-backup').iterdir()), backups)
        (config / 'nvim/init.lua').write_text('-- edited through app path')
        self.assertEqual((self.repo / 'shared/nvim/init.lua').read_text(), '-- edited through app path')

    def test_macos_preserves_profile_and_is_isolated(self):
        """The Mac profile links AeroSpace, includes common Ghostty, and keeps zprofile."""
        profile = self.home / '.zprofile'
        profile.write_text('# existing profile\n')
        self.install('macos')
        self.assertEqual((self.home / '.aerospace.toml').resolve(), self.repo / 'macos/aerospace/aerospace.toml')
        self.assertEqual((self.home / '.config/ghostty/config').resolve(), self.repo / 'macos/ghostty/config')
        self.assertIn('# existing profile', profile.read_text())
        self.assertEqual(profile.read_text().count('macos-profile.sh'), 2)
        self.assertFalse((self.home / '.config/hypr').exists())
        self.assertEqual((self.home / '.zshrc').resolve(), self.repo / 'macos/zsh/.zshrc')
        self.assertEqual((self.home / '.config/omarchy-sync/sync.py').resolve(), self.repo / 'macos/omarchy-sync/sync.py')
        before = profile.read_text()
        self.install('macos')
        self.assertEqual(profile.read_text(), before)

    def test_native_pi_state_remains_active(self):
        """An existing native Pi data directory keeps its credentials and sessions."""
        native = self.home / '.pi/agent'
        native.mkdir(parents=True)
        (native / 'auth.json').write_text('private fixture')
        self.install()
        self.assertEqual((native / 'auth.json').read_text(), 'private fixture')
        self.assertEqual((native / 'settings.json').resolve(), self.repo / 'shared/pi/settings.json')

    def test_two_pi_directories_fail_before_changes(self):
        """Conflicting state directories require a deliberate merge by the owner."""
        (self.home / '.pi/agent').mkdir(parents=True)
        (self.home / '.config/pi').mkdir(parents=True)
        result = subprocess.run(['bash', str(self.repo / 'install.sh'), '--platform', 'macos', '--configs-only'],
                                env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Two Pi data directories', result.stderr)
        self.assertFalse((self.home / '.dotfiles-backup').exists())

    def test_existing_directory_links_do_not_modify_other_checkout(self):
        """Replacing a config below a symlink preserves the previous source tree."""
        previous = self.home / 'previous-checkout'
        previous.mkdir()
        (previous / 'opencode.json').write_text('previous settings')
        (previous / 'auth.json').write_text('private fixture')
        config = self.home / '.config'
        config.mkdir()
        (config / 'opencode').symlink_to(previous)
        self.install()
        self.assertEqual((previous / 'opencode.json').read_text(), 'previous settings')
        self.assertEqual((config / 'opencode/auth.json').read_text(), 'private fixture')
        backup = next((self.home / '.dotfiles-backup').iterdir())
        subprocess.run(['bash', str(self.repo / 'scripts/restore.sh'), str(backup)],
                       env=self.env, check=True, capture_output=True)
        self.assertEqual((config / 'opencode').resolve(), previous)

    def test_legacy_ghostty_filename_uses_selected_platform(self):
        """Keep one Ghostty config so common.conf is not included twice."""
        target = self.home / '.config/ghostty/config.ghostty'
        target.parent.mkdir(parents=True)
        target.write_text('old config')
        self.install('macos')
        self.assertFalse(target.exists())
        self.assertFalse(target.is_symlink())
        self.assertEqual(target.with_name('config').resolve(), self.repo / 'macos/ghostty/config')
        backup = next((self.home / '.dotfiles-backup').iterdir())
        self.assertEqual((backup / 'files/.config/ghostty/config.ghostty').read_text(), 'old config')

    def test_omarchy_package_setup_selects_repo_mise_config(self):
        """A fresh machine installs the repo tools before its global link exists."""
        tools = self.base / 'fake-package-tools'
        tools.mkdir()
        log = self.base / 'package-calls'
        for name in ['omarchy', 'mise']:
            tool = tools / name
            tool.write_text('#!/usr/bin/env bash\nprintf "%s|%s|%s|%s\\n" "${0##*/}" "$*" "${MISE_GLOBAL_CONFIG_FILE:-}" "$PWD" >> "$SETUP_TEST_LOG"\n')
            tool.chmod(0o755)
        self.env.update(PATH=str(tools) + os.pathsep + self.env['PATH'],
                        SETUP_TEST_LOG=str(log), SETUP_TEST_REPO=str(self.repo))
        subprocess.run(['bash', '-ec', 'REPO_DIR="$SETUP_TEST_REPO"; source "$REPO_DIR/scripts/install-omarchy.sh"; install_platform_packages'],
                       env=self.env, check=True, capture_output=True)
        self.assertIn(f'mise|install|{self.repo}/omarchy/mise/config.toml|{self.home}', log.read_text())
        self.assertIn('omarchy|pkg add ', log.read_text())

    def test_restore_recovers_previous_files_and_removes_new_links(self):
        """Restore handles whole-directory backups and initially absent targets."""
        config = self.home / '.config'
        (config / 'nvim').mkdir(parents=True)
        (config / 'nvim/init.lua').write_text('-- original')
        gitconfig = self.home / '.gitconfig'
        gitconfig.write_text('[user]\n\tname = Original User\n')
        self.install()
        backup = next((self.home / '.dotfiles-backup').iterdir())
        subprocess.run(['bash', str(self.repo / 'scripts/restore.sh'), str(backup)], env=self.env, check=True, capture_output=True, text=True)
        self.assertFalse((config / 'nvim').is_symlink())
        self.assertEqual((config / 'nvim/init.lua').read_text(), '-- original')
        self.assertEqual(gitconfig.read_text(), '[user]\n\tname = Original User\n')
        self.assertFalse((config / 'ghostty/config').exists())
        self.assertFalse((config / 'pi/settings.json').exists())

    def test_invalid_platform_fails_before_mutation(self):
        """A misspelled platform must not modify the machine."""
        result = subprocess.run(['bash', str(self.repo / 'install.sh'), '--platform', 'unknown'], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_relative_profile_and_git_links_preserve_content_and_restore(self):
        """Moving a relative symlink to a backup must not lose its file content."""
        original_profile = self.home / 'original-profile'
        original_profile.write_text('# existing linked profile\n')
        profile = self.home / '.zprofile'
        profile.symlink_to('original-profile')
        original_git = self.home / 'original-gitconfig'
        original_git.write_text('[user]\n\tname = Linked User\n')
        gitconfig = self.home / '.gitconfig'
        gitconfig.symlink_to('original-gitconfig')
        self.install('macos')
        self.assertIn('# existing linked profile', profile.read_text())
        self.assertIn('Linked User', gitconfig.read_text())
        self.assertEqual(original_profile.read_text(), '# existing linked profile\n')
        self.assertEqual(original_git.read_text(), '[user]\n\tname = Linked User\n')
        backup = next((self.home / '.dotfiles-backup').iterdir())
        subprocess.run(['bash', str(self.repo / 'scripts/restore.sh'), str(backup)], env=self.env, check=True, capture_output=True, text=True)
        self.assertEqual(os.readlink(profile), 'original-profile')
        self.assertEqual(os.readlink(gitconfig), 'original-gitconfig')

    def test_dependency_sync_uses_local_pi_lock_and_isolated_tmux(self):
        """Mock external tools to check sync commands and lockfile reuse offline."""
        tools = self.base / 'fake-tools'
        tools.mkdir()
        log = self.base / 'calls.log'
        self.env.update(PATH=str(tools) + os.pathsep + self.env['PATH'], SETUP_TEST_LOG=str(log))
        mocks = {
            'npm': 'printf "npm %s\\n" "$*" >> "$SETUP_TEST_LOG"\nmkdir -p "$HOME/.config/pi/node_modules/.bin"\ntouch "$HOME/.config/pi/node_modules/.bin/pi"\nchmod +x "$HOME/.config/pi/node_modules/.bin/pi"\n',
            'tmux': 'printf "tmux %s\\n" "$*" >> "$SETUP_TEST_LOG"\ncase "$*" in *display-message*) printf "/test/socket,42,0\\n" ;; esac\n',
            'nvim': 'printf "nvim %s\\n" "$*" >> "$SETUP_TEST_LOG"\n',
            'git-lfs': 'printf "git-lfs %s\\n" "$*" >> "$SETUP_TEST_LOG"\n',
        }
        for name, content in mocks.items():
            tool = tools / name
            tool.write_text('#!/usr/bin/env bash\nset -eu\n' + content)
            tool.chmod(0o755)
        tpm = self.home / '.config/tmux/plugins/tpm'
        (tpm / '.git').mkdir(parents=True)
        (tpm / 'bin').mkdir()
        plugin_installer = tpm / 'bin/install_plugins'
        plugin_installer.write_text('#!/usr/bin/env bash\nprintf "TPM %s\\n" "$TMUX" >> "$SETUP_TEST_LOG"\n')
        plugin_installer.chmod(0o755)
        command = ['bash', str(self.repo / 'install.sh'), '--platform', 'omarchy', '--skip-packages']
        subprocess.run(command, env=self.env, check=True, capture_output=True, text=True)
        subprocess.run(command, env=self.env, check=True, capture_output=True, text=True)
        calls = log.read_text()
        self.assertEqual(calls.count('npm ci --prefix'), 1)
        self.assertIn('TPM /test/socket,42,0', calls)
        self.assertIn('kill-server', calls)
        self.assertIn('git-lfs install', calls)
        self.assertIn('nvim --headless +Lazy! restore +qa', calls)


if __name__ == '__main__':
    unittest.main()
