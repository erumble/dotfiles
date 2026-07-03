-- Fuzzy finder (replaces the CocList pickers). `<space>` mappings mirror the
-- old bindings: a=diagnostics, c=commands, o=document symbols, s=workspace
-- symbols; plus the usual find/grep/buffers. Live grep is backed by ripgrep.
return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = "Telescope",
  keys = {
    { "<space>f", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<space>g", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
    { "<space>b", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
    { "<space>a", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
    { "<space>c", "<cmd>Telescope commands<cr>", desc = "Commands" },
    { "<space>o", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
    { "<space>s", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace symbols" },
  },
  opts = {},
}
