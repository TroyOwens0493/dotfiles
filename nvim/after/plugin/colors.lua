-- Define the function in Lua
function ColorMyPencils(color)
    color = color or "rose-pine"
    vim.cmd('colorscheme ' .. color)
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function()
        ColorMyPencils('tokyonight')
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "CS",
    callback = function()
        ColorMyPencils('yorumi')
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "rust",
    callback = function()
        ColorMyPencils('gruvbox')
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "typescript", "javascript", "typescriptreact", "javascriptreact" }, -- Array of patterns
    callback = function()
        ColorMyPencils('moonfly')
    end,
})

vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        ColorMyPencils() -- Apply the default colorscheme after startup
    end,
})
