-- Load the personal development plugin only when its checkout is available.
local path = vim.fn.expand("~/nvimPuginDev/singlemaven-nvim")
if vim.fn.isdirectory(path) == 1 then
    return { dir = path }
end
return {}
