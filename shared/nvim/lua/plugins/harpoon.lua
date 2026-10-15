local function setup_harpoon()
    local harpoon = require("harpoon")

    local function add_file()
        harpoon:list():add()
    end

    local function toggle_menu()
        harpoon.ui:toggle_quick_menu(harpoon:list())
    end

    local function select_file(index)
        local function select()
            harpoon:list():select(index)
        end
        return select
    end

    harpoon:setup()

    vim.keymap.set("n", "<leader>a", add_file)
    vim.keymap.set("n", "<C-e>", toggle_menu)

    vim.keymap.set("n", "<C-y>", select_file(1))
    vim.keymap.set("n", "<C-h>", select_file(2))
    vim.keymap.set("n", "<C-j>", select_file(3))
    vim.keymap.set("n", "<C-m>", select_file(4))
end

return {
    'theprimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { "nvim-lua/plenary.nvim" },
    config = setup_harpoon,
}
