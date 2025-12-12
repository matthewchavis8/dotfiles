-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local nvlsp = require "nvchad.configs.lspconfig"

local servers = { "html", "cssls" }

-- use default config for these, via new API
for _, server in ipairs(servers) do
  vim.lsp.config(server, {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  })

  -- enable the server so it actually attaches to buffers
  vim.lsp.enable(server)
end

-- customized clangd with real-time diagnostics
vim.lsp.config("clangd", {
  on_attach = function(client, bufnr)
    nvlsp.on_attach(client, bufnr)

    -- Trigger diagnostics on insert leave or text change
    vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
      buffer = bufnr,
      callback = function()
        vim.diagnostic.setloclist({ open = false })
      end,
    })
  end,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
})

vim.lsp.enable("clangd")

