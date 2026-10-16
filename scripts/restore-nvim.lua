-- lazy.setup may have rewritten its cached lock while installing missing plugins.
-- Restore from the installer's snapshot, rather than that mutated cache.
local pins = vim.json.decode(table.concat(vim.fn.readfile(vim.env.DOTFILES_NVIM_LOCK_SNAPSHOT), "\n"))
local lock = require("lazy.manage.lock")
lock.lock = vim.deepcopy(pins)
lock._loaded = true
require("lazy").restore({ wait = true })

local failures = {}
local plugins = require("lazy.core.config").plugins
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
