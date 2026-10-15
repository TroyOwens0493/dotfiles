vim.g.mapleader = " "
local builtin = require('telescope.builtin')

--- Format the current buffer using its configured formatter.
local function format_buffer()
    require('conform').format({ async = true })
end

local function grep_prompt()
    builtin.grep_string({ search = vim.fn.input("Grep > ") })
end

local function toggle_supermaven()
    require("supermaven-nvim.api").toggle()
    print("Supermaven is now " .. (require("supermaven-nvim.api").is_running() and "active" or "inactive"))
end

local function toggle_trouble()
    require("trouble").toggle()
end

local function toggle_workspace_diagnostics()
    require("trouble").toggle("workspace_diagnostics")
end

local function toggle_document_diagnostics()
    require("trouble").toggle("document_diagnostics")
end

local function toggle_location_list()
    require("trouble").toggle("loclist")
end

local function toggle_quickfix()
    require("trouble").toggle("quickfix")
end

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "nr", "nzzzv")
vim.keymap.set("n", "pr", "Nzzzv")

vim.keymap.set("x", "<leader>p", "\"_dP")

vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")

vim.keymap.set("n", "<leader>d", "\"_d")
vim.keymap.set("v", "<leader>d", "\"_d")

vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "nt", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "<leader>f", format_buffer, { desc = 'Format buffer' })

vim.keymap.set("n", "<leader>j", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>lk", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>lj", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left>")

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set("n", "<leader>pf", builtin.find_files, {})
vim.keymap.set("n", "<C-p>", builtin.git_files, {})
vim.keymap.set("n", "<leader>ps", grep_prompt)

vim.keymap.set("n", "<leader>wt", ":set wrap!<CR>")

-- Function to open Lazygit in a floating terminal window
local function open_lazygit()
    -- Window configuration
    local width = math.floor(vim.o.columns * 0.8)      -- 80% of screen width
    local height = math.floor(vim.o.lines * 0.8)       -- 80% of screen height
    local row = math.floor((vim.o.lines - height) / 2) -- Center the window
    local col = math.floor((vim.o.columns - width) / 2)

    -- Create the floating window
    local buf = vim.api.nvim_create_buf(false, true) -- Create a new empty buffer
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "single" -- You can change the border style
    })

    -- Run Lazygit in the terminal inside the floating window
    vim.fn.termopen("lazygit", { detach = 0 })

    -- Enter terminal mode in the buffer automatically
    vim.cmd("startinsert") -- Start terminal input mode
end

-- Keymap to open Lazygit
vim.keymap.set("n", "<leader>lg", open_lazygit, { noremap = true, silent = true, desc = "Open Lazygit" })

-- Keymap to open .md preview
vim.keymap.set("n", "<leader>md", "<cmd>Glow<CR>", { desc = "Open Markdown Preview" })

vim.keymap.set("n", "<leader>ts", toggle_supermaven, { desc = "Toggle Supermaven" })

vim.keymap.set("n", "<leader>xx", toggle_trouble)
vim.keymap.set("n", "<leader>xX", toggle_workspace_diagnostics)
vim.keymap.set("n", "<leader>xd", toggle_document_diagnostics)
vim.keymap.set("n", "<leader>xl", toggle_location_list)
vim.keymap.set("n", "<leader>xq", toggle_quickfix)
