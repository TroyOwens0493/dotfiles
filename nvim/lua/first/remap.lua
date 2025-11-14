vim.g.mapleader = " "
local builtin = require('telescope.builtin')
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
vim.keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format()
end)

vim.keymap.set("n", "<leader>j", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>lk", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>lj", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left>")

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set("n", "<leader>pf", builtin.find_files, {})
vim.keymap.set("n", "<C-p>", builtin.git_files, {})
vim.keymap.set("n", "<leader>ps", function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") });
end)

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

vim.keymap.set("n", "<leader>ts", function()
    require("supermaven-nvim.api").toggle()
    print("Supermaven is now " .. (require("supermaven-nvim.api").is_running() and "active" or "inactive"))
end, { desc = "Toggle Supermaven" })

vim.keymap.set("n", "<leader>xx", function() require("trouble").toggle() end)
vim.keymap.set("n", "<leader>xX", function() require("trouble").toggle("workspace_diagnostics") end)
vim.keymap.set("n", "<leader>xd", function() require("trouble").toggle("document_diagnostics") end)
vim.keymap.set("n", "<leader>xl", function() require("trouble").toggle("loclist") end)
vim.keymap.set("n", "<leader>xq", function() require("trouble").toggle("quickfix") end)
