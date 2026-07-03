-- Treesitter parser management.
--
-- Neovim 0.12 ships the treesitter engine and auto-starts highlighting once a
-- parser exists, but it has no way to install parsers, and the old
-- nvim-treesitter plugin was archived in 2026. tree-sitter-manager.nvim fills
-- that gap: it clones + compiles parsers (via the `tree-sitter` CLI and a C
-- compiler) and installs their highlight queries; core does the highlighting.
--
-- Commands: :TSInstall / :TSUpdate / :TSUninstall, and :TSManager for a TUI.
-- Note: this manages parsers + highlighting only, not treesitter indentation.
return {
  "romus204/tree-sitter-manager.nvim",
  event = { "BufReadPost", "BufNewFile" },
  -- Also load on these so they work from a fresh session with no file open.
  cmd = { "TSInstall", "TSUpdate", "TSUninstall", "TSManager" },
  config = function()
    require("tree-sitter-manager").setup({
      -- lua/vim/markdown/vimdoc ship with Neovim, so only list the extras.
      ensure_installed = {
        "bash",
        "go",
        "javascript",
        "json",
        "typescript",
        "yaml",
      },
      auto_install = true, -- grab a parser the first time a filetype is opened
      highlight = true,
    })
  end,
}
