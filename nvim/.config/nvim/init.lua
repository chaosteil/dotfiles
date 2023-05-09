-- Remap leader, needs to be done before plugin configs run
vim.keymap.set("n", " ", "<Nop>", { silent = true, noremap = true })
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup{
  { -- Sonokai colorscheme
    'sainnhe/sonokai',
    priority=1000,
    lazy=false,
    config=function()
      vim.cmd[[
      set termguicolors
      " Sets up the specific font and color for individual system settings
      let g:sonokai_style = 'andromeda'
      let g:sonokai_transparent_background = 1
      let g:sonokai_menu_selection_background = 'green'
      let g:sonokai_diagnostic_virtual_text = 'colored'
      let g:sonokai_enable_italic = 1
      colorscheme sonokai " Set up my currently favored colorscheme
      ]]
    end,
  },
  { -- Insert matching parens, quote
    'windwp/nvim-autopairs', 
    config=true
  },
  'embear/vim-localvimrc', -- Allows to have a local vimrc per folder
  { -- Better Go support
    'fatih/vim-go', 
    config = function()
      vim.cmd[[
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
      ]]
    end
  },
  { -- neovim LSP nicer UI
    'glepnir/lspsaga.nvim', 
    branch= 'main',
    opts = {
      symbol_in_winbar = {
        enable = false,
      },
  }}, 
  'weilbith/nvim-code-action-menu', -- Nice code action menu
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
      end,
    },
    opts = {
      history = true,
      delete_check_events = "TextChanged",
    },
    -- stylua: ignore
    keys = {
      {
        "<tab>",
        function()
          return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
        end,
        expr = true, silent = true, mode = "i",
      },
      { "<tab>", function() require("luasnip").jump(1) end, mode = "s" },
      { "<s-tab>", function() require("luasnip").jump(-1) end, mode = { "i", "s" } },
    },
  },
  {
    "hrsh7th/nvim-cmp",
    version = false, -- last release is way too old
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      'windwp/nvim-autopairs',
    },
    opts = function()
      local cmp = require("cmp")
      return {
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
        experimental = {
          ghost_text = {
            hl_group = "LspCodeLens",
          },
        },
      }
    end,
    config = function(_, opts)
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      local cmp = require('cmp')
      cmp.event:on(
        'confirm_done',
        cmp_autopairs.on_confirm_done()
        )
      cmp.setup(opts)
    end
  },
  { -- Pretty diagnostics
    'folke/trouble.nvim', 
    config = function() 
      vim.api.nvim_set_keymap("n", "<leader>xx", "<cmd>Trouble<cr>",
        {silent = true, noremap = true}
        )
      vim.api.nvim_set_keymap("n", "<leader>xq", "<cmd>Trouble quickfix<cr>",
        {silent = true, noremap = true}
        )
      -- Quickfix for workspace diagnostics
      vim.api.nvim_set_keymap("n", "<leader>xw", "<cmd>Trouble workspace_diagnostics<cr>", 
        {silent = true, noremap = true}
        )
      require("trouble").setup{}
    end
  },
  { -- Tags on the right
    'majutsushi/tagbar', 
    config = function()
      vim.cmd[[
      nnoremap <F3> :TagbarToggle<CR>
      ]]
    end
  },
  { -- Killer feature for undo
    'mbbill/undotree', 
    cmd='UndotreeToggle',
    config = function()
      vim.cmd[[
      let g:undotree_WindowLayout=3
      nnoremap <F4> :UndotreeToggle<CR>
      ]]
    end
  }, 
  { -- Git info
    'tanvirtin/vgit.nvim',
    dependencies={'nvim-lua/plenary.nvim'},
    config = true
  },
  { -- Better start screen
    'mhinz/vim-startify', 
    config = function()
      vim.cmd[[
      let g:startify_change_to_dir = 0  " I define my own dir with .lvimrc if I need it
        ]]
      end
  },
  'RRethy/vim-illuminate', -- Illuminate word under cursor
  'myusuf3/numbers.vim', -- Alters between relative and absolute line numbers in normal/insert mode
  'neomake/neomake', -- Syntax checking
  'nvim-lua/lsp_extensions.nvim', -- Additional LSP extension callbacks
  'nvim-lua/plenary.nvim', -- Helper functions for nvim lua
  'nvim-lua/popup.nvim', -- Vim popup API port in neovim
  { -- Fuzzy finder of many things
    'nvim-telescope/telescope.nvim', 
    dependencies={'nvim-lua/plenary.nvim'},
    config=function()
      require('telescope').setup{}
      require("telescope").load_extension("notify")
      vim.cmd[[
      nnoremap <C-P> <cmd>Telescope find_files<cr>
      nnoremap <C-G> <cmd>Telescope live_grep<cr>
      nnoremap <C-B> <cmd>Telescope buffers<cr>
      ]]
    end
  },
  { -- AST-based syntax highlighting
    'nvim-treesitter/nvim-treesitter',
    build=':TSUpdate',
    dependencies={
      'nvim-treesitter/playground',
    },
    config=function()
      require'nvim-treesitter.configs'.setup {
        ensure_installed = "all",  -- All maintained languages
        ignore_install = {"phpdoc"},  -- Gave some problems when launchin
        highlight = {
          enable = true
        },
        indent = {
          enable = true
        }
      }
    end
  }, 
  { -- add pictograms to lsp
    'onsails/lspkind-nvim', 
    config=function()
      require'lspkind'.init({
          mode = 'symbol',
        })
    end
  },
  {
    'rafamadriz/friendly-snippets',
    branch='main'
  },
  { -- LSP signature help
    'ray-x/lsp_signature.nvim', 
    config = true,
  },
  'rust-lang/rust.vim', -- Vim configuration for Rust
  'simrat39/rust-tools.nvim', -- Additional rust tooling for lsp
  { -- Autocommenting
    'numToStr/Comment.nvim', 
    config = function()
      require('Comment').setup{}
      vim.cmd[[
      nmap <silent> <C-_> gcc
      vmap <silent> <C-_> gc
      ]]
    end,
  },
  'sebdah/vim-delve', -- Delve debugging for Go
  'sheerun/vim-polyglot', -- More syntaxes
  'solarnz/arcanist.vim', -- Arcanist filetypes
  'tpope/vim-fugitive', -- Git functions
  'tpope/vim-speeddating', -- Can increase dates with c-a and c-x
  'tpope/vim-surround', -- Adds surround operator
  'tpope/vim-vinegar', -- Better netrw with -
  'uarun/vim-protobuf', -- protobuf colors
  { -- line at the bottom
    'nvim-lualine/lualine.nvim', 
    dependencies={'sainnhe/sonokai'},
    opts = {
      options = {
        theme = 'sonokai',
        component_separators = '',
        section_separators = { left = '', right = '' },
      },
      sections = {
        lualine_z = {'%3l/%L:%3c'}
      },
      extensions = {
        'fzf', 'quickfix', 'fugitive', 'neo-tree'
      }
    }
  },
  'mqudsi/a.vim', -- :A for switching between src and header files
  { -- File tree
    'nvim-neo-tree/neo-tree.nvim',  
    branch='v2.x',
    dependencies={'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons'},
    config=function()
      vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])
      require("neo-tree").setup{
        close_if_last_window = true,
        default_component_configs = {
          name = {
            trailing_slash = true,
          },
        },
        source_selector = {
          winbar = true,
        },
        window = {
          width = 30,
          mappings = {
            ["S"] = "open_vsplit",
            ["s"] = "open_split",
            ["v"] = "open_vsplit",
          },
        },
        filesystem = {
          window = {
            mappings = {
              ["-"] = "navigate_up",
            },
          },
        },
      }
      vim.cmd[[ nnoremap <F2> :NeoTreeShowToggle<CR> ]]
    end
  },
  'mfussenegger/nvim-dap', -- DAP support
  { -- Make colorcolumn appear only when over 80
    'm4xshen/smartcolumn.nvim', 
    opts = { colorcolumn="81" }
  },
  {  -- UI dressing
    'stevearc/dressing.nvim',
    config=true
  }, 
  { -- Notification dressing
    'rcarriga/nvim-notify', 
    config=function()
      require('notify').setup{
        background_colour = "#000000",
        render='compact',
      }
      vim.notify = require('notify')
    end
  },
  { -- LSP status window
    'j-hui/fidget.nvim',
    config=true
  }, 
  { -- Better yanking across ssh sessions
    'ojroques/vim-oscyank',
    branch='main',
    config=function()
      vim.keymap.set('n', '<leader>c', '<Plug>OSCYankOperator')
      vim.keymap.set('n', '<leader>cc', '<leader>c_', {remap = true})
      vim.keymap.set('v', '<leader>c', '<Plug>OSCYankVisual')
    end
  },
  { -- Colorful window separators
    'nvim-zh/colorful-winsep.nvim',
    config=true,
    event = { "WinNew" },
  }, 
  { -- Breadcrumbs in top view
    "utilyre/barbecue.nvim",
    version = "*",
    dependencies = {
      "neovim/nvim-lspconfig",
      "SmiteshP/nvim-navic",
      "nvim-tree/nvim-web-devicons", -- optional dependency
      'sainnhe/sonokai',
    },
    opts = {
      theme = 'sonokai',
      show_modified = true,
      symbols = {
        modified = "[+]",
        separator = '',
      },
    },
  },
  {
    'ErichDonGubler/lsp_lines.nvim',
    config=function()
      require("lsp_lines").setup()
      vim.keymap.set(
        "",
        "<Leader>l",
        require("lsp_lines").toggle,
        { desc = "Toggle lsp_lines" }
      )
    end
  },
  { -- Lsp adapter for languages that have none
    'jose-elias-alvarez/null-ls.nvim',
    dependencies = {
      'williamboman/mason.nvim',
      'nvim-lua/plenary.nvim'
    },
    config = function()
      local null_ls = require("null-ls")
      null_ls.setup{
        sources={
          null_ls.builtins.code_actions.shellcheck,
          null_ls.builtins.diagnostics.shellcheck,

          null_ls.builtins.formatting.markdownlint,
          null_ls.builtins.diagnostics.markdownlint,

          null_ls.builtins.formatting.jq,

          null_ls.builtins.diagnostics.yamllint,
          null_ls.builtins.formatting.yamlfmt,
        }
      }
    end,
  },
  { -- Tooling installer
    'williamboman/mason.nvim',
    dependencies = {
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
    },
    config=function()
      require("mason").setup{}
      require('mason-tool-installer').setup{
        ensure_installed = {
          'gopls',
          'rust-analyzer',
          'pyright',
          'typescript-language-server',
          'zls',

          -- null-ls non-lsp configs
          'markdownlint',
          'shellcheck',
          'jq',
          'yamllint',
          'yamlfmt',
        }
      }
      require("mason-lspconfig").setup{}
    end,
  },
  { -- Default LSP configurations
    'neovim/nvim-lspconfig', 
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'hrsh7th/nvim-cmp',
      'simrat39/rust-tools.nvim',
    },
    config=function()
      local nvim_lsp = require('lspconfig')

      -- Update cmp
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

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
        nvim_lsp[lsp].setup { capabilities = capabilities }
      end

      -- gopls and rust-analyzer have custom configs here
      local rust_tool_opts = {
        tools = {
          autoSetHints = true,
          runnables = {
            use_telescope = true,
          },
          inlay_hints = {
            show_parameter_hints = false,
            other_hints_prefix  = " ",
            highlight = "Conceal"
          },
        },
      }

      require('rust-tools').setup(rust_tool_opts)

      -- Attach gopls to any running gopls if it exists
      nvim_lsp.gopls.setup {
        capabilities = capabilities,
        cmd = {'gopls', '--remote=auto'},
        flags = {
          debounce_text_changes = 1000,
        },
        init_options = {
          analyses = {
            unusedparams = true,
            nilness = true,
            unusedwrite = true,
          },
          staticcheck = true,
          gofumpt = true,
          memoryMode = "DegradeClosed",
        }
      }
    end
  }
}

