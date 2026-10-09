return {
    'esmuellert/codediff.nvim',
    cmd = 'CodeDiff',
    opts = {
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
