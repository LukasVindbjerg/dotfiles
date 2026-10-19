-- Catppuccin Mocha everywhere (LazyVim ships the catppuccin plugin; this selects it)
return {
  { "catppuccin/nvim", name = "catppuccin", opts = { flavour = "mocha" } },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}
