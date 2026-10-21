local function review_pr()
    local root = vim.fs.root(0, '.git') or vim.fs.root(vim.fn.getcwd(), '.git')
    if not root then
        vim.notify('Not in a Git repository', vim.log.levels.ERROR)
        return
    end

    if vim.fn.executable('gh') == 0 then
        vim.notify('GitHub CLI (gh) is required to find the branch PR', vim.log.levels.ERROR)
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
        local function on_pr(output)
            if output == '' then
                vim.notify('No open PR found for branch ' .. branch, vim.log.levels.ERROR)
                return
            end

            local pr = vim.json.decode(output)
            vim.api.nvim_cmd({
                cmd = 'CodeDiff',
                args = { '--repo', root, 'pr', tostring(pr.number), '--base', pr.baseRefName },
            }, {})
        end

        run({
            'gh', 'pr', 'list', '--head', branch, '--state', 'open', '--limit', '1',
            '--json', 'number,baseRefName', '--jq', '.[0] // empty',
        }, on_pr)
    end

    run({ 'git', 'symbolic-ref', '--short', 'HEAD' }, on_branch)
end

return {
    'TroyOwens0493/codediff.nvim',
    dir = vim.fn.isdirectory(vim.fn.expand('~/nvimPuginDev/codediff.nvim')) == 1
        and vim.fn.expand('~/nvimPuginDev/codediff.nvim') or nil,
    branch = 'feat/ai-change-summaries',
    cmd = { 'CodeDiff', 'CodeDiffAI', 'CodeDiffReview' },
    opts = {
        -- AI behavior lives in the fork; this table sets personal preferences.
        ai = {
            enabled = true,
            effort = 'high',
            auto_summary = true,
            keymap = 'gs',
            why_keymap = 'gb',
            explain_keymap = '<leader>ge',
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
        { '<leader>gp', review_pr, desc = 'Review current branch PR' },
        { '<leader>gc', '<cmd>CodeDiff HEAD^ HEAD<CR>', desc = 'Review latest commit' },
        { '<leader>gu', '<cmd>CodeDiff<CR>', desc = 'Review unstaged changes' },
    },
}
