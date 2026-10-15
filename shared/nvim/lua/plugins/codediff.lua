local dev_path = vim.fn.expand('~/nvimPuginDev/codediff.nvim')

return {
    'TroyOwens0493/codediff.nvim',
    dir = vim.fn.isdirectory(dev_path) == 1 and dev_path or nil,
    cmd = { 'CodeDiff', 'CodeDiffAI' },
    opts = {
        ai = {
            enabled = true,
            auto_summary = true,
            keymap = 'gs',
            why_keymap = 'gb',
            detail = 'detailed',
        },
        explorer = {
            visible_groups = {
                staged = false,
            },
        },
    },
    keys = {
        { '<leader>gp', '<cmd>CodeDiff main HEAD<CR>', desc = 'Review branch against main' },
        { '<leader>gc', '<cmd>CodeDiff HEAD^ HEAD<CR>', desc = 'Review latest commit' },
        { '<leader>gu', '<cmd>CodeDiff<CR>', desc = 'Review unstaged changes' },
    },
}
