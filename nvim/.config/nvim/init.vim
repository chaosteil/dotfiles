" Chaosteils Neovim init.vim
set nocompatible

" Reenable checking of filetypes and filetype indent plugins
call plug#begin('~/.config/nvim/bundle')

Plug 'Raimondi/delimitMate' " Inserts matching parens, quote
Plug 'elzr/vim-json' " Better json highlighting
Plug 'embear/vim-localvimrc' " Allows to have a local vimrc per folder
Plug 'fatih/vim-go' " Better Go support
Plug 'fatih/vim-hclfmt' " Format hashicorp configs
Plug 'tami5/lspsaga.nvim', {'branch': 'main'} " neovim LSP nicer UI
Plug 'weilbith/nvim-code-action-menu' " Nice code action menu
Plug 'kosayoda/nvim-lightbulb' " Lightbulb in gutter
Plug 'hrsh7th/nvim-cmp' " Autocompletion for nvim
  Plug 'hrsh7th/cmp-nvim-lsp'
  Plug 'hrsh7th/cmp-buffer'
  Plug 'hrsh7th/cmp-path'
  Plug 'hrsh7th/cmp-cmdline'
  Plug 'hrsh7th/nvim-cmp'
  Plug 'hrsh7th/cmp-vsnip'
  Plug 'hrsh7th/vim-vsnip' " Snippets
  Plug 'hrsh7th/vim-vsnip-integ' " Support for lsp
Plug 'kyazdani42/nvim-web-devicons' " Extra icons
Plug 'folke/trouble.nvim' " Pretty diagnostics
Plug 'majutsushi/tagbar' " Tags on the right
Plug 'mbbill/undotree', { 'on': 'UndotreeToggle' } " Killer feature for undo
Plug 'mhinz/vim-signify' " Git marks next to line numbers
Plug 'mhinz/vim-startify' " Better start screen
Plug 'myusuf3/numbers.vim' " Alters between relative and absolute line numbers in normal/insert mode
Plug 'neomake/neomake' " Syntax checking
Plug 'neovim/nvim-lspconfig' " Default LSP configuration
Plug 'nvim-lua/lsp_extensions.nvim' " Additional LSP extension callbacks
Plug 'nvim-lua/plenary.nvim' " Helper functions for nvim lua
Plug 'nvim-lua/popup.nvim' " Vim popup API port in neovim
Plug 'nvim-telescope/telescope.nvim' " Fuzzy finder
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'} " AST-based syntax highlighting
Plug 'nvim-treesitter/playground' " Extra tools for tree sitter
Plug 'onsails/lspkind-nvim' " add pictograms to lsp
Plug 'plasticboy/vim-markdown' " Better syntax highlighting for markdown
Plug 'rafamadriz/friendly-snippets', {'branch':'main'}
Plug 'ray-x/lsp_signature.nvim' " LSP signature help
Plug 'rust-lang/rust.vim' " Vim configuration for Rust
Plug 'simrat39/rust-tools.nvim' " Additional rust tooling for lsp
Plug 'sainnhe/sonokai' " Colorscheme based on monokai pro
Plug 'numToStr/Comment.nvim' " Autocommenting
Plug 'sebdah/vim-delve' " Delve debugging for Go
Plug 'sheerun/vim-polyglot' " More syntaxes
Plug 'solarnz/arcanist.vim' " Arcanist filetypes
Plug 'tomasr/molokai' " Molokai color scheme
Plug 'tpope/vim-fugitive' " Git functions
Plug 'tpope/vim-speeddating' " Can increase dates with c-a and c-x
Plug 'tpope/vim-surround' " Adds surround operator
Plug 'tpope/vim-vinegar' " Better netrw with -
Plug 'uarun/vim-protobuf' " protobuf colors
Plug 'nvim-lualine/lualine.nvim' " line at the bottom
Plug 'vim-scripts/a.vim' " :A for switching between src and header files
Plug 'kyazdani42/nvim-tree.lua' " File tree
Plug 'mfussenegger/nvim-dap' " DAP support
Plug 'stevearc/dressing.nvim' " UI dressing
Plug 'rcarriga/nvim-notify' " Notification dressing

call plug#end()

" Colorscheme {{{
" Sets up the specific font and color for individual system settings
syntax on " Enable syntax highlighting
let g:sonokai_style = 'andromeda'
let g:sonokai_transparent_background = 1
let g:sonokai_menu_selection_background = 'green'
let g:sonokai_diagnostic_virtual_text = 'colored'
let g:sonokai_enable_italic = 1
colorscheme sonokai " Set up my currently favored colorscheme
set termguicolors
" Disable terminal background for transparency goodness
hi Normal guibg=none ctermbg=none
" }}}

