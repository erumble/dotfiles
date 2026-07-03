-- Language support (replaces coc.nvim): Neovim's built-in LSP client + nvim-cmp
-- for completion, with mason installing the servers. Requires Neovim 0.11+ for
-- the vim.lsp.config / vim.lsp.enable API.
return {
  -- Completion engine.
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      local function has_words_before()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        if col == 0 then
          return false
        end
        return vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        -- Tab/Shift-Tab to cycle, <C-Space> to trigger, <CR> to confirm --
        -- mirrors the old coc.nvim keybindings.
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer" },
        }),
      })
    end,
  },

  -- LSP: mason installs the servers, and Neovim's native client enables them.
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "williamboman/mason.nvim", opts = {} },
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      -- Buffer-local keymaps, set when a server attaches. LSP navigation uses
      -- Telescope so results land in a picker (was `gd`/`gy`/`gi`/`gr` in coc).
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local telescope = require("telescope.builtin")
          local function map(mode, keys, fn, desc)
            vim.keymap.set(mode, keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("n", "gd", telescope.lsp_definitions, "Goto definition")
          map("n", "gy", telescope.lsp_type_definitions, "Goto type definition")
          map("n", "gi", telescope.lsp_implementations, "Goto implementation")
          map("n", "gr", telescope.lsp_references, "References")
          map("n", "K", vim.lsp.buf.hover, "Hover documentation")
          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map({ "n", "x" }, "<leader>a", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>ac", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>qf", vim.lsp.buf.code_action, "Quick fix")
          map("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, "Format buffer")
        end,
      })

      -- `:Format` to format the current buffer (was a coc command).
      vim.api.nvim_create_user_command("Format", function()
        vim.lsp.buf.format({ async = true })
      end, {})

      -- Advertise nvim-cmp's completion capabilities to every server.
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      vim.lsp.config("*", { capabilities = capabilities })

      -- Install and enable the servers. Add more here (and they'll be installed
      -- on next launch); manage them interactively with `:Mason`.
      local servers = { "lua_ls", "ts_ls", "jsonls", "bashls", "gopls" }
      require("mason-lspconfig").setup({ ensure_installed = servers })
      vim.lsp.enable(servers)
    end,
  },
}
