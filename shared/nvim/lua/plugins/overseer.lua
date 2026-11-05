local function run_task()
    require('overseer').run_task({ search_params = { dir = vim.fn.getcwd() } })
end

local function setup_overseer(_, opts)
    local overseer = require('overseer')
    overseer.setup(opts)

    local direnv = vim.fn.exepath('direnv')
    if direnv == '' then
        return
    end
    local shell = require('overseer.shell').normalize_shell_name()
    if shell == 'sh' then
        shell = 'bash'
    end

    local function apply_direnv(task)
        if type(task.cmd) == 'string' and (shell == 'bash' or shell == 'zsh') then
            -- Force a reload after macOS removes DYLD variables from the task shell.
            task.cmd = string.format(
                'overseer_direnv_exports=$(DIRENV_FILE= %s export %s) || exit $?\neval "$overseer_direnv_exports"\n%s',
                vim.fn.shellescape(direnv), vim.fn.shellescape(shell), task.cmd
            )
        elseif type(task.cmd) == 'table' and #task.cmd > 0 then
            task.cmd = vim.list_extend({ direnv, 'exec', task.cwd or vim.fn.getcwd() }, task.cmd)
        end
    end

    overseer.add_template_hook({ module = '^vscode$' }, apply_direnv)
end

return {
    'stevearc/overseer.nvim',
    ---@module 'overseer'
    ---@type overseer.SetupOpts
    opts = {},
    config = setup_overseer,
    keys = {
        { '<leader>tr', run_task, desc = 'Run task' },
        { '<leader>tv', '<cmd>OverseerToggle<CR>', desc = 'Toggle task list' },
    },
}