" Nice title! {{{
set title
set titlestring=
set titlestring+=%f " file name
set titlestring+=%h%m%r%w " flags
set titlestring+=\ -\ nvim
" }}}

" Make command line completion nicer
set wildmenu

" Let files reopen on the same line if opened again
autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
\| exe "normal g'\"" | endif

" Sudo fix {{{
" Allows to write a file when forgot to do sudo
cmap w!! %!sudo tee > /dev/null %
" }}}

" Backups {{{
set nobackup " disable backups
set noswapfile " disable swaps

 "Persistent undo, I cannot overstate how much I love this
if has("persistent_undo")
  set undofile
  set undodir=~/.config/nvim/undo " undo files
  set undolevels=1000
  set undoreload=10000
endif
 "}}}

set lazyredraw " Do not show macro expansion visually
set showtabline=1 " Show tabs on top only if available
set laststatus=2 " Status bar always visible

set clipboard=unnamed " On windows, use the unnamed register as system
set fileformats=unix,mac,dos

set encoding=utf-8
set nowrap " No wrapping on the right side
set nolinebreak "No linebreak
set tabstop=4 " Tabstop size
set cursorline " Highlight screen line where the cursor is
set shiftwidth=2 " Number of spaces for each step of indent
set backspace=2 " Backspacing with all possible indents
set expandtab " Expand tab to spaces by default
set smartindent " Smart indenting when starting a new line
set autoindent " Copy indent from current line when starting a new line
set scrolloff=5 " Keeps the cursor 5 lines from the top or bottom of the screen
set ttimeoutlen=50 " To not pause after leaving insert mode
set signcolumn=yes " Always enable sign column for git or LSP info
set nohidden " Never make an unsaved buffer disappear off-screen

" More comfortable search
set ignorecase " Ignores the case of the searched item
set smartcase " If contains uppercase letter, make it a case-sensitive search

" Using these two together will use vim hybrid line number mode
set relativenumber " Relative number lines
set number " Show line in front of each line

set showcmd " Show command in the last line of the screen
set ruler " Show line, column, etc. at the bottom

set autoread " Enable automatic refresh of files if they have been changed
au FocusGained * :checktime " Force checking of file status on focus

set showmatch " Show matching braces

set mouse=a " Mouse enabled for all modes

" We don't want any interruptions
set noerrorbells
set novisualbell

" Highlight search
set hlsearch
" Space to turn off highlighting
nnoremap <silent> <space> :nohlsearch<Bar>:echo<CR>

" Enable incremental commands for more visual feedback
set inccommand=nosplit

" Empty space automatic highlighting
highlight default link EndOfLineSpace ErrorMsg
match EndOfLineSpace /\s\+$/
autocmd InsertEnter * hi link EndOfLineSpace Normal
autocmd InsertLeave * hi link EndOfLineSpace ErrorMsg

" Highlight VCS conflict markers
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

" Because I'm too lazy to type this out everytime, :FormatJSON
com! FormatJSON %!python3 -mjson.tool

" Custom Colorcolumn settings
hi colorcolumn ctermbg=red ctermfg=white guibg=#592929
set colorcolumn=81 " Make a colorcolumn for the 81st symbol
set textwidth=80 " Also automatically split at 80

autocmd VimEnter * autocmd WinEnter * let w:created=1
autocmd VimEnter * let w:created=1

" Some useful bindings for various panes {{{
nnoremap <F2> :NvimTreeToggle<CR>
nnoremap <F3> :TagbarToggle<CR>
nnoremap <F4> :UndotreeToggle<CR>
" }}}

" Comment {{{
lua require('Comment').setup{}
nmap <silent> <C-_> gcc
vmap <silent> <C-_> gc
" }}}

" Some completion options {{{
set completeopt=menu,menuone,noselect
set pumheight=15 " Max items in the insert mode completion
" }}}

" Undotree settings
let g:undotree_WindowLayout=3

" Changed split behavior to open splits by default below and on the right
set splitbelow
set splitright

" Stop it, hash key.
inoremap # X<BS>#

" List mapping {{{
" Show special symbols instead of nothing in special situations
if has("unix")
  set list
  set listchars=tab:▸\ ,extends:❯,precedes:❮
  set fillchars+=vert:│
endif
" }}}

" Substitute {{{
nnoremap <leader>s :%s//<left>
set gdefault  " No more g in substitute operations
" }}}

" Disable annoying keys
nnoremap <F1> <nop>
nnoremap Q <nop>

" Hexmode
nnoremap <C-H> :Hexmode<CR>
" ex command for toggling hex mode
command -bar Hexmode call ToggleHex()

