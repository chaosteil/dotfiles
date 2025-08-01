-- Remap leader, needs to be done before plugin configs run
vim.keymap.set('n', ' ', '<Nop>', { silent = true, noremap = true })
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Plugin manager
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  { -- Sonokai colorscheme
    'sainnhe/sonokai',
    priority = 1000,
    lazy = false,
    config = function()
      vim.o.termguicolors = true
      -- Sets up the specific font and color for individual system settings
      vim.g.sonokai_style = 'andromeda'
      vim.g.sonokai_transparent_background = 1
      vim.g.sonokai_menu_selection_background = 'green'
      vim.g.sonokai_enable_italic = 1
      vim.g.sonokai_better_performance = 1
      vim.g.sonokai_inlay_hints_background = 'none'
      vim.g.sonokai_diagnostic_virtual_text = 'highlighted'
      vim.g.sonokai_diagnostic_text_highlight = 1
      -- Set up my currently favored colorscheme
      vim.cmd('colorscheme sonokai')
    end,
  },
  { -- Rainbox delimiters to make parentheses more readable
    'HiPhish/rainbow-delimiters.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'sainnhe/sonokai',
    },
  },
  { -- Insert matching parens, quote
    'windwp/nvim-autopairs',
    config = true,
  },
  { -- Smear cursor on movement
    'sphamba/smear-cursor.nvim',
    opts = {
      never_draw_over_target = true,
      min_horizontal_distance_smear = 1,
      min_vertical_distance_smear = 1,
      distance_stop_animating = 1,
    },
  },
  { -- Highlight whitespace
    'johnfrankmorgan/whitespace.nvim',
    opts = {
      ignored_filetypes = { 'TelescopePrompt', 'Trouble', 'help', 'lazy' },
    },
  },
  { -- Git conflict markers
    'akinsho/git-conflict.nvim',
    version = '*',
    config = true,
  },
  { -- Allows to have a local vimrc per folder
    'embear/vim-localvimrc',
    config = function()
      vim.g.localvimrc_ask = 0 -- don't ask before loading a local vimrc
    end,
  },
  { -- Better Go support
    'fatih/vim-go',
    config = function()
      -- Automagically run gopls with gofmumpt on save
      vim.g.go_fmt_command = 'gopls'
      vim.g.go_gopls_gofumpt = 1
      vim.g.go_def_mapping_enabled = 0 -- Disable so LSP can take over

      -- Better highlighting
      vim.g.go_highlight_array_whitespace_error = 1
      vim.g.go_highlight_chan_whitespace_error = 1
      vim.g.go_highlight_extra_types = 1
      vim.g.go_highlight_space_tab_error = 1
      vim.g.go_highlight_trailing_whitespace_error = 1
      vim.g.go_highlight_operators = 1
      vim.g.go_highlight_functions = 1
      vim.g.go_highlight_function_arguments = 1
      vim.g.go_highlight_function_calls = 1
      vim.g.go_highlight_methods = 1
      vim.g.go_highlight_fields = 1
      vim.g.go_highlight_types = 1
      vim.g.go_highlight_generate_tags = 1
      vim.g.go_highlight_build_constraints = 1
      vim.g.go_highlight_variable_declarations = 1

      -- Run lint and vet on save
      vim.g.go_metalinter_autosave = 1
      vim.g.go_metalinter_autosave_enabled = { 'all' }
      vim.g.go_jump_to_error = 0

      -- Remap to use :A for swapping between tests and non-tests
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'go',
        callback = function()
          vim.api.nvim_create_user_command('A', function()
            vim.cmd('GoAlternate')
          end, {})
        end,
      })
    end,
  },
  { -- neovim LSP nicer UI
    'nvimdev/lspsaga.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    branch = 'main',
    opts = {
      symbol_in_winbar = {
        enable = false,
      },
    },
  },
  { -- Expanded hover menu
    'lewis6991/hover.nvim',
    opts = {
      init = function()
        require('hover.providers.lsp')
        require('hover.providers.gh')
        require('hover.providers.gh_user')
        require('hover.providers.jira')
        require('hover.providers.man')
        require('hover.providers.dictionary')
      end,
    },
  },
  'aznhe21/actions-preview.nvim', -- Nice code action menu
  { -- Autocompletion
    'saghen/blink.cmp',
    version = '*',
    event = 'InsertEnter',
    dependencies = {
      'rafamadriz/friendly-snippets',
    },
    opts = {
      completion = {
        list = {
          selection = {
            preselect = function(ctx)
              return ctx.mode ~= 'cmdline'
            end,
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 100,
        },
      },
      keymap = {
        preset = 'enter',
        ['<C-U>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-D>'] = { 'scroll_documentation_down', 'fallback' },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono',
      },
      sources = {
        default = { 'lsp', 'snippets', 'buffer', 'path' },
      },
    },
    opts_extend = { 'sources.default' },
  },
  { -- Pretty diagnostics
    'folke/trouble.nvim',
    config = function()
      vim.keymap.set('n', '<leader>xx', function()
        require('trouble').toggle('diagnostics_split')
      end)
      vim.keymap.set('n', '<leader>xb', function()
        require('trouble').toggle('diagnostics_buffer')
      end)
      vim.keymap.set('n', '<leader>xq', function()
        require('trouble').toggle('quickfix')
      end)
      vim.keymap.set('n', '<leader>xl', function()
        require('trouble').toggle('loclist')
      end)
      vim.keymap.set('n', 'gR', function()
        require('trouble').toggle('lsp_references')
      end)
      require('trouble').setup({
        modes = {
          diagnostics_split = {
            mode = 'diagnostics',
            preview = {
              type = 'split',
              relative = 'win',
              position = 'right',
              size = 0.3,
            },
          },
          diagnostics_buffer = {
            mode = 'diagnostics_split', -- inherit from diagnostics mode
            filter = { buf = 0 }, -- filter diagnostics to the current buffer
          },
        },
      })
    end,
  },
  { -- Tags on the right
    'majutsushi/tagbar',
    config = function()
      vim.keymap.set('n', '<F3>', function()
        vim.cmd('TagbarToggle')
      end)
    end,
  },
  { -- Killer feature for undo
    'mbbill/undotree',
    cmd = 'UndotreeToggle',
    init = function()
      vim.g.undotree_WindowLayout = 3
      vim.keymap.set('n', '<F4>', function()
        vim.cmd('UndotreeToggle')
      end)
    end,
  },
  { -- Git info
    'tanvirtin/vgit.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = true,
  },
  { -- Better start screen
    'mhinz/vim-startify',
    config = function()
      vim.g.startify_change_to_dir = 0 -- I define my own dir with .lvimrc if I need it
    end,
  },
  'RRethy/vim-illuminate', -- Illuminate word under cursor
  'myusuf3/numbers.vim', -- Alters between relative and absolute line numbers in normal/insert mode
  'nvim-lua/lsp_extensions.nvim', -- Additional LSP extension callbacks
  'nvim-lua/plenary.nvim', -- Helper functions for nvim lua
  'nvim-lua/popup.nvim', -- Vim popup API port in neovim
  {
    'RaafatTurki/hex.nvim',
    config = function()
      vim.keymap.set('n', '<leader>H', require('hex').toggle)
    end,
  },
  { -- Fuzzy finder of many things
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      -- Go up one directory in the file picker from the currently selected file
      local go_path_up = function(prompt_bufnr)
        local entry = require('telescope.actions.state').get_selected_entry().cwd
        require('telescope.actions').close(prompt_bufnr)

        local cwd = vim.fs.normalize(entry .. '/..')
        vim.notify(cwd)
        require('telescope.builtin').find_files({ cwd = cwd })
      end
      require('telescope').setup({
        pickers = {
          find_files = {
            mappings = {
              i = {
                ['<C-->'] = go_path_up,
              },
              n = {
                ['-'] = go_path_up,
              },
            },
          },
        },
      })
      require('telescope').load_extension('notify')
      vim.keymap.set('n', '<C-P>', function()
        vim.cmd('Telescope find_files')
      end, { noremap = true })
      vim.keymap.set('n', '<C-G>', function()
        vim.cmd('Telescope live_grep')
      end, { noremap = true })
      vim.keymap.set('n', '<C-B>', function()
        vim.cmd('Telescope buffers')
      end, { noremap = true })
    end,
  },
  { -- AST-based syntax highlighting
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    dependencies = {
      'nvim-treesitter/playground',
    },
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = 'all', -- All maintained languages
        ignore_install = { 'phpdoc' }, -- Gave some problems when launchin
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
          disable = { 'gdscript' },
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<leader>v',
            node_incremental = '<leader>v',
            node_decremental = '<leader>V',
          },
        },
      })
    end,
  },
  { -- Show context about current position of cursor.
    'nvim-treesitter/nvim-treesitter-context',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    config = true,
  },
  { -- add pictograms to lsp
    'onsails/lspkind-nvim',
    config = function()
      require('lspkind').init({
        mode = 'symbol',
      })
    end,
  },
  {
    'rafamadriz/friendly-snippets',
    branch = 'main',
  },
  { -- LSP signature help
    'ray-x/lsp_signature.nvim',
    config = true,
  },
  'rust-lang/rust.vim', -- Vim configuration for Rust
  { -- Additional rust tooling for lsp
    'mrcjkb/rustaceanvim',
    version = '^4',
    ft = { 'rust' },
  },
  { -- helps manage Rust crates
    'saecki/crates.nvim',
    event = { 'BufRead Cargo.toml' },
    config = function()
      require('crates').setup()
    end,
  },
  { -- for interacting with Rust LSP extensions
    'vxpm/ferris.nvim',
    opts = {},
  },
  { -- Autocommenting
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup({})
      vim.keymap.set('n', '<C-_>', 'gcc', { silent = true, remap = true })
      vim.keymap.set('n', '<C-/>', 'gcc', { silent = true, remap = true })
      vim.keymap.set('v', '<C-_>', 'gc', { silent = true, remap = true })
      vim.keymap.set('v', '<C-/>', 'gc', { silent = true, remap = true })
    end,
  },
  'sheerun/vim-polyglot', -- More syntaxes
  'solarnz/arcanist.vim', -- Arcanist filetypes
  'tpope/vim-fugitive', -- Git functions
  'tpope/vim-speeddating', -- Can increase dates with c-a and c-x
  'tpope/vim-surround', -- Adds surround operator
  'tpope/vim-vinegar', -- Better netrw with -
  'uarun/vim-protobuf', -- protobuf colors
  'avm99963/vim-jjdescription', -- jjdesc colors
  { -- line at the bottom
    'nvim-lualine/lualine.nvim',
    dependencies = {
      'sainnhe/sonokai',
      'AndreM222/copilot-lualine',
    },
    opts = {
      options = {
        theme = 'sonokai',
        component_separators = '',
        section_separators = { left = '', right = '' },
      },
      sections = {
        lualine_x = {
          {
            'copilot',
            show_colors = true,
          },
          'encoding',
          'fileformat',
          'filetype',
        },
        lualine_z = { '%3l/%L:%3c' },
      },
      extensions = {
        'fzf',
        'quickfix',
        'fugitive',
        'neo-tree',
      },
    },
  },
  'mqudsi/a.vim', -- :A for switching between src and header files
  { -- Nice markdown preview
    'OXY2DEV/markview.nvim',
    ft = 'markdown',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    opts = {
      preview = {
        filetypes = { 'markdown', 'codecompanion' },
        ignore_buftypes = {},
        icon_provider = 'devicons',
        hybrid_modes = { 'n' },
      },
    },
  },
  { -- Highlight colors inline
    'brenoprata10/nvim-highlight-colors',
    opts = {
      render = 'virtual',
      enable_named_colors = false,
      enable_tailwind = true,
    },
  },
  { -- File tree
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = { 'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons' },
    config = function()
      vim.g.neo_tree_remove_legacy_commands = 1
      require('neo-tree').setup({
        close_if_last_window = true,
        auto_clean_after_session_restore = true,
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
            ['/'] = '',
            ['w'] = '',
            ['f'] = 'fuzzy_finder',
            ['F'] = 'filter_on_submit',
            ['S'] = 'open_vsplit',
            ['s'] = 'open_split',
            ['v'] = 'open_vsplit',
          },
        },
        filesystem = {
          window = {
            mappings = {
              ['-'] = 'navigate_up',
            },
          },
        },
      })
      vim.keymap.set('n', '<F2>', function()
        vim.cmd('Neotree toggle show filesystem left')
      end)
    end,
  },
  'mfussenegger/nvim-dap', -- DAP support
  { -- DAP UI
    'rcarriga/nvim-dap-ui',
    dependencies = {
      'mrcjkb/rustaceanvim',
      'nvim-neotest/nvim-nio',
    },
    config = function()
      require('dapui').setup()
      local dap, dapui = require('dap'), require('dapui')
      dap.listeners.after.event_initialized['dapui_config'] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated['dapui_config'] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited['dapui_config'] = function()
        dapui.close()
      end
      vim.keymap.set('n', '<leader>dq', function()
        dapui.close()
      end)
      vim.keymap.set('n', '<leader>dc', function()
        dap.continue()
      end)
      vim.keymap.set('n', '<leader>dn', function()
        dap.step_over()
      end)
      vim.keymap.set('n', '<leader>ds', function()
        dap.step_into()
      end)
      vim.keymap.set('n', '<leader>do', function()
        dap.step_out()
      end)
      vim.keymap.set('n', '<leader>dP', function()
        dap.pause()
      end)
      vim.keymap.set('n', '<leader>db', function()
        dap.toggle_breakpoint()
      end)
      vim.keymap.set('n', '<leader>dr', function()
        dap.repl.open()
      end)
      vim.keymap.set('n', '<leader>dl', function()
        dap.run_last()
      end)
      vim.keymap.set('n', '<leader>dx', function()
        dap.terminate()
      end)
    end,
  },
  { -- Make colorcolumn appear only when over 80
    'm4xshen/smartcolumn.nvim',
    opts = { colorcolumn = '81' },
  },
  { -- UI dressing
    'stevearc/dressing.nvim',
    config = true,
  },
  { -- Notification dressing
    'rcarriga/nvim-notify',
    config = function()
      require('notify').setup({
        background_colour = '#000000',
        render = 'compact',
      })
      vim.notify = require('notify')
    end,
  },
  { -- LSP status window
    'j-hui/fidget.nvim',
    opts = {},
  },
  { -- Automatic session managment
    'echasnovski/mini.sessions',
  },
  { -- Improved text objects for a and i
    'echasnovski/mini.ai',
  },
  { -- Better yanking across ssh sessions
    'ojroques/vim-oscyank',
    branch = 'main',
    config = function()
      vim.keymap.set('n', '<leader>y', '<Plug>OSCYankOperator')
      vim.keymap.set('n', '<leader>yy', '<leader>y_', { remap = true })
      vim.keymap.set('v', '<leader>y', '<Plug>OSCYankVisual')
    end,
  },
  { -- Colorful yank highlight among others
    'gbprod/yanky.nvim',
    opts = {
      highlight = {
        timer = 100,
      },
    },
  },
  { -- Colorful window separators
    'nvim-zh/colorful-winsep.nvim',
    config = true,
    event = { 'WinNew' },
  },
  { -- Formatter
    'stevearc/conform.nvim',
    config = function()
      require('conform').setup({
        formatters_by_ft = {
          lua = { 'stylua' },
          markdown = { 'markdownlint' },
          sh = { 'shellcheck' },
          yaml = { 'yamlfix' },
          toml = { 'taplo' },
        },
        formatters = {
          stylua = {
            prepend_args = {
              '--quote-style',
              'AutoPreferSingle',
              '--indent-width',
              '2',
              '--indent-type',
              'Spaces',
            },
          },
          yamlfix = {
            env = {
              YAMLFIX_EXPLICIT_START = 'false', -- Don't add the --- header if missing
            },
          },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_format = 'fallback',
        },
      })

      -- Formatexpr
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },
  { -- Breadcrumbs in top view
    'Bekaboo/dropbar.nvim',
    dependencies = {
      -- optional, but required for fuzzy finder support
      'nvim-telescope/telescope-fzf-native.nvim',
      -- icons
      'nvim-tree/nvim-web-devicons',
      build = 'make',
    },
    config = function()
      local dropbar = require('dropbar')
      local configs = require('dropbar.configs')
      local dropbar_api = require('dropbar.api')
      vim.keymap.set('n', '<Leader>;', dropbar_api.pick, { desc = 'Pick symbols in winbar' })
      vim.api.nvim_set_hl(0, 'DropBarKindDir', { link = 'Comment' })
      dropbar.setup({
        sources = {
          path = {
            modified = function(sym)
              return sym:merge({
                icon = '[+] ',
                name_hl = 'DiagnosticWarn',
                icon_hl = 'DiagnosticWarn',
              })
            end,
          },
        },
      })
    end,
  },
  {
    'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
    config = function()
      require('lsp_lines').setup()
      vim.keymap.set('', '<leader>l', function()
        lines = require('lsp_lines').toggle()
        vim.diagnostic.config({ virtual_text = not lines })
      end, { desc = 'Toggle lsp_lines' })
      vim.keymap.set('', '<leader>L', function()
        cfg = vim.diagnostic.config()
        if cfg.virtual_text or cfg.virtual_lines then
          vim.diagnostic.config({ virtual_text = false, virtual_lines = false })
        else
          vim.diagnostic.config({ virtual_text = true, virtual_lines = false })
        end
      end, { desc = 'Toggle lsp_lines and virtual text completely' })
    end,
  },
  { -- Linter
    'mfussenegger/nvim-lint',
    event = {
      'BufReadPre',
      'BufNewFile',
    },
    config = function()
      local lint = require('lint')
      lint.linters_by_ft = {
        markdown = { 'markdownlint' },
        yaml = { 'yamllint' },
      }
      lint.linters.markdownlint.args = {
        '--disable',
        'MD013', -- Ignore line length in markdown lints
        '--stdin',
      }
      lint.linters.yamllint.args = {
        '-d',
        '{rules: {document-start: {present: false}}}', -- ignore the `---` header missing
        '--format',
        'parsable',
        '-',
      }

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
  { -- Tooling installer
    'mason-org/mason.nvim',
    dependencies = {
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
    },
    config = function()
      require('mason').setup({})
      require('mason-tool-installer').setup({
        ensure_installed = {
          'gopls',
          'pyright',
          'typescript-language-server',
          'zls',
          'delve',
          'codelldb',
          'jsonls',
          'bash-language-server',

          -- non-lsp configs
          'markdownlint',
          'stylua',
          'yamlfix',
          'yamllint',
          'taplo',
        },
      })
      require('mason-lspconfig').setup({})
    end,
  },
  { -- Default LSP configurations
    'neovim/nvim-lspconfig',
    dependencies = {
      'mason-org/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
      'saghen/blink.cmp',
      'mrcjkb/rustaceanvim',
      'mfussenegger/nvim-dap',
    },
    config = function()
      local nvim_lsp = require('lspconfig')
      local mason_registry = require('mason-registry')

      -- Update cmp
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      capabilities.textDocument.completion.completionItem.snippetSupport = true
      capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = {
          'documentation',
          'detail',
          'additionalTextEdits',
        },
      }

      -- Use a loop to conveniently call 'setup' on multiple servers and
      -- map buffer local keybindings when the language server attaches
      local servers = {
        'gdscript',
        'pyright',
        'ts_ls',
        'zls',
        'bashls',
        'jsonls',
      }

      for _, lsp in ipairs(servers) do
        nvim_lsp[lsp].setup({ capabilities = capabilities })
      end

      -- gopls and rust-analyzer have custom configs here
      local codelldb = mason_registry.get_package('codelldb')
      local extension_path = vim.fn.expand('$MASON/packages/codelldb') .. '/extension/'
      local codelldb_path = extension_path .. 'adapter/codelldb'
      local liblldb_path = extension_path .. 'lldb/lib/liblldb.dylib'
      local rustaceanvim = {
        dap = {
          adapter = require('rustaceanvim.config').get_codelldb_adapter(codelldb_path, liblldb_path),
          autoload_configurations = true,
        },
        server = {
          capabilities = capabilities,
        },
        tools = {
          autoSetHints = true,
          runnables = {
            use_telescope = true,
          },
        },
      }
      vim.g.rustaceanvim = rustaceanvim

      -- Attach gopls to any running gopls if it exists
      nvim_lsp.gopls.setup({
        capabilities = capabilities,
        cmd = { 'gopls', '--remote=auto' },
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
          hints = {
            compositeLiteralFields = true,
            parameterNames = true,
          },
        },
      })
    end,
  },
  { -- Copilot
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {
      suggestion = {
        auto_trigger = true,
        keymap = {
          dismiss = '<M-p>',
          accept = '<M-\\>',
          next = '<M-]>',
          prev = '<M-[>',
        },
      },
    },
  },
  { -- AI code companion
    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {},
    config = function()
      require('codecompanion').setup({})
      vim.keymap.set('n', '<leader>cc', function()
        vim.cmd('CodeCompanionActions')
      end)
      vim.keymap.set('n', '<leader>cp', function()
        vim.cmd('CodeCompanion')
      end)
    end,
  },
})

