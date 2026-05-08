return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      require "configs.lspconfig"
    end,
  },

  { import = "nvchad.blink.lazyspec" },

  {
  	"nvim-treesitter/nvim-treesitter",
  	lazy = false,
  	build = ":TSUpdate",
  	config = function()
  		local treesitter = require "nvim-treesitter"

  		treesitter.setup {
  			install_dir = vim.fn.stdpath "data" .. "/site",
  		}

  		vim.api.nvim_create_autocmd("FileType", {
  			pattern = { "c", "cpp", "css", "html", "lua", "vim", "vimdoc" },
  			callback = function(args)
  				pcall(vim.treesitter.start, args.buf)
  			end,
  		})
  	end,
  },
}
