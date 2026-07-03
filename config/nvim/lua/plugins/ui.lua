-- UI plugins: statusline, indent guides, rainbow delimiters.
return {
  -- Statusline (replaces vim-airline). Uses the active colorscheme's palette
  -- and the Nerd Font that ghostty is configured with.
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        theme = "auto",
        globalstatus = true,
      },
    },
  },

  -- Indent guides (replaces yggdroot/indentline).
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },

  -- Rainbow parentheses (replaces junegunn/rainbow_parentheses.vim). Backed by
  -- Treesitter, so it understands the language rather than matching brackets.
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("rainbow-delimiters.setup").setup({})
    end,
  },
}
