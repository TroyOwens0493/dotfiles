local function setup_trouble()
    require("trouble").setup {
        icons = true,
    }
end

return {
    "folke/trouble.nvim",
    config = setup_trouble,
}
