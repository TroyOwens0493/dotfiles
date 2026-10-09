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

        local refresh_timer
        local refresh_states = {}
        local function stop_refresh()
            if refresh_timer then
                vim.fn.timer_stop(refresh_timer)
                refresh_timer = nil
            end
            -- Discard results from checks started before the status was hidden.
            refresh_states = {}
        end

        local function visible_status_buffers()
            local buffers = {}
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.bo[buf].filetype == 'fugitive' then
                    buffers[buf] = true
                end
            end
            return buffers
        end

        local function status_signature(status, tree)
            local signature = { status }
            local fields = { ['1'] = 8, ['2'] = 9, u = 10, ['?'] = 1 }
            local skip_original = false
            for record in status:gmatch('[^%z]+') do
                if skip_original then
                    skip_original = false
                else
                    local kind = record:sub(1, 1)
                    local count = fields[kind]
                    if count then
                        -- Porcelain -z preserves spaces and newlines in filenames.
                        local path = record:match('^' .. ('%S+ '):rep(count) .. '(.*)$')
                        local stat = path and vim.uv.fs_stat(tree .. '/' .. path)
                        if stat then
                            -- Further edits to an already dirty file leave its
                            -- Git status unchanged, but can change expanded diffs.
                            signature[#signature + 1] = vim.inspect({ stat.size, stat.mtime, stat.ctime })
                        end
                        skip_original = kind == '2'
                    end
                end
            end
            return table.concat(signature, '\0')
        end

        local function poll_status(buf, repo)
            local tree = vim.fn.FugitiveWorkTree(buf)
            if tree == '' then
                return
            end
            local state = refresh_states[repo]
            if not state then
                state = {}
                refresh_states[repo] = state
            end
            if state.pending then
                return
            end
            state.pending = true
            -- Check asynchronously without entering windows or redrawing them.
            vim.system({
                'git', '--git-dir=' .. repo, '--work-tree=' .. tree,
                '--no-optional-locks', 'status', '--porcelain=v2', '--branch',
                '--show-stash', '--untracked-files=all', '-z',
            }, { cwd = tree, timeout = 10000 }, vim.schedule_wrap(function(result)
                if refresh_states[repo] ~= state then
                    return
                end
                state.pending = false
                if result.code ~= 0 or vim.api.nvim_get_mode().mode ~= 'n' then
                    return
                end
                local signature = status_signature(result.stdout, tree)
                if signature == state.signature then
                    return
                end
                for visible_buf in pairs(visible_status_buffers()) do
                    if vim.fn.FugitiveGitDir(visible_buf) == repo then
                        state.signature = signature
                        vim.fn.FugitiveDidChange(visible_buf)
                        break
                    end
                end
            end))
        end

        local function update_refresh()
            if not next(visible_status_buffers()) then
                stop_refresh()
            elseif not refresh_timer then
                refresh_timer = vim.fn.timer_start(1000, function()
                    local buffers = visible_status_buffers()
                    if not next(buffers) then
                        stop_refresh()
                        return
                    end
                    if vim.api.nvim_get_mode().mode ~= 'n' then
                        return
                    end
                    local refreshed = {}
                    for buf in pairs(buffers) do
                        local repo = vim.fn.FugitiveGitDir(buf)
                        if repo ~= '' and not refreshed[repo] then
                            refreshed[repo] = true
                            poll_status(buf, repo)
                        end
                    end
                end, { ['repeat'] = -1 })
            end
        end

        local pending = false
        local function schedule_update()
            if pending then
                return
            end
            pending = true
            vim.schedule(function()
                pending = false
                resize_status()
                update_refresh()
            end)
        end

        local group = vim.api.nvim_create_augroup('FugitiveAutoHeight', { clear = true })
        vim.api.nvim_create_autocmd({
            'BufWinEnter', 'BufWinLeave', 'TabEnter', 'WinClosed',
            'TextChanged', 'VimResized', 'WinResized',
        }, {
            group = group,
            callback = schedule_update,
        })
        vim.api.nvim_create_autocmd('User', {
            group = group,
            pattern = { 'FugitiveIndex', 'FugitiveChanged' },
            callback = schedule_update,
        })
        vim.api.nvim_create_autocmd('VimLeavePre', {
            group = group,
            callback = stop_refresh,
        })
        schedule_update()
    end,
}
