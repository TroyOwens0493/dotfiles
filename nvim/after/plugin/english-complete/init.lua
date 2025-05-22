local ls = require("luasnip")

-- Load snippets from your lua/luasnip_snippets.lua file
-- This assumes your snippets are in a `luasnip_snippets.lua` file
-- inside the `lua` directory of your plugin.
ls.add_snippets("markdown", require("english-complete.luasnip_snippets"))

-- You might also want to ensure auto-triggering if not already handled by nvim-cmp settings
-- This is often handled by nvim-cmp's mapping for '<Tab>' or similar.
-- If you want snippets to expand automatically as you type, you'd add:
 vim.keymap.set({"i"}, "<Tab>", function()
     if ls.expand_or_jumpable() then
         ls.expand_or_jump()
     end
 end, { silent = true })

 vim.keymap.set({"i", "s"}, "<S-Tab>", function()
     if ls.jumpable(-1) then
         ls.jump(-1)
     end
 end, { silent = true })