-- auto-reload files when modified externally
vim.o.autoread = true
vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'CursorHoldI', 'FocusGained' }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = { '*' },
})

-- Some file path operations
-- Change working directory to the current file's directory
vim.keymap.set('n', '<leader>p.', function()
  vim.cmd('cd %:p:h')
end)
-- Change working directory to be one level higher
vim.keymap.set('n', '<leader>p-', function()
  vim.cmd('cd ..')
end)

-- Nice title
vim.o.title = true
vim.o.titlestring = '%f%h%m%r%w - nvim'

-- Make command line completion nicer
vim.o.wildmenu = true

-- Let files reopen on the same line if opened again
vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = { '*' },
  callback = function()
    if vim.fn.line('\'"') > 1 and vim.fn.line('\'"') <= vim.fn.line('$') then
      vim.api.nvim_exec('normal! g\'"', false)
    end
  end,
})

-- Allows to write a file when forgot to do sudo
vim.keymap.set('c', 'w!!', ':w ! sudo tee % > /dev/null')

-- No swaps etc
vim.o.backup = false
vim.o.swapfile = false

-- Persistent undo, I cannot overstate how much I love this
vim.o.undofile = true
vim.o.undodir = vim.fn.expand('~/.config/nvim/undo')
vim.o.undolevels = 1000
vim.o.undoreload = 10000

