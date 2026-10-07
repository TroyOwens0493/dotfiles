local function find_worktrees()
    if vim.fn.executable('git') == 0 then
        return {}
    end

    local cwd = vim.fn.getcwd()
    local candidates = { cwd }
    local buffer = vim.api.nvim_buf_get_name(0)
    if buffer ~= '' then
        table.insert(candidates, vim.fs.dirname(buffer))
    end
    -- The parent of sibling worktrees is not itself a Git repository.
    for _, git_dir in ipairs(vim.fn.globpath(cwd, '*/.git', false, true)) do
        table.insert(candidates, vim.fs.dirname(git_dir))
    end

    for _, directory in ipairs(candidates) do
        local result = vim.system({
            'git', '-C', directory, 'worktree', 'list', '--porcelain', '-z',
        }):wait(3000)
        if result.code == 0 then
            local worktrees = {}
            for field in result.stdout:gmatch('([^%z]+)%z') do
                local path = field:match('^worktree (.+)$')
                if path and vim.fn.isdirectory(path) == 1 then
                    table.insert(worktrees, path)
                end
            end
            return worktrees
        end
    end
    return {}
end

local function run_task()
    local worktrees = find_worktrees()
    if #worktrees < 2 then
        require('overseer').run_task()
        return
    end

    vim.ui.select(worktrees, {
        prompt = 'Select worktree:',
        format_item = function(path)
            return vim.fs.basename(path)
        end,
    }, function(path)
        if not path then
            return
        end
        -- Keep VS Code variables and dependent tasks in the selected worktree.
        vim.cmd.tcd(vim.fn.fnameescape(path))
        require('overseer').run_task({ search_params = { dir = path } })
    end)
end

return {
    'stevearc/overseer.nvim',
    ---@module 'overseer'
    ---@type overseer.SetupOpts
    opts = {},
    config = function(_, opts)
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

        overseer.add_template_hook({ module = '^vscode$' }, function(task)
            if type(task.cmd) == 'string' and (shell == 'bash' or shell == 'zsh') then
                -- Force a reload after macOS removes DYLD variables from the task shell.
                task.cmd = string.format(
                    'overseer_direnv_exports=$(DIRENV_FILE= %s export %s) || exit $?\neval "$overseer_direnv_exports"\n%s',
                    vim.fn.shellescape(direnv), vim.fn.shellescape(shell), task.cmd
                )
            elseif type(task.cmd) == 'table' and #task.cmd > 0 then
                task.cmd = vim.list_extend({ direnv, 'exec', task.cwd or vim.fn.getcwd() }, task.cmd)
            end
        end)
    end,
    keys = {
        { '<leader>tr', run_task, desc = 'Run task in worktree' },
        { '<leader>tv', '<cmd>OverseerToggle<CR>', desc = 'Toggle task list' },
    },
}
