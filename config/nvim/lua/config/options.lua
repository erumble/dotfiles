-- Editor options (ported from the old init.vim).
local opt = vim.opt

-- nvim-tree owns file browsing, so disable the built-in netrw early.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- This config is pure Lua and uses no remote-host plugins, so disable the
-- optional Node/Perl/Python/Ruby providers (silences their health warnings).
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- Files / backups: some language servers dislike backup files (coc.nvim #649).
opt.backup = false
opt.writebackup = false

-- Responsiveness: shorter updatetime -> snappier CursorHold and diagnostics.
opt.updatetime = 300
opt.shortmess:append("c") -- don't show ins-completion-menu messages

-- UI
opt.number = true       -- show line numbers
opt.signcolumn = "yes"  -- always show the sign column so text doesn't shift
opt.mouse = "a"         -- enable mouse support
opt.laststatus = 2      -- always show a status line (for lualine)

-- Indentation: 2-space, expand tabs, autoindent.
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.autoindent = true

-- Completion behaviour expected by nvim-cmp.
opt.completeopt = { "menu", "menuone", "noselect" }
