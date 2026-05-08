-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, args.buf) then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end,
})

local nvlsp = require "nvchad.configs.lspconfig"

local clangd_root_markers = {
  ".clangd",
  ".clang-tidy",
  ".clang-format",
  "compile_commands.json",
  "compile_flags.txt",
  "configure.ac",
  ".git",
}

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
  root_dir = function(bufnr, on_dir)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(filename, clangd_root_markers)

    if root then
      on_dir(root)
      return
    end

    -- Keep clangd useful for quick standalone C/C++ files on a fresh VM.
    on_dir(vim.fs.dirname(filename) or vim.fn.getcwd())
  end,
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