" helper function to toggle hex mode - forgot where I got this from, but super
" useful
function ToggleHex()
  " hex mode should be considered a read-only operation
  " save values for modified and read-only for restoration later,
  " and clear the read-only flag for now
  let l:modified=&mod
  let l:oldreadonly=&readonly
  let &readonly=0
  let l:oldmodifiable=&modifiable
  let &modifiable=1
  if !exists("b:editHex") || !b:editHex
    " save old options
    let b:oldft=&ft
    let b:oldbin=&bin
    " set new options
    setlocal binary " make sure it overrides any textwidth, etc.
    let &ft="xxd"
    " set status
    let b:editHex=1
    " switch to hex editor
    %!xxd
  else
    " restore old options
    let &ft=b:oldft
    if !b:oldbin
      setlocal nobinary
    endif
    " set status
    let b:editHex=0
    " return to normal editing
    %!xxd -r
  endif
  " restore values for modified and read only state
  let &mod=l:modified
  let &readonly=l:oldreadonly
  let &modifiable=l:oldmodifiable
endfunction

" Folding is by default not okay
set nofoldenable
"set foldlevel=10
"set foldmethod=syntax

" Startify settings
let g:startify_change_to_dir = 0  " I define my own dir with .lvimrc if I need it

" Fuzzy file finder with ctrl+P
nnoremap <C-P> <cmd>Telescope find_files<cr>

" Nvim terminal settings
tnoremap <Esc> <C-\><C-n> " Enter normal mode on escape

" Local vimrc settings
let g:localvimrc_ask=0

" Automagically run gopls with gofmumpt on save
let g:go_fmt_command = "gopls"
let g:go_gopls_gofumpt=1
let g:go_def_mapping_enabled = 0 " Disable so LSP can take over

" Better highlighting
let g:go_highlight_array_whitespace_error = 1
let g:go_highlight_chan_whitespace_error = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_space_tab_error = 1
let g:go_highlight_trailing_whitespace_error = 1
let g:go_highlight_operators = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_arguments = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_methods = 1
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_highlight_generate_tags = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_variable_declarations = 1

" Run lint and vet on save
let g:go_metalinter_autosave = 1
let g:go_metalinter_autosave_enabled = ['all']
let g:go_jump_to_error = 0

let g:rustfmt_autosave = 1

" Show highlight when yanking
au TextYankPost * silent! lua vim.highlight.on_yank {higroup="IncSearch", timeout=150, on_visual=false}

"" -------------------- LSP ---------------------------------
lua << EOF

-- Trouble
require("trouble").setup{}
vim.api.nvim_set_keymap("n", "<leader>xx", "<cmd>Trouble<cr>",
  {silent = true, noremap = true}
)
vim.api.nvim_set_keymap("n", "<leader>xq", "<cmd>Trouble quickfix<cr>",
  {silent = true, noremap = true}
)
-- Quickfix for workspace diagnostics
vim.api.nvim_set_keymap("n", "<leader>q", "<cmd>Trouble workspace_diagnostics<cr>", 
  {silent = true, noremap = true}
)

-- Lualine
require'lualine'.setup{
  options = {
    theme = 'sonokai'
  },
  sections = {
    lualine_z = {'%3l/%L:%3c'}
  },
  extensions = {
    'fzf', 'quickfix', 'fugitive',
  }
}

local tree_cb = require'nvim-tree.config'.nvim_tree_callback
require'nvim-tree'.setup {
   diagnostics = {
    enable = true,
  },
  view = {
    mappings = {
      list = {
        { key = "<C-s>", cb = tree_cb("system_open") },
        { key = "s", cb = tree_cb("split") },
        { key = "v", cb = tree_cb("vsplit") },
      }
    }
  }
}

require('dressing').setup{}

require('notify').setup{
  background_colour = "#000000"
}
vim.notify = require('notify')

-- LSP
local nvim_lsp = require('lspconfig')
require'lspsaga'.setup{}

vim.cmd [[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()]]

-- TODO: remove once nvim-code-action-menu is updated
local function get_line(uri, row)
  local uv = vim.loop
  -- load the buffer if this is not a file uri
  -- Custom language server protocol extensions can result in servers sending URIs with custom schemes. Plugins are able to load these via `BufReadCmd` autocmds.
  if uri:sub(1, 4) ~= "file" then
    local bufnr = vim.uri_to_bufnr(uri)
    vim.fn.bufload(bufnr)
    return (vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false) or { "" })[1]
  end

  local filename = vim.uri_to_fname(uri)

  -- use loaded buffers if available
  if vim.fn.bufloaded(filename) == 1 then
    local bufnr = vim.fn.bufnr(filename, false)
    return (vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false) or { "" })[1]
  end

  local fd = uv.fs_open(filename, "r", 438)
  -- TODO: what should we do in this case?
  if not fd then return "" end
  local stat = uv.fs_fstat(fd)
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)

  local lnum = 0
  for line in string.gmatch(data, "([^\n]*)\n?") do
    if lnum == row then return line end
    lnum = lnum + 1
  end
  return ""
