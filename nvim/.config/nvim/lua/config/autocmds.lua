-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Save the session (open files, splits) as you work, not only on a clean exit:
-- a shutdown kills nvim without one, and tmux-resurrect restores from this.
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusLost" }, {
  group = vim.api.nvim_create_augroup("persistence_autosave", { clear = true }),
  callback = function()
    local ok, persistence = pcall(require, "persistence")
    if not ok or not persistence.active() then
      return
    end
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[b].buflisted and vim.bo[b].buftype == "" and vim.api.nvim_buf_get_name(b) ~= "" then
        pcall(persistence.save)
        return
      end
    end
  end,
})
