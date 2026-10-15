local function setup_telescope()
    local builtin = require('telescope.builtin')
    local function grep_prompt()
        builtin.grep_string({ search = vim.fn.input("Grep > ") })
    end

    vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
    vim.keymap.set('n', '<leader>pft', builtin.git_files, {})
    vim.keymap.set('n', '<leader>ps', grep_prompt)
end

return {
    'nvim-telescope/telescope.nvim',
    tag = 'v0.2.2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = setup_telescope,
}
