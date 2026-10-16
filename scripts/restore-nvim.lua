-- lazy.setup may have rewritten its cached lock while installing missing plugins.
-- Restore from the installer's snapshot, rather than that mutated cache.
local pins = vim.json.decode(table.concat(vim.fn.readfile(vim.env.DOTFILES_NVIM_LOCK_SNAPSHOT), "\n"))
local plugins = require("lazy.core.config").plugins

-- Omarchy ships shallow plugin caches. A normal fetch can leave older locked
-- commits outside their history, so fetch any missing pin before restoring it.
for name, plugin in pairs(plugins) do
    if pins[name] and not plugin._.is_local then
        local commit = pins[name].commit
        vim.fn.system({ "git", "-C", plugin.dir, "cat-file", "-e", commit .. "^{commit}" })
        if vim.v.shell_error ~= 0 then
            local output = vim.fn.system({
                "git", "-C", plugin.dir, "fetch", "--quiet", "--no-tags", "--depth=1", "origin", commit,
            })
            if vim.v.shell_error ~= 0 then
                vim.api.nvim_err_writeln(name .. ": cannot fetch locked commit\n" .. output)
                vim.cmd("cquit 1")
            end
        end
    end
end

local lock = require("lazy.manage.lock")
lock.lock = vim.deepcopy(pins)
lock._loaded = true
require("lazy").restore({ wait = true })

local failures = {}
for name, plugin in pairs(plugins) do
    if require("lazy.core.plugin").has_errors(plugin) then
        table.insert(failures, name .. ": plugin task failed")
    end
    if pins[name] and not plugin._.is_local then
        local commit = vim.fn.system({ "git", "-C", plugin.dir, "rev-parse", "HEAD" }):gsub("%s+$", "")
        if vim.v.shell_error ~= 0 or commit ~= pins[name].commit then
            table.insert(failures, name .. ": checkout does not match lazy-lock.json")
        end
    end
end
if #failures > 0 then
    vim.api.nvim_err_writeln(table.concat(failures, "\n"))
    vim.cmd("cquit 1")
end
