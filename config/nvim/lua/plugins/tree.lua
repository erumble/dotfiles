-- File explorer (replaces preservim/nerdtree + Xuyuanp/nerdtree-git-plugin).
return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
  keys = {
    { "<C-n>", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
  },
  -- Open the tree on startup when nvim is launched with no file arguments,
  -- mirroring the old NERDTree autocmd. `init` runs before the plugin loads.
  init = function()
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function(data)
        local no_args = vim.fn.argc() == 0
        local real_file = vim.fn.filereadable(data.file) == 1
        local no_name_buffer = data.file == "" and vim.bo[data.buf].buftype == ""
        if no_args and not real_file and no_name_buffer then
          require("nvim-tree.api").tree.open()
        end
      end,
    })
  end,
  config = function()
    require("nvim-tree").setup({
      git = { enable = true }, -- replaces nerdtree-git-plugin
    })

    -- Quit Neovim if the tree is the last remaining window (old NERDTree behaviour).
    vim.api.nvim_create_autocmd("BufEnter", {
      nested = true,
      callback = function()
        local api = require("nvim-tree.api")
        if #vim.api.nvim_list_wins() == 1 and api.tree.is_tree_buf() then
          vim.cmd("quit")
        end
      end,
    })
  end,
}
