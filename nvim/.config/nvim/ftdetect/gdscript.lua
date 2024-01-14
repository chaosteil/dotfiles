vim.api.nvim_create_autocmd({'BufNewFile','BufRead'}, {
  pattern = {"*.gd", "*.gdscript"},
  callback = function() vim.bo.filetype='gdscript' end,
})
