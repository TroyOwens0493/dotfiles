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
local diff_files = {}

local function schedule_update()
    if pending then
        return
    end
    pending = true
    -- Select the theme after plugins finish changing windows and buffers.
    vim.schedule(function()
        pending = false
        local filetype = vim.bo.filetype
        local diff_file = diff_files[vim.api.nvim_get_current_tabpage()]
        if diff_file then
            -- The explorer and revision buffers have no language filetype.
            filetype = vim.filetype.match({ filename = diff_file })
        end
        local color = filetype_colors[filetype] or "rose-pine"
        -- Themes can set colors_name to a variant, such as tokyonight-moon.
        if color ~= current_color or vim.g.colors_name ~= current_colors_name then
            ColorMyPencils(color)
            current_color = color
            current_colors_name = vim.g.colors_name
        end
    end)
end

local group = vim.api.nvim_create_augroup("FiletypeColors", { clear = true })

-- FileType handles newly opened files; entry events handle files already loaded.
vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "WinEnter", "VimEnter", "TabEnter" }, {
    group = group,
    callback = function(event)
        if event.buf == vim.api.nvim_get_current_buf() then
            schedule_update()
        end
    end,
})

vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "CodeDiffFileSelect", "CodeDiffClose" },
    callback = function(event)
        local data = event.data
        if not data or not data.tabpage then
            return
        end
        diff_files[data.tabpage] = event.match == "CodeDiffFileSelect" and data.path or nil
        schedule_update()
    end,
})
