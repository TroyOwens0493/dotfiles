"""Check color defaults, local exports, and reloads without touching live sessions."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[1]
COLOR_NAMES = ['DOTFILES_PATH_COLOR', 'DOTFILES_TMUX_BAR_COLOR',
               'DOTFILES_TMUX_ACTIVE_COLOR', 'DOTFILES_TMUX_TEXT_COLOR']


class ColorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / 'home with spaces'
        self.home.mkdir()
        self.env = os.environ.copy()
        for name in COLOR_NAMES + ['STARSHIP_CONFIG', 'TMUX', 'TMUX_PANE']:
            self.env.pop(name, None)
        self.env.update(HOME=str(self.home), XDG_CACHE_HOME=str(self.home / '.cache'))

    def bash(self, code, *args):
        return subprocess.run(['bash', '--noprofile', '--norc', '-c',
                               'source "$1"; shift; ' + code,
                               'colors-test', str(ROOT / 'shared/shell/colors.sh'), *map(str, args)],
                              env=self.env, capture_output=True, text=True, check=True)

    def test_bash_defaults_overrides_and_invalid_values(self):
        prompt = 'source "$1"; printf "%s" "$PS1"'
        config = ROOT / 'omarchy/bash/.bash_customizations'
        for color in [None, '', 'invalid', '#12ab', '#bb9af7"; touch /tmp/color-injection-test']:
            with self.subTest(color=color):
                self.env.pop('DOTFILES_PATH_COLOR', None)
                if color is not None:
                    self.env['DOTFILES_PATH_COLOR'] = color
                self.assertIn(r'\e[38;5;37m', self.bash(prompt, config).stdout)
        self.env['DOTFILES_PATH_COLOR'] = '#bb9af7'
        self.assertIn(r'\e[38;2;187;154;247m', self.bash(prompt, config).stdout)
        result = self.bash('source "$1"; export DOTFILES_PATH_COLOR="#112233"; '
                           '_dotfiles_set_prompt; printf "%s" "$PS1"', config)
        self.assertIn(r'\e[38;2;17;34;51m', result.stdout)

    def test_starship_override_preserves_template_and_resets(self):
        template = ROOT / 'omarchy/starship.toml'
        original = template.read_bytes()
        self.env['DOTFILES_PATH_COLOR'] = '#bb9af7'
        result = self.bash('_dotfiles_configure_starship "$1"; printf "%s" "$STARSHIP_CONFIG"', template)
        generated = Path(result.stdout)
        config = tomllib.loads(generated.read_text())
        self.assertEqual(config['directory']['style'], 'bold #bb9af7')
        self.assertEqual(config['directory']['repo_root_style'], 'bold #bb9af7')
        baseline = tomllib.loads(original.decode())
        self.assertEqual(config['git_branch'], baseline['git_branch'])
        self.assertEqual(config['git_status'], baseline['git_status'])
        self.assertEqual(template.read_bytes(), original)
        self.env['STARSHIP_CONFIG'] = str(generated)
        self.env.pop('DOTFILES_PATH_COLOR')
        result = self.bash('_dotfiles_configure_starship "$1"; printf "%s" "${STARSHIP_CONFIG-unset}"', template)
        self.assertEqual(result.stdout, 'unset')

    def test_explicit_starship_config_is_preserved(self):
        self.env.update(DOTFILES_PATH_COLOR='#bb9af7', STARSHIP_CONFIG='/custom/starship.toml')
        result = self.bash('_dotfiles_configure_starship "$1"; printf "%s" "$STARSHIP_CONFIG"',
                           ROOT / 'omarchy/starship.toml')
        self.assertEqual(result.stdout, '/custom/starship.toml')
        self.assertFalse((self.home / '.cache').exists())

    @unittest.skipUnless(shutil.which('zsh'), 'Zsh is not installed')
    def test_zsh_path_override_and_default(self):
        code = 'source "$1"; source "$2"; print -r -- "${(e)PROMPT}"'
        args = ['zsh', '-f', '-c', code, 'colors-test', str(ROOT / 'shared/shell/colors.sh'),
                str(ROOT / 'macos/zsh/.zsh_customizations')]
        result = subprocess.run(args, env=self.env, capture_output=True, text=True, check=True)
        self.assertIn('%F{37}', result.stdout)
        self.env['DOTFILES_PATH_COLOR'] = '#bb9af7'
        result = subprocess.run(args, env=self.env, capture_output=True, text=True, check=True)
        self.assertIn('%F{#bb9af7}', result.stdout)

    @unittest.skipUnless(shutil.which('tmux'), 'tmux is not installed')
    def test_tmux_inherits_exports_and_reload_restores_defaults(self):
        # A private socket and HOME keep this test away from the user's server.
        executable = shutil.which('tmux')
        socket = 'dotfiles-colors-test-' + uuid.uuid4().hex
        bin_dir = self.home / 'bin'
        bin_dir.mkdir()
        wrapper = bin_dir / 'tmux'
        wrapper.write_text(f'#!/bin/sh\nexec "{executable}" -L "{socket}" "$@"\n')
        wrapper.chmod(0o755)
        self.env['PATH'] = str(bin_dir) + os.pathsep + self.env['PATH']
        config = self.home / '.config'
        (config / 'shell').mkdir(parents=True)
        (config / 'shell/colors.sh').symlink_to(ROOT / 'shared/shell/colors.sh')
        (config / 'tmux/plugins/tpm').mkdir(parents=True)
        tpm = config / 'tmux/plugins/tpm/tpm'
        tpm.write_text('#!/bin/sh\nexit 0\n')
        tpm.chmod(0o755)
        for name in ['colors.sh', 'tmux.conf']:
            (config / 'tmux' / name).symlink_to(ROOT / 'shared/tmux' / name)
        self.env.update(DOTFILES_TMUX_BAR_COLOR='#bb9af7',
                        DOTFILES_TMUX_ACTIVE_COLOR='#987bc7', DOTFILES_TMUX_TEXT_COLOR='#282a36')

        def tmux(*args):
            return subprocess.run([str(wrapper), *args], env=self.env,
                                  capture_output=True, text=True, check=True)

        tmux('-f', str(config / 'tmux/tmux.conf'), 'new-session', '-d', '-s', 'test')
        self.addCleanup(lambda: subprocess.run([str(wrapper), 'kill-server'], env=self.env, capture_output=True))
        colors = tmux('show-option', '-gqv', '@dracula-colors').stdout
        self.assertIn('gray="#bb9af7"', colors)
        self.assertIn('dark_purple="#987bc7"', colors)
        self.assertIn('white="#282a36"', colors)
        self.assertIn('network_blue="#8be9fd"', colors)

        # Stale session exports must not win over the newly updated server.
        tmux('set-environment', '-t', 'test', 'DOTFILES_TMUX_BAR_COLOR', '#bb9af7')
        for name in COLOR_NAMES:
            self.env.pop(name, None)
        subprocess.run(['sh', str(ROOT / 'shared/bin/tmux-colors')],
                       env=self.env, capture_output=True, text=True, check=True)
        defaults = tmux('show-option', '-gqv', '@dracula-colors').stdout
        self.assertIn('gray="#44475a"', defaults)
        self.assertIn('cyan="#8be9fd"', defaults)
        self.assertIn('dark_purple="#6272a4"', defaults)
        self.assertIn('white="#f8f8f2"', defaults)

        self.env['DOTFILES_TMUX_BAR_COLOR'] = '#invalid'
        subprocess.run(['sh', str(ROOT / 'shared/bin/tmux-colors')],
                       env=self.env, capture_output=True, text=True, check=True)
        self.assertEqual(tmux('show-option', '-gqv', '@dracula-colors').stdout, defaults)
