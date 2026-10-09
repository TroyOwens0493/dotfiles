-- Run from the repo: nvim --headless -u NONE -l tests/test_nvim_fugitive.lua
-- Uses the installed, locked vim-fugitive plugin; all Git changes are isolated.
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
local plugin = vim.fn.stdpath('data') .. '/lazy/vim-fugitive'
assert(vim.fn.isdirectory(plugin) == 1, 'Install the locked vim-fugitive plugin first')
local repo = vim.fn.tempname() .. ' repo'
vim.fn.mkdir(repo, 'p')

local function git(...)
    local result = vim.system({ 'git', '-C', repo, ... }):wait()
    assert(result.code == 0, result.stderr)
end

local function commit(message)
    git('-c', 'user.name=Test', '-c', 'user.email=test@example.com',
        '-c', 'core.hooksPath=/dev/null', '-c', 'commit.gpgsign=false', 'commit', '-qm', message)
end

local function wait_for(predicate, message)
    assert(vim.wait(4000, predicate, 20), message)
end

local function settle()
    vim.wait(100, function() return false end, 10)
end

local function run()
    git('init', '-q')
    vim.fn.writefile({ 'print("hello")' }, repo .. '/example.py')
    vim.fn.writefile({ 'print("rename")' }, repo .. '/rename.py')
    vim.fn.writefile({ 'const value = 1;' }, repo .. '/example.ts')
    git('add', '.')
    commit('initial')

    vim.opt.rtp:append(plugin)
    vim.cmd('runtime plugin/fugitive.vim')
    vim.cmd('filetype on')
    dofile(root .. '/shared/nvim/lua/first/colors.lua')
    local colors = {}
    -- Exercise variant names without requiring every colorscheme plugin.
    ColorMyPencils = function(color)
        colors[#colors + 1] = color
        vim.g.colors_name = color == 'tokyonight' and 'tokyonight-moon' or color
    end
    dofile(root .. '/shared/nvim/lua/plugins/vim-fugitive.lua').config()

    vim.cmd.edit(repo .. '/example.py')
    settle()
    assert(vim.g.colors_name == 'tokyonight-moon', 'Python theme was not selected')
    vim.cmd.Git()
    local status_buf = vim.api.nvim_get_current_buf()
    settle()
    assert(vim.g.colors_name == 'rose-pine', 'Focusing Git status should select the default theme')
    vim.cmd('wincmd p')
    settle()
    local file_win = vim.api.nvim_get_current_win()
    local file_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_win_set_cursor(file_win, { 1, 5 })

    local refreshes = 0
    vim.api.nvim_create_autocmd('User', {
        pattern = 'FugitiveIndex',
        callback = function() refreshes = refreshes + 1 end,
    })
    local function assert_focus()
        assert(vim.api.nvim_get_current_win() == file_win, 'Polling changed the active window')
        assert(vim.api.nvim_get_current_buf() == file_buf, 'Polling changed the active buffer')
        assert(vim.deep_equal(vim.api.nvim_win_get_cursor(file_win), { 1, 5 }), 'Polling moved the cursor')
        assert(vim.g.colors_name == 'tokyonight-moon', 'Polling changed the Python theme')
    end

    wait_for(function() return refreshes > 0 end, 'Initial status check did not complete')
    settle()
    assert_focus()
    local baseline, theme_count = refreshes, #colors
    vim.wait(2200, function() return false end, 20)
    assert(refreshes == baseline, 'Unchanged polls refreshed the status window')
    assert(#colors == theme_count, 'Unchanged polls reapplied the colorscheme')
    assert_focus()

    local function change(action)
        local previous = refreshes
        action()
        wait_for(function() return refreshes > previous end, 'External Git change was not refreshed')
        settle()
        assert_focus()
    end
    change(function() vim.fn.writefile({ 'print("changed")' }, repo .. '/example.py') end)
    assert(table.concat(vim.api.nvim_buf_get_lines(status_buf, 0, -1, false), '\n'):find('Unstaged'),
        'Status did not display the external edit')
    -- Same size, same Git status: metadata must still detect a further edit.
    change(function() vim.fn.writefile({ 'print("another")' }, repo .. '/example.py') end)
    change(function() git('add', 'example.py') end)
    assert(table.concat(vim.api.nvim_buf_get_lines(status_buf, 0, -1, false), '\n'):find('Staged'),
        'Status did not display the staged edit')
    change(function() commit('external commit') end)
    change(function() git('mv', 'rename.py', 'renamed file.py') end)
    change(function() vim.fn.writefile({ 'print("renamed")' }, repo .. '/renamed file.py') end)
    local unusual_path = repo .. '/new file\nwith newline.py'
    change(function() vim.fn.writefile({ 'first' }, unusual_path) end)
    change(function() vim.fn.writefile({ 'other' }, unusual_path) end)

    -- Real file switches still change the theme, including already loaded files.
    vim.cmd.edit(repo .. '/example.ts')
    settle()
    assert(vim.g.colors_name == 'moonfly', 'TypeScript theme was not selected')
    vim.cmd.buffer(file_buf)
    settle()
    assert(vim.g.colors_name == 'tokyonight-moon', 'Returning to a loaded file did not restore its theme')

    -- Reproduce a native/manual Fugitive refresh outside our polling code too.
    theme_count = #colors
    vim.fn.FugitiveDidChange(status_buf)
    settle()
    assert_focus()
    assert(#colors == theme_count, 'Temporary status entry reapplied the colorscheme')

    vim.api.nvim_buf_delete(status_buf, { force = true })
    settle()
    baseline = refreshes
    vim.fn.writefile({ 'const value = 2;' }, repo .. '/example.ts')
    vim.wait(1200, function() return false end, 20)
    assert(refreshes == baseline, 'Polling continued after the status window closed')
    print('PASS: colors, idle polls, external edits, staging, commits, renames, unusual paths, and timer cleanup')
end

local ok, err = xpcall(run, debug.traceback)
vim.fn.delete(repo, 'rf')
if not ok then
    io.stderr:write(err .. '\n')
    vim.cmd('cquit 1')
end
vim.cmd('qa!')
