-- Define the function to set colorscheme
function ColorMyPencils(color)
    color = color or "rose-pine"
    vim.cmd('colorscheme ' .. color)
end

local filetype_colors = {
    python = "tokyonight",
    cs = "yorumi",
    rust = "gruvbox",
    typescript = "moonfly",
    javascript = "moonfly",
    typescriptreact = "moonfly",
    javascriptreact = "moonfly",
}

local current_color
local current_colors_name
local pending = false

-- FileType handles newly opened files; entry events handle files already loaded.
vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "WinEnter", "VimEnter" }, {
    group = vim.api.nvim_create_augroup("FiletypeColors", { clear = true }),
    callback = function(event)
        if event.buf ~= vim.api.nvim_get_current_buf() then
            return
        end
        if pending then
            return
        end
        pending = true
        -- Fugitive can temporarily enter its status window while refreshing.
        -- Select the theme after it has restored the user's current window.
        vim.schedule(function()
            pending = false
            local color = filetype_colors[vim.bo.filetype] or "rose-pine"
            -- Themes can set colors_name to a variant, such as tokyonight-moon.
            if color ~= current_color or vim.g.colors_name ~= current_colors_name then
                ColorMyPencils(color)
                current_color = color
                current_colors_name = vim.g.colors_name
            end
        end)
    end,
})
