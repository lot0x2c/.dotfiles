-- update: :lua vim.pack.update(), :w to accept, commit nvim-pack-lock.json

local ok, err = pcall(vim.pack.add, {
    "https://github.com/ellisonleao/gruvbox.nvim",
    "https://github.com/stevearc/oil.nvim",
})
if not ok then
    -- offline first start
    vim.api.nvim_echo({ { "could not install plugins:\n" .. tostring(err), "ErrorMsg" } }, true, {})
    return
end

require("gruvbox").setup({
    undercurl = false,
    underline = false,
    italic = {
        strings = false,
        emphasis = false,
        comments = false,
        folds = false,
    },
    invert_selection = true,
    invert_tabline = true,
    contrast = "hard",
    -- bubblegum accents
    palette_overrides = {
        bright_red = "#ed286f",
        bright_green = "#08c7a4",
        bright_blue = "#00a2b8",
        bright_purple = "#f030a8",
        bright_aqua = "#00b9a3",
    },
    transparent_mode = true,
})
vim.cmd("colorscheme gruvbox")

require("oil").setup({
    columns = {},
    view_options = { show_hidden = true },
})
vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "open parent directory" })
