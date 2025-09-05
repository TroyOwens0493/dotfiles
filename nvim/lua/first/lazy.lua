-- Bootstrap lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- Loading lazy so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy
require("lazy").setup({
    spec = {
        -- Telescope
        { 'nvim-telescope/telescope.nvim', config = true,     tag = '0.1.8' },

        -- Colorschemes
        { "rose-pine/neovim",              name = "rose-pine" },
        "folke/tokyonight.nvim",
        "yorumicolors/yorumi.nvim",
        "morhetz/gruvbox",
        "bluz71/vim-moonfly-colors",

        -- Trouble
        {
            "folke/trouble.nvim",
            config = function()
                require("trouble").setup {
                    icons = false,
                }
            end
        },

        {
            'nvim-treesitter/nvim-treesitter',
            build = ':TSUpdate',
            config = true
        },

        {
            'nvim-lua/plenary.nvim',
            lazy = false
        },

        -- Harpoon
        { 'theprimeagen/harpoon',  config = true },

        -- UndoTree
        {
            'mbbill/undotree',
            config = function()
                vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
            end
        },

        -- Fugitive
        {
            'tpope/vim-fugitive',
            config = function()
                vim.keymap.set('n', '<leader>gs', vim.cmd.Git)
            end
        },

        -- LSP Zero
        {
            'VonHeikemen/lsp-zero.nvim',
            branch = 'v3.x',
            dependencies = {
                -- Uncomment if you want to manage language servers from neovim
                'williamboman/mason.nvim',
                'williamboman/mason-lspconfig.nvim',
                'neovim/nvim-lspconfig',
                'hrsh7th/nvim-cmp',
                'hrsh7th/cmp-nvim-lsp',
                'L3MON4D3/LuaSnip',
            }
        },

        -- Markdown previewer
        { "ellisonleao/glow.nvim", config = true },
        -- SuperMaven AI autocompletion
        {
            "supermaven-inc/supermaven-nvim",
        },
    },

    -- Colorscheme that will be used when installing plugins.
    install = { colorscheme = { "habamax" } },

    -- Automatically check for plugin updates
    checker = { enabled = true },
})
