vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('user_lsp_attach', { clear = true }),
    callback = function(event)
        local opts = { buffer = event.buf }

        vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end, opts)
        vim.keymap.set('n', 'si', function() vim.lsp.buf.hover() end, opts)
        vim.keymap.set('n', '<leader>vws', function() vim.lsp.buf.workspace_symbol() end, opts)
        vim.keymap.set('n', '<leader>vd', function() vim.diagnostic.open_float() end, opts)
        vim.keymap.set('n', '[d', function() vim.diagnostic.goto_next() end, opts)
        vim.keymap.set('n', ']d', function() vim.diagnostic.goto_prev() end, opts)
        vim.keymap.set('n', '<leader>vca', function() vim.lsp.buf.code_action() end, opts)
        vim.keymap.set('n', '<leader>vfr', function() vim.lsp.buf.references() end, opts)
        vim.keymap.set('n', '<leader>vrn', function() vim.lsp.buf.rename() end, opts)
        vim.keymap.set('i', '<C-h>', function() vim.lsp.buf.signature_help() end, opts)
    end,
})

-- capabilities for cmp
local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()

require('mason').setup({})

-- mason-lspconfig: register server configs using vim.lsp.config and enable them
local mason_lspconfig = require('mason-lspconfig')

mason_lspconfig.setup({
    ensure_installed = {
        'ts_ls',
        'jsonls',
        'rust_analyzer',
        'pylsp',
        'gopls',
        'html',
        'cssls',
        'clangd',
        'omnisharp',
        'harper_ls',
        'emmet_language_server',
        'erlangls',
        'zls',
    },
    handlers = {
        -- Default handler: register and enable server with basic capabilities
        function(server_name) -- Fallback/default handler
            -- Register the server config (this associates the config with `server_name`)
            vim.lsp.config(server_name, {
                capabilities = lsp_capabilities,
            })
            -- Enable auto-starting for that server (filetype matching will start it)
            -- If you want to start immediately for open buffers, you can call vim.lsp.start()
            vim.lsp.enable(server_name)
        end,

        -- Server override for Lua_ls (keeps my Lua settings)
        lua_ls = function()
            vim.lsp.config('lua_ls', {
                capabilities = lsp_capabilities,
                settings = {
                    Lua = {
                        runtime = {
                            version = 'LuaJIT',
                        },
                        diagnostics = {
                            globals = { 'vim' },
                        },
                        workspace = {
                            library = {
                                vim.env.VIMRUNTIME,
                            },
                        },
                    },
                },
            })
            vim.lsp.enable('lua_ls')
        end,
    },
})

-- Manual server setup
vim.lsp.config('sourcekit', {
    capabilities = lsp_capabilities,
    filetypes = { 'swift', 'objective-c', 'objective-cpp' },
    cmd = { 'xcrun', 'sourcekit-lsp' },
})
vim.lsp.enable('sourcekit')

-- Cmp setup remains unchanged
local cmp = require('cmp')
local cmp_select = { behavior = cmp.SelectBehavior.Select }

cmp.setup({
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
    }, {
        { name = 'buffer' },
    }),
    mapping = cmp.mapping.preset.insert({
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
        ['<C-Space>'] = cmp.mapping.complete(),
    }),
    snippet = {
        expand = function(args)
            require('luasnip').lsp_expand(args.body)
        end,
    },
})
