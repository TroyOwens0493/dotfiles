local function review_pr()
    local root = vim.fs.root(0, '.git') or vim.fs.root(vim.fn.getcwd(), '.git')
    if not root then
        vim.notify('Not in a Git repository', vim.log.levels.ERROR)
        return
    end

    if vim.fn.executable('gh') == 0 then
        vim.notify('GitHub CLI (gh) is required to find the PR base', vim.log.levels.ERROR)
        return
    end

    local function run(args, callback)
        local function on_exit(result)
            if result.code ~= 0 then
                local output = vim.trim((result.stderr or '') .. '\n' .. (result.stdout or ''))
                vim.notify(table.concat(args, ' ') .. ' failed:\n' .. output, vim.log.levels.ERROR)
                return
            end
            callback(vim.trim(result.stdout or ''))
        end

        vim.system(args, { cwd = root, text = true }, vim.schedule_wrap(on_exit))
    end

    local function on_branch(branch)
        local function on_base(base)
            local ref = 'refs/remotes/origin/' .. base
            local function open_diff()
                vim.api.nvim_cmd({ cmd = 'CodeDiff', args = { '--repo', root, ref, 'HEAD' } }, {})
            end

            local function on_merge()
                vim.cmd('checktime')
                open_diff()
            end

            local function on_current_branch(current_branch)
                if current_branch ~= branch then
                    vim.notify('Branch changed during fetch; run the shortcut again', vim.log.levels.ERROR)
                    return
                end

                vim.notify('Merging origin/' .. base .. '…')
                run({ 'git', 'merge', '--no-ff', '--no-edit', '--no-autostash', ref }, on_merge)
            end

            local function on_status(status)
                if status ~= '' then
                    vim.notify('Commit or stash changes before merging the PR base', vim.log.levels.ERROR)
                    return
                end

                run({ 'git', 'symbolic-ref', '--short', 'HEAD' }, on_current_branch)
            end

            local function on_count(count)
                if count == '0' then
                    open_diff()
                    return
                end

                run({ 'git', 'status', '--porcelain' }, on_status)
            end

            local function on_fetch()
                run({ 'git', 'rev-list', '--count', 'HEAD..' .. ref }, on_count)
            end

            vim.notify('Fetching origin/' .. base .. '…')
            run({ 'git', 'fetch', 'origin', '+refs/heads/' .. base .. ':' .. ref }, on_fetch)
        end

        run({
            'gh', 'pr', 'list', '--head', branch, '--state', 'open', '--limit', '1',
            '--json', 'baseRefName', '--jq', '.[0].baseRefName // "main"',
        }, on_base)
    end

    run({ 'git', 'symbolic-ref', '--short', 'HEAD' }, on_branch)
end

return {
    'TroyOwens0493/codediff.nvim',
    branch = 'feat/ai-change-summaries',
    cmd = { 'CodeDiff', 'CodeDiffAI' },
    opts = {
        ai = {
            enabled = true,
            effort = 'high',
            auto_summary = true,
            keymap = 'gs',
            why_keymap = 'gb',
            detail = 'detailed',
            max_input_bytes = math.huge,
        },
        explorer = {
            visible_groups = {
                staged = false,
            },
        },
    },
    keys = {
        { '<leader>gp', review_pr, desc = 'Fetch and merge PR base, then review branch' },
        { '<leader>gc', '<cmd>CodeDiff HEAD^ HEAD<CR>', desc = 'Review latest commit' },
        { '<leader>gu', '<cmd>CodeDiff<CR>', desc = 'Review unstaged changes' },
    },
}
