-- init.lua
--
-- Neovim configuration, in Lua.
--
-- Plugins are managed by lazy.nvim, which self-bootstraps below on first launch
-- (no manual install step). Language support comes from Neovim's built-in LSP
-- client plus mason.nvim, which installs the servers on demand; run `:Mason` to
-- manage them and `:Lazy` to manage plugins.
--
-- Layout:
--   lua/config/options.lua   editor options
--   lua/config/keymaps.lua   global keymaps (LSP/plugin maps live with their specs)
--   lua/plugins/*.lua        one file per plugin group; each returns a lazy spec

-- Load core settings before plugins so specs can rely on them.
require("config.options")
require("config.keymaps")

-- Bootstrap lazy.nvim -> https://github.com/folke/lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load every spec module under lua/plugins/.
require("lazy").setup("plugins", {
  change_detection = { notify = false },
  -- No plugin here needs luarocks; disabling it drops a spurious health error.
  rocks = { enabled = false },
})
