vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true
vim.opt.winborder = "rounded"

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50
vim.opt.autoread = true

vim.opt.colorcolumn = "80"

local autoread_group = vim.api.nvim_create_augroup("AutoRead", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
    command = "checktime",
    group = autoread_group,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = autoread_group,
    callback = function()
        vim.notify("File changed on disk.")
    end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
    desc = "Briefly highlight yanked text",
    --- Flash the region affected by a yank.
    callback = function()
        vim.hl.on_yank({ higroup = "IncSearch", timeout = 100 })
    end,
})

vim.g.mapleader = " "
