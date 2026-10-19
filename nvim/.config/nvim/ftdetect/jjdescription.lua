vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = { '*.jjdescription' },
  callback = function()
    vim.bo.filetype = 'jjdescription'
  end,
})
