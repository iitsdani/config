function GoOrganizeImports(wait_ms)
    local clients = vim.lsp.get_clients({ bufnr = 0, name = "gopls" })
    if #clients == 0 then return end
    local enc = clients[1].offset_encoding or "utf-16"

    local params = vim.lsp.util.make_range_params(0, enc)
    params.context = { only = { "source.organizeImports" } }

    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, wait_ms)
    for _, res in pairs(result or {}) do
        for _, r in pairs(res.result or {}) do
            if r.edit then
                vim.lsp.util.apply_workspace_edit(r.edit, enc)
            end
        end
    end
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "go",
    callback = function()
        vim.bo.tabstop = 4
        vim.bo.shiftwidth = 4
        vim.bo.softtabstop = 4
        vim.bo.expandtab = false
        vim.bo.omnifunc = "v:lua.vim.lsp.omnifunc"
        vim.treesitter.query.disable("go", "indents")
    end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.go",
    callback = function() GoOrganizeImports(1000) end,
})
