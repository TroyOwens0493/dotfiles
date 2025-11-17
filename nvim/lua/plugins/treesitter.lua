return {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
        require('nvim-treesitter.configs').setup({
            -- Add your treesitter configuration here
            ensure_installed = { "lua", "python", "javascript", "typescript", "rust", "go", "html", "css", "json", "yaml", "markdown" },
            highlight = { enable = true },
            indent = { enable = true },
        })
    end,
}