end
vim.lsp.util.get_line = get_line

-- Use an on_attach function to only map the following keys 
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  require "lsp_signature".on_attach()

  --Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gh', '<Cmd>lua require"lspsaga.provider".lsp_finder()<CR>', opts)
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', '<C-]>', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua require("lspsaga.hover").render_hover_doc()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua require("lspsaga.signaturehelp").signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua require("lspsaga.rename").rename()<CR>', opts)
  buf_set_keymap('n', '<leader><CR>', '<cmd>CodeActionMenu<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
-- Update cmp
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    'documentation',
    'detail',
    'additionalTextEdits',
  }
}

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = {
  "pyright",
  "tsserver",
  "zls",
}

for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup { on_attach = on_attach, capabilities = capabilities }
end

local rust_tool_opts = {
    tools = {
      autoSetHints = true,
      hover_with_actions = true,
      runnables = {
        use_telescope = true,
      },
        inlay_hints = {
            show_parameter_hints = true,
            parameter_hints_prefix = " ",
            other_hints_prefix  = " ",
        },
    },
    server = {on_attach = on_attach}, -- rust-analyzer options
}

require('rust-tools').setup(rust_tool_opts)

-- Attach gopls to any running gopls if it exists
nvim_lsp.gopls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = {'gopls', '--remote=auto'},
  gopls = {
    analyses = {
      unusedparams = true,
      nilness = true,
      unusedwrite = true,
    },
    staticcheck = true,
  }
}

-- Set up diagnosticls to show linter help inline for these tools
nvim_lsp.diagnosticls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = {"diagnostic-languageserver", "--stdio"},
  filetypes = {
    "sh",
    "markdown",
    },
  init_options = {
    linters = {
      shellcheck = {
        command = "shellcheck",
        debounce = 100,
        args = {"--format", "json", "-"},
        sourceName = "shellcheck",
        parseJson = {
          line = "line",
          column = "column",
        endLine = "endLine",
      endColumn = "endColumn",
      message = "${message} [${code}]",
      security = "level"
      },
    securities = {
      error = "error",
      warning = "warning",
      info = "info",
      style = "hint"
      }
    },
    markdownlint = {
      command = "markdownlint",
      isStderr = true,
      debounce = 100,
      args = {"--stdin"},
      offsetLine = 0,
      offsetColumn = 0,
      sourceName = "markdownlint",
      formatLines = 1,
      formatPattern = {
        "^.*?:\\s?(\\d+)(:(\\d+)?)?\\s(MD\\d{3}\\/[A-Za-z0-9-/]+)\\s(.*)$",
        {
            line = 1,
            column = 3,
            message = {4}
        }
        }
      }
    },
    filetypes = {
      sh = "shellcheck",
      markdown = "markdownlint"
    }
  }
}

-- Cmp autocompletion configuration.
local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local feedkey = function(key, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

local cmp = require('cmp')
cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
    ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
    ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
    ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
    ['<C-e>'] = cmp.mapping({
      i = cmp.mapping.abort(),
      c = cmp.mapping.close(),
    }),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif vim.fn["vsnip#available"](1) == 1 then
        feedkey("<Plug>(vsnip-expand-or-jump)", "")
      elseif has_words_before() then
        cmp.complete()
      else
        fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
      end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_prev_item()
      elseif vim.fn["vsnip#jumpable"](-1) == 1 then
        feedkey("<Plug>(vsnip-jump-prev)", "")
      end
    end, { "i", "s" }),
    },
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'buffer' },
      { name = 'vsnip' },
    })
})

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})

-- Treesitter configuration
require'nvim-treesitter.configs'.setup {
  ensure_installed = "all",  -- All maintained languages
  ignore_install = {"phpdoc"},  -- Gave some problems when launchin
  highlight = {
    enable = true
  },
}

require'lspkind'.init({
  mode = 'symbol',
})
vim.diagnostic.config({
    underline = true,
    signs = true,
    virtual_text = true,
    float = {
        show_header = false,
        source = 'if_many',
        border = 'rounded',
        focusable = false,
    },
    update_in_insert = false, -- default to false
    severity_sort = false, -- default to false
})

-- Disable numbers in nvimtree among other plugins
vim.g.numbers_exclude = { 'tagbar', 'startify', 'gundo', 'vimshell', 'w3m', 'NvimTree' }

-- Set updatetime for slower swapfile generation (if enabled)
vim.api.nvim_set_option('updatetime', 300)

EOF

" Completion extras

" Map tab temporarily before our buffer attach kicks in
inoremap <expr> <Tab>   pumvisible() ? "\<Cn>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
