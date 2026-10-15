local function setup_supermaven()
    require("supermaven-nvim").setup({
        keymaps = {
            accept_suggestion = "<C-l>",
            clear_suggestion = "<C-]>",
            accept_word = "<C-j>",
        },
    })
end

return {
    "supermaven-inc/supermaven-nvim",
    config = setup_supermaven,
}
