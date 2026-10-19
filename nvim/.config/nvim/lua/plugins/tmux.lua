-- Ctrl+h/j/k/l moves between nvim splits and tmux panes as one.
-- The tmux half is the vim-tmux-navigator plugin in ~/.config/tmux/tmux.conf.
return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight", "TmuxNavigatePrevious" },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to left split/pane" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to lower split/pane" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to upper split/pane" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right split/pane" },
      { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Go to previous split/pane" },
    },
  },
  -- The explorer is a floating window, so "move left" from it lands back in the
  -- editor instead of reaching tmux. It is always nvim's leftmost window, so
  -- Ctrl+h there goes straight to the tmux pane on the left.
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            actions = {
              tmux_left = function()
                if vim.env.TMUX then
                  vim.fn.system({ "tmux", "select-pane", "-t", vim.env.TMUX_PANE, "-L" })
                end
              end,
            },
            win = { list = { keys = { ["<c-h>"] = "tmux_left" } } },
          },
        },
      },
    },
  },
}