vim.o.lazyredraw = true -- Do not show macro expansion visually
vim.o.showtabline = 1 -- Show tabs on top only if available

local function paste()
  return {
    vim.fn.split(vim.fn.getreg(''), '\n'),
    vim.fn.getregtype(''),
  }
end

vim.g.clipboard = {
  name = 'OSC52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = paste,
    ['*'] = paste,
  },
}

vim.o.clipboard = 'unnamedplus'
vim.o.fileformats = 'unix,mac,dos'

vim.o.encoding = 'utf-8'
vim.o.wrap = false
vim.o.linebreak = false
vim.o.tabstop = 4
vim.o.cursorline = true -- Highlight screen line where the cursor is
vim.o.shiftwidth = 2 -- Number of spaces for each step of indent
vim.o.expandtab = true -- Expand tab to spaces by default
vim.o.smartindent = true -- Smart indenting when starting a new line
vim.o.autoindent = true -- Copy indent from current line when starting a new line
vim.o.scrolloff = 10 -- Keeps the cursor 10 lines from the top or bottom of the screen
vim.o.ttimeoutlen = 50 -- To not pause after leaving insert mode
vim.o.signcolumn = 'yes:1' -- Always enable sign column for git or LSP info
vim.o.hidden = false -- Never make an unsaved buffer disappear off-screen

