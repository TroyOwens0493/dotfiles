return {
    -- LSP Support
    'neovim/nvim-lspconfig',
    {
        'williamboman/mason-lspconfig.nvim',
        dependencies = {
            'williamboman/mason.nvim',
            'hrsh7th/cmp-nvim-lsp',
        },
        config = function()
            -- Setup capabilities first
            local cmp_capabilities = require('cmp_nvim_lsp').default_capabilities()

            -- Setup mason-lspconfig
            require('mason-lspconfig').setup({
                ensure_installed = {
                    'vtsls',
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
                    'astro',
                },
                handlers = {
                    function(server_name)
                        vim.lsp.config(server_name, {
                            capabilities = cmp_capabilities,
                        })
                        vim.lsp.enable(server_name)
                    end,
                    lua_ls = function()
                        vim.lsp.config('lua_ls', {
                            capabilities = cmp_capabilities,
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

            -- Swift support
            vim.lsp.config('sourcekit', {
                capabilities = cmp_capabilities,
                filetypes = { 'swift', 'objective-c', 'objective-cpp' },
                cmd = { 'xcrun', 'sourcekit-lsp' },
            })
            vim.lsp.enable('sourcekit')

            -- LSP keymaps
            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('user_lsp_attach', { clear = true }),
                callback = function(event)
                    local opts = { buffer = event.buf }

                    -- Function to goto definition
                    -- It will just if there is only one definition
                    -- It also will remove duplicates (in case you have multiple lsps returning the same result)
                    -- Otherwise it will open the quickfix window
                    vim.keymap.set('n', 'gd', function()
                        vim.lsp.buf.definition({
                            on_list = function(options)
                                local items = options.items
                                if #items > 1 then
                                    local seen = {}
                                    local unique_items = {}
                                    for _, item in ipairs(items) do
                                        local key = (item.filename or item.bufnr or '') ..
                                            ':' .. item.lnum .. ':' .. item.col
                                        if not seen[key] then
                                            table.insert(unique_items, item)
                                            seen[key] = true
                                        end
                                    end
                                    items = unique_items
                                    options.items = unique_items
                                end

                                if #items > 1 then
                                    vim.fn.setqflist({}, ' ', options)
                                    vim.cmd.copen()
                                elseif #items == 1 then
                                    local item = items[1]
                                    vim.cmd("normal! m'")
                                    if item.bufnr then
                                        vim.cmd('b ' .. item.bufnr)
                                    else
                                        vim.cmd('e ' .. vim.fn.fnameescape(item.filename))
                                    end
                                    vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
                                end
                            end,
                        })
                    end, opts)

                    -- Lsp remaps
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
        end,
    },
}
