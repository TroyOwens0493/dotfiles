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
    branch = 'main',
    cmd = { 'CodeDiff', 'CodeDiffAI', 'CodeDiffReview' },
    opts = {
        highlights = {
            char_whole_line = false,
        },
        diff = {
            layout = 'inline',
            show_deleted_lines = false,
            gutter_signs = {
                insert_text = '+',
                delete_text = '-',
                highlight_numbers = true,
            },
        },
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
    config = function(_, opts)
        require('codediff').setup(opts)

        local function changed_text_only()
            -- Keep the theme's character highlights, without whole-line shading.
            vim.api.nvim_set_hl(0, 'CodeDiffLineInsert', {})
            vim.api.nvim_set_hl(0, 'CodeDiffLineDelete', {})
            vim.api.nvim_set_hl(0, 'CodeDiffGutterInsert', { link = 'DiagnosticOk' })
            vim.api.nvim_set_hl(0, 'CodeDiffGutterDelete', { link = 'DiagnosticError' })
            vim.api.nvim_set_hl(0, 'CodeDiffGutterInsertNumber', { link = 'DiagnosticOk' })
            vim.api.nvim_set_hl(0, 'CodeDiffGutterDeleteNumber', { link = 'DiagnosticError' })
        end

        changed_text_only()
        vim.api.nvim_create_autocmd('ColorScheme', {
            group = vim.api.nvim_create_augroup('CodeDiffChangedTextOnly', { clear = true }),
            callback = changed_text_only,
        })
    end,
    keys = {
        { '<leader>gp', review_pr, desc = 'Review current branch PR' },
        { '<leader>gv', '<cmd>CodeDiffReview start<CR>', desc = 'Create or open guided review' },
        { '<leader>gc', '<cmd>CodeDiff HEAD^ HEAD<CR>', desc = 'Review latest commit' },
        { '<leader>gh', '<cmd>CodeDiff history origin/main..HEAD<CR>', desc = 'Review branch history from origin/main' },
        { '<leader>gu', '<cmd>CodeDiff<CR>', desc = 'Review unstaged changes' },
    },
}
