-- Distraction-free writing (replaces junegunn/goyo.vim + junegunn/limelight.vim).
-- zen-mode centres the buffer; twilight dims everything but the current block.
return {
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    keys = { { "<space>z", "<cmd>ZenMode<cr>", desc = "Zen mode" } },
    opts = {
      plugins = {
        twilight = { enabled = true }, -- turn twilight on with zen mode
      },
    },
  },
  {
    "folke/twilight.nvim",
    cmd = { "Twilight", "TwilightEnable" },
    opts = {},
  },
}
