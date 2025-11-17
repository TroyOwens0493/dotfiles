-- Define the function to set colorscheme
function ColorMyPencils(color)
    color = color or "rose-pine"
    vim.cmd('colorscheme ' .. color)
end

-- Python files -> tokyonight
vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function()
        ColorMyPencils('tokyonight')
    end,
})

-- C# files -> yorumi (pattern should be "cs", not "CS")
vim.api.nvim_create_autocmd("FileType", {
    pattern = "cs",
    callback = function()
        ColorMyPencils('yorumi')
    end,
})

-- Rust files -> gruvbox
vim.api.nvim_create_autocmd("FileType", {
    pattern = "rust",
    callback = function()
        ColorMyPencils('gruvbox')
    end,
})

-- TypeScript/JavaScript files -> moonfly
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
    callback = function()
        ColorMyPencils('moonfly')
    end,
})

-- Set default colorscheme on startup
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        ColorMyPencils() -- Apply the default colorscheme after startup
    end,
})