-- More comfortable search
vim.o.ignorecase = true -- Ignores the case of the searched item
vim.o.smartcase = true -- If contains uppercase letter, make it a case-sensitive search

-- Using these two together will use vim hybrid line number mode
vim.o.relativenumber = true -- Relative number lines
vim.o.number = true -- Show line in front of each line

vim.o.showcmd = true -- Show command in the last line of the screen
vim.o.ruler = true -- Show line, column, etc. at the bottom

vim.o.showmatch = true -- Show matching braces

vim.o.mouse = 'a' -- Mouse enabled for all modes

-- We don't want any interruptions
vim.o.errorbells = false
vim.o.visualbell = false

-- Highlight search
vim.o.hlsearch = true
-- Double space to remove highlight
vim.keymap.set('n', '<leader><space>', function()
  vim.cmd('nohlsearch')
end, { silent = true })

-- Enable incremental commands for more visual feedback
vim.o.inccommand = 'nosplit'

-- Custom Colorcolumn settings
vim.api.nvim_set_hl(0, 'colorcolumn', { ctermbg = 'red', ctermfg = 'white', bg = '#592929' })
vim.o.colorcolumn = '81' -- Make a colorcolumn for the 81st symbol
vim.o.textwidth = 80 -- Also automatically split at 80

-- Some completion options
vim.o.completeopt = 'menu,menuone,noselect'
vim.o.pumheight = 15 -- Max items in the insert mode completion

