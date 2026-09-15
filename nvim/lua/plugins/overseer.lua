return {
    'stevearc/overseer.nvim',
    ---@module 'overseer'
    ---@type overseer.SetupOpts
    opts = {},
    keys = {
        { '<leader>tr', '<cmd>OverseerRun<CR>', desc = 'Run task' },
        { '<leader>tv', '<cmd>OverseerToggle<CR>', desc = 'Toggle task list' },
    },
}
