-- the servers come from dev.nix

vim.lsp.config("lua_ls", {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", ".git" },
    settings = {
        Lua = {
            diagnostics = { globals = { "vim" } },
            -- fallback, .editorconfig wins
            format = {
                defaultConfig = {
                    indent_style = "space",
                    indent_size = "4",
                    align_continuous_assign_statement = "false",
                },
            },
        },
    },
})

vim.lsp.config("clangd", {
    cmd = { "clangd", "--background-index" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
    root_markers = { "compile_commands.json", ".clangd", ".git" },
})

vim.lsp.config("texlab", {
    cmd = { "texlab" },
    filetypes = { "tex", "plaintex", "bib" },
    root_markers = { ".latexmkrc", ".git" },
})

vim.lsp.config("html", {
    cmd = { "vscode-html-language-server", "--stdio" },
    filetypes = { "html" },
    root_markers = { "package.json", ".git" },
    init_options = {
        provideFormatter = true,
        embeddedLanguages = { css = true, javascript = true },
        configurationSection = { "html", "css", "javascript" },
    },
})

vim.lsp.config("cssls", {
    cmd = { "vscode-css-language-server", "--stdio" },
    filetypes = { "css", "scss", "less" },
    root_markers = { "package.json", ".git" },
    settings = {
        css = { validate = true },
        scss = { validate = true },
        less = { validate = true },
    },
})

vim.lsp.config("jsonls", {
    cmd = { "vscode-json-language-server", "--stdio" },
    filetypes = { "json", "jsonc" },
    root_markers = { "package.json", ".git" },
    init_options = { provideFormatter = true },
})

vim.lsp.config("ts_ls", {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})

vim.lsp.config("bashls", {
    cmd = { "bash-language-server", "start" },
    filetypes = { "sh", "bash" },
    root_markers = { ".git" },
})

vim.lsp.config("nixd", {
    cmd = { "nixd" },
    filetypes = { "nix" },
    root_markers = { ".git" },
    -- no formatting: nixfmt puts every list item on its own line
    on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end,
    settings = {
        nixd = {
            options = {
                nixos = {
                    expr = "(import <nixpkgs/nixos> { configuration = ~/.config/.dotfiles/nixos/configuration.nix; }).options",
                },
            },
        },
    },
})

-- only servers on PATH, so a pending rebuild doesn't throw on open
local enabled = {}
for _, name in ipairs({ "lua_ls", "clangd", "texlab", "html", "cssls", "jsonls", "ts_ls", "bashls", "nixd" }) do
    if vim.fn.executable(vim.lsp.config[name].cmd[1]) == 1 then
        table.insert(enabled, name)
    end
end
vim.lsp.enable(enabled)

vim.o.completeopt = "menu,menuone,popup,noselect,fuzzy"
vim.opt.shortmess:append("c")

-- the menu first, then the snippet placeholders (nvim's own <Tab> does those,
-- and mapping over it would lose them), then the key itself
local function pum(key, direction, fallback)
    return function()
        if vim.fn.pumvisible() == 1 then
            return key
        elseif vim.snippet.active({ direction = direction }) then
            return "<Cmd>lua vim.snippet.jump(" .. direction .. ")<CR>"
        end
        return fallback
    end
end

vim.keymap.set("i", "<Tab>", pum("<C-n>", 1, "<Tab>"), { expr = true })
vim.keymap.set("i", "<S-Tab>", pum("<C-p>", -1, "<S-Tab>"), { expr = true })
vim.keymap.set("i", "<Cr>", function()
    return vim.fn.complete_info({ "selected" }).selected ~= -1 and "<C-y>" or "<Cr>"
end, { expr = true })
vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get)

local words = vim.split("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_", "")

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLsp", {}),
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then
            return
        end

        if client:supports_method("textDocument/completion") then
            -- servers only trigger on punctuation. once per client: LspAttach
            -- fires again for every buffer
            local provider = client.server_capabilities.completionProvider
            if provider and not provider.ro15rend_words then
                provider.triggerCharacters = vim.list_extend(provider.triggerCharacters or {}, words)
                provider.ro15rend_words = true
            end

            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
        end
    end,
})

-- two formatters attached: refuse rather than guess
local function format(buf)
    local clients = vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" })
    if #clients == 1 then
        vim.lsp.buf.format({ bufnr = buf, id = clients[1].id, timeout_ms = 1000 })
    elseif #clients > 1 then
        vim.notify("Multiple LSP formatters attached; select one before formatting", vim.log.levels.WARN)
    end
end

vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("UserLspFormat", { clear = true }),
    callback = function(ev)
        if vim.b[ev.buf].format_on_save == true then format(ev.buf) end
    end,
})

vim.keymap.set("n", "<leader>lt", function()
    vim.b.format_on_save = vim.b.format_on_save ~= true
    vim.notify("Format on save: " .. (vim.b.format_on_save and "on" or "off") .. " (this buffer)")
end, { desc = "toggle format on save (buffer)" })

vim.keymap.set("n", "<leader>lf", function() format(0) end, { desc = "format file (LSP)" })

vim.diagnostic.config({
    virtual_text = false,
    float = { border = "rounded" },
})

vim.api.nvim_create_autocmd("CursorHold", {
    group = vim.api.nvim_create_augroup("UserDiagnosticFloat", {}),
    callback = function()
        -- a float is already up (K hover, signature): opening this one closes it
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.api.nvim_win_get_config(win).relative ~= "" then
                return
            end
        end
        vim.diagnostic.open_float(nil, { focus = false })
    end,
})