-- Changed split behavior to open splits by default below and on the right
vim.o.splitbelow = true
vim.o.splitright = true

vim.keymap.set('i', '#', 'X<BS>#') -- Don't drop the indent when writing #

-- List mapping, show special symbols instead of nothing in special situations
vim.o.list = true
vim.o.listchars = 'tab:▸ ,extends:❯,precedes:❮'
vim.o.fillchars = (vim.o.fillchars or '') .. 'vert:│'

-- Substitution
vim.o.gdefault = true -- No more g in substitute operations

-- Disable annoying keys
vim.keymap.set('n', '<F1>', '<nop>')
vim.keymap.set('n', 'Q', '<nop>')

-- Folding settings, default disabled
vim.o.foldenable = false
vim.o.foldlevel = 10
vim.o.foldmethod = 'syntax'

-- Nvim terminal settings
vim.keymap.set('t', '<Esc>', '<C-\\><C-n') -- Enter normal mode on escape

-- Use an lsp_on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local lsp_on_attach = function(client, bufnr)
  local function buf_set_keymap(...)
    vim.api.nvim_buf_set_keymap(bufnr, ...)
  end
  local function buf_set_option(...)
    vim.api.nvim_buf_set_option(bufnr, ...)
  end

  --Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
  -- Enable inlay hints if available.
  if vim.lsp.inlay_hint then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end
  vim.lsp.set_log_level('off') -- Disable LSP logging for some minor performance

  -- Mappings.
  local opts = { buffer = bufnr, noremap = true, silent = true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  vim.keymap.set('n', 'gh', function()
    vim.cmd('Lspsaga finder')
  end, opts) -- Shows definitions, references etc.
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gd', function()
    vim.cmd('Lspsaga peek_definition')
  end, opts) -- Inline definition
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', '<C-]>', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', require('hover').hover, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', 'gI', function()
    vim.cmd('Lspsaga finder imp')
  end, opts)
  vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
  vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
  vim.keymap.set('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts)
  vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
  vim.keymap.set('n', '<leader>i', function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
  end, opts)
  vim.keymap.set('n', '<leader>R', function()
    vim.cmd('Lspsaga rename')
  end, opts)
  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
  vim.keymap.set('n', '<leader>xn', vim.diagnostic.goto_next)
  vim.keymap.set('n', '<leader>xp', vim.diagnostic.goto_prev)
  vim.keymap.set({ 'v', 'n' }, '<leader><CR>', require('actions-preview').code_actions)
  vim.keymap.set({ 'v', 'n' }, '<leader>f', function()
    require('conform').format({ bufnr = bufnr, lsp_fallback = true, async = true })
  end, opts)
  vim.keymap.set({ 'v', 'n' }, '<leader>F', function()
    require('conform').format({ bufnr = bufnr, lsp_fallback = true, timeout_ms = 2000 })
  end, opts)
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    lsp_on_attach(client, args.buf)
  end,
})

-- Diagnostic options
vim.diagnostic.config({
  underline = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.INFO] = '',
      [vim.diagnostic.severity.HINT] = '',
    },
    texthl = {
      [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
      [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
      [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
      [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
      [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
      [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
      [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
    },
  },
  virtual_text = true,
  virtual_lines = false,
  float = {
    show_header = false,
    source = 'if_many',
    border = 'rounded',
    focusable = false,
  },
  update_in_insert = false, -- default to false
  severity_sort = false, -- default to false
})

-- Disable numbers in neotree among other plugins
vim.g.numbers_exclude = { 'tagbar', 'startify', 'gundo', 'vimshell', 'w3m', 'sagahover', 'neo-tree', 'notify' }

-- Set updatetime for slower swapfile generation (if enabled)
vim.api.nvim_set_option('updatetime', 300)
