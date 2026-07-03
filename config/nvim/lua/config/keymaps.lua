-- Global keymaps. LSP- and plugin-specific maps live with their plugin specs
-- (see lua/plugins/lsp.lua and lua/plugins/telescope.lua).
local map = vim.keymap.set

-- Diagnostics navigation (was `[g` / `]g` under coc.nvim). vim.diagnostic.jump
-- is the current API; fall back to the older goto_* on pre-0.11 Neovim.
local function diag_jump(count)
  if vim.diagnostic.jump then
    vim.diagnostic.jump({ count = count, float = true })
  elseif count < 0 then
    vim.diagnostic.goto_prev({ float = true })
  else
    vim.diagnostic.goto_next({ float = true })
  end
end

map("n", "[g", function() diag_jump(-1) end, { desc = "Previous diagnostic" })
map("n", "]g", function() diag_jump(1) end, { desc = "Next diagnostic" })