-- auto-reload files when modified externally
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained"}, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = {"*"},
})

vim.cmd[[
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
set signcolumn=yes:1 " Always enable sign column for git or LSP info
set nohidden " Never make an unsaved buffer disappear off-screen

" More comfortable search
set ignorecase " Ignores the case of the searched item
set smartcase " If contains uppercase letter, make it a case-sensitive search

" Using these two together will use vim hybrid line number mode
set relativenumber " Relative number lines
set number " Show line in front of each line

set showcmd " Show command in the last line of the screen
set ruler " Show line, column, etc. at the bottom

set showmatch " Show matching braces

set mouse=a " Mouse enabled for all modes

" We don't want any interruptions
set noerrorbells
set novisualbell

" Highlight search
set hlsearch
" Space to turn off highlighting
nnoremap <silent> <leader><space> :nohlsearch<Bar>:echo<CR>

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

" Some completion options {{{
set completeopt=menu,menuone,noselect
set pumheight=15 " Max items in the insert mode completion
" }}}

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

" Nvim terminal settings
tnoremap <Esc> <C-\><C-n> " Enter normal mode on escape

" Local vimrc settings
let g:localvimrc_ask=0

let g:rustfmt_autosave = 1

" Show highlight when yanking
au TextYankPost * silent! lua vim.highlight.on_yank {higroup="IncSearch", timeout=150, on_visual=false}
]]

