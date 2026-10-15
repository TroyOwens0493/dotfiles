---Starts Treesitter features for filetypes backed by installed parsers.
local function start_treesitter()
    local ok = pcall(vim.treesitter.start)
    if not ok then
        return
    end

    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end

---Configures parser installation and enables Treesitter features per filetype.
local function setup_treesitter()
    local parsers = { "lua", "python", "javascript", "typescript", "tsx", "rust", "go", "html", "css", "json", "yaml", "markdown", "astro", "svelte", "powershell" }
    local filetypes = { "lua", "python", "javascript", "javascriptreact", "typescript", "typescriptreact", "rust", "go", "html", "css", "json", "yaml", "markdown", "astro", "svelte", "ps1" }

    require('nvim-treesitter').setup()
    require('nvim-treesitter').install(parsers)

    vim.treesitter.language.register('powershell', 'ps1')

    vim.api.nvim_create_autocmd('FileType', {
        pattern = filetypes,
        callback = start_treesitter,
    })
end

return {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = setup_treesitter,
}
