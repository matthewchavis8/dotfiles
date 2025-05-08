
-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
local nvlsp = require "nvchad.configs.lspconfig"

local servers = { "html", "cssls" }

-- use default config for these
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

-- customized clangd with real-time diagnostics
lspconfig.clangd.setup {
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
}

