return {
    'tpope/vim-fugitive',
    config = function()
        vim.keymap.set('n', '<leader>gs', vim.cmd.Git)

        local function resize_status()
            local windows = {}
            local top, bottom = math.huge, 0
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                if vim.api.nvim_win_get_config(win).relative == '' then
                    windows[#windows + 1] = win
                    local row = vim.api.nvim_win_get_position(win)[1]
                    top = math.min(top, row)
                    bottom = math.max(bottom, row + vim.api.nvim_win_get_height(win))
                end
            end
            if #windows < 2 then
                return
            end

            local max_height = math.max(1, math.floor((bottom - top) / 2))
            for _, win in ipairs(windows) do
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.bo[buf].filetype == 'fugitive' then
                    -- Count displayed rows, including wrapped lines and folded sections.
                    local height = math.min(vim.api.nvim_win_text_height(win, {}).all, max_height)
                    vim.wo[win].winfixheight = true
                    if vim.api.nvim_win_get_height(win) ~= height then
                        vim.api.nvim_win_set_height(win, height)
                    end
                end
            end
        end

        local pending = false
        local function schedule_resize()
            if pending then
                return
            end
            pending = true
            vim.schedule(function()
                pending = false
                resize_status()
            end)
        end

        local group = vim.api.nvim_create_augroup('FugitiveAutoHeight', { clear = true })
        vim.api.nvim_create_autocmd({ 'BufWinEnter', 'TextChanged', 'VimResized', 'WinResized' }, {
            group = group,
            callback = schedule_resize,
        })
        vim.api.nvim_create_autocmd('User', {
            group = group,
            pattern = { 'FugitiveIndex', 'FugitiveChanged' },
            callback = schedule_resize,
        })
    end,
}