-------------------- Lua Config ---------------------------------

-- Use an lsp_on_attach function to only map the following keys 
-- after the language server attaches to the current buffer
local lsp_on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  --Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gh', '<Cmd>Lspsaga lsp_finder<CR>', opts) -- Shows definitions, references etc.
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>Lspsaga peek_definition<CR>', opts) -- Inline definition
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<C-]>', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>Lspsaga hover_doc<CR>', opts)  -- Documentation
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<leader>R', '<cmd>Lspsaga rename<CR>', opts)
  buf_set_keymap('n', '<leader><CR>', '<cmd>CodeActionMenu<CR>', opts)
  buf_set_keymap('n', '<leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.format()<CR>", opts)
  vim.keymap.set("v", "<leader>f", vim.lsp.buf.format, {buffer=bufnr, noremap=true, silent=true})
end

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		lsp_on_attach(client, args.buf)
	end,
})

-- Diagnostic options

local signs = { Error = "", Warn = "", Hint = "", Info = "" } 
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl= hl, numhl = hl })
end

vim.diagnostic.config({
    underline = true,
    signs = true,
    virtual_text = false,
    virtual_lines = true,
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
vim.g.numbers_exclude = { 'tagbar', 'startify', 'gundo', 'vimshell', 'w3m', 'sagahover', 'neo-tree', 'notify' }

-- Set updatetime for slower swapfile generation (if enabled)
vim.api.nvim_set_option('updatetime', 300)
