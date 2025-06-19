vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = { '/*/new-commit', '/*/differential-edit-revision-info' },
  callback = function()
    vim.bo.filetype = 'arcanistdiff'
  end,
})
