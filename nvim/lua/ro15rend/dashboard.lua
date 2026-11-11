vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        if vim.fn.argc() > 0 or vim.api.nvim_buf_get_name(0) ~= "" or vim.fn.line("$") ~= 1
            or vim.fn.getline(1) ~= "" then return end
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(buf)
        vim.bo[buf].bufhidden = "wipe"
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "", "  ><>  ro15rend", "",
            "  n  new", "  f  find", "  e  explore", "  q  quit" })
        vim.bo[buf].modifiable = false
        vim.opt_local.number, vim.opt_local.relativenumber, vim.opt_local.signcolumn = false, false, "no"
        local explore = vim.fn.exists(":Oil") == 2 and "<cmd>Oil<cr>" or "<cmd>Explore<cr>"
        local keys = { n = "<cmd>enew<cr>", f = ":find ", e = explore, q = "<cmd>quit<cr>" }
        for key, action in pairs(keys) do
            -- not silent: that hides the :find prompt until a key is typed
            vim.keymap.set("n", key, action, { buffer = buf, nowait = true })
        end
    end,
})
