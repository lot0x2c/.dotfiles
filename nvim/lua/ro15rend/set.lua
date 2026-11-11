local set = vim.opt

set.nu = true
set.relativenumber = true

set.tabstop = 4
set.softtabstop = -1
set.shiftwidth = 4
set.expandtab = true

-- editorconfig still wins per project
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("UserIndent", { clear = true }),
    pattern = { "html", "css", "scss", "less", "javascript", "javascriptreact",
        "typescript", "typescriptreact", "json", "jsonc", "yaml", "nix" },
    callback = function(ev)
        vim.bo[ev.buf].shiftwidth = 2
        vim.bo[ev.buf].tabstop = 2
    end,
})

set.smartindent = true
set.guicursor = "a:block-blinkon0"
set.signcolumn = "yes"

-- Keep unsaved edits recoverable after an editor or system crash.
set.swapfile = true
set.undofile = true
set.clipboard:append("unnamedplus")

set.hlsearch = false
set.inccommand = "split"
set.ignorecase = true

set.termguicolors = true

set.scrolloff = 999

set.isfname:append("@-@")
-- also the diagnostic float delay
set.updatetime = 950

set.splitbelow = true
set.splitright = true

-- Recursive searches belong to the project finder, not every :find completion.
set.wildoptions = "fuzzy,pum,tagfile"

vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("UserYank", {}),
    callback = function()
        vim.hl.on_yank({ higroup = "IncSearch", timeout = 150 })
    end,
})

set.virtualedit = "block"

-- only where nvim ships a parser
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("UserTreesitter", {}),
    callback = function(ev)
        local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
        if lang and #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) > 0 then
            vim.treesitter.start(ev.buf, lang)
        end
    end,
})
