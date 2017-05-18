" Chaosteils Neovim init.vim

" Plug Settings
if has('gui_win32')
  let plugpath='~/vimfiles/bundle'
else
  let plugpath='~/.config/nvim/bundle'
end

" Reenable checking of filetypes and filetype indent plugins
call plug#begin(plugpath)

 " Snippets
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'

function! DoRemote(arg)
  UpdateRemotePlugins
endfunction
Plug 'Raimondi/delimitMate' " Inserts matching parens, quote
Plug 'neomake/neomake' " Syntax checking
Plug 'elzr/vim-json' " Better json highlighting
Plug 'embear/vim-localvimrc' " Allows to have a local vimrc per folder
Plug 'Shougo/deoplete.nvim', { 'do': function('DoRemote') }
Plug 'ervandew/supertab' " Tab on steroids
Plug 'fatih/vim-go' " Better Go support
Plug 'gotgenes/vim-yapif' " python indentaiton
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install --no-update-rc' } " Fuzzy finder (ctrlp replacement)
Plug 'majutsushi/tagbar' " Tags on the right
Plug 'mattn/gist-vim' " Quick gist
Plug 'mbbill/undotree', { 'on': 'UndotreeToggle' } " Killer feature for undo
Plug 'mhinz/vim-signify' " Git marks next to line numbers
Plug 'mhinz/vim-startify' " Better start screen
Plug 'myusuf3/numbers.vim' " Alters between relative and absolute line numbers in normal/insert mode
Plug 'plasticboy/vim-markdown' " Better syntax highlighting for markdown
Plug 'rhysd/vim-clang-format' " Quick access to clang format
Plug 'scrooloose/nerdcommenter' " Autocommenting
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' } " Tree toggle
Plug 'sheerun/vim-polyglot' " More syntaxes
Plug 'solarnz/arcanist.vim' " Arcanist filetypes
Plug 'tomasr/molokai' " Molokai color scheme
Plug 'tpope/vim-fugitive' " Git functions
Plug 'tpope/vim-obsession' " Better vim sessions
Plug 'tpope/vim-speeddating' " Can increase dates with c-a and c-x
Plug 'tpope/vim-surround' " Adds surround operator
Plug 'tpope/vim-vinegar' " Better netrw with -
Plug 'uarun/vim-protobuf' " protobuf colors
Plug 'vim-airline/vim-airline' " airline at the bottom
Plug 'vim-airline/vim-airline-themes' " we want pretty airline colors
Plug 'xolox/vim-easytags' " Ctags generation
Plug 'xolox/vim-lua-ftplugin' " More lua completion
Plug 'xolox/vim-misc' " Library for xolox scripts
Plug 'rust-lang/rust.vim' " Vim configuration for Rust
Plug 'racer-rust/vim-racer' " Rust autocompletion
"Plug 'yuttie/comfortable-motion.vim' " Smooth scrolling

Plug 'a.vim' " :A for switching between src and header files
Plug 'google.vim' " Google style guide
Plug 'utl.vim' " Execute urls

call plug#end()

" Colorscheme {{{
" Sets up the specific font and color for individual system settings

syntax on " Enable syntax highlighting
colorscheme molokai " Set up my currently favored colorscheme
" Disable terminal background for transparency goodness
hi Normal ctermbg=none

" }}}

" System settings {{{

if has('gui_running')
  " Only in gvim
  if has('gui_win32')
    " Windows font
    set guifont=Consolas:h10
  elseif has('gui_macvim')
    " Mac font + AirLine
    " From https://github.com/Lokaltog/vim-powerline/wiki/Patched-fonts
    set guifont=Inconsolata-dz\ for\ Powerline:h10
    let g:airline_powerline_fonts=1
  else
    " Linux font
    set guifont=Inconsolata\ 9
  end

  " Remove UI
  set guioptions-=T " Tabs
  set guioptions-=l " Left scrollbar
  set guioptions-=L
  set guioptions-=r " Right scrollbar
  set guioptions-=R
else
  " Terminal stuff. If any.
end
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
" Write backups
set nobackup " disable backups
set noswapfile " disable swaps
" Directories for when we need backup/swaps
"set backupdir=~/.config/nvim/tmp/backup " backups
"set directory=~/.config/nvim/tmp/swap " swap files

 "Persistent undo
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
set fileformats=unix,dos,mac

set encoding=utf-8
set nowrap " No wrapping on the right side
set nolinebreak "No linebreak
set tabpagemax=20 " Max possible to open tabs with :tab all
set tabstop=2 " Tabstop size
set cursorline " Highlight screen line where the cursor is
set shiftwidth=2 " Number of spaces for each step of indent
set backspace=2 " Backspacing with all possible indents
set expandtab " Expand tab to spaces by default
set smartindent " Smart indenting when starting a new line
set autoindent " Copy indent from current line when starting a new line
set scrolloff=5 " Keeps the cursor 5 lines from the top or bottom of the screen
set ttimeoutlen=50 " To not pause after leaving insert mode

" Default filetype I'm most comfy with
set filetype=cpp
set syntax=cpp

" More comfortable search
set ignorecase " Ignores the case of the searched item
set smartcase " If contains uppercase letter, make it a case-sensitive search

" Using these two together will use vim hybrid line number mode
set relativenumber " Relative number lines
set number  " Show line in front of each line

set showcmd " Show command in the last line of the screen
set ruler   " Show line, column, etc. at the bottom

set autoread " Enable automatic refresh of files if they have been changed
au FocusGained * :checktime " Force checking of file status on focus

set showmatch " Show matching braces

set mouse=a " Mouse enabled for all modes
set comments=sO:*\ -,mO:*\ \ ,exO:*/,s1:/*,mb:*,ex:*/,bO:///,O://

set guioptions+=a " Autoselect for visual mode
set guioptions+=c " Console dialogs instead of popup dialogs

" We don't want any interruptions
set noerrorbells
set novisualbell

" Highlight search
set hlsearch
" Space to turn off highlighting
nnoremap <silent> <space> :nohlsearch<Bar>:echo<CR>

" Enable incremental commands for more visual feedback
set inccommand=nosplit

" Enable doxygen highlighting for supported files
let g:load_doxygen_syntax=1

" Empty space automatic highlighting
highlight default link EndOfLineSpace ErrorMsg
match EndOfLineSpace / \+$/
autocmd InsertEnter * hi link EndOfLineSpace Normal
autocmd InsertLeave * hi link EndOfLineSpace ErrorMsg

" Highlight VCS conflict markers
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

" Various compilation settings {{{
" Make F5 compile
map <F5> : call CompileGcc()<CR>
func! CompileGcc()
  exec "w"
  exec "!g++ % -o %<"
endfunc

" Make F6 compile and run
map <F6> :call CompileRunGcc()<CR>
func! CompileRunGcc()
  exec "w"
  exec "!g++ % -o %<"
  if has('gui_win32')
    exec "! %<.exe"
  else
    exec "! ./%<"
  endif
endfunc

" Map F7 to make
map <F7> : call CompileMake()<CR>
func! CompileMake()
	exec "make"
endfunc
" }}}

" Because I'm too lazy to type this out everytime
function FormatJson()
  %!python -mjson.tool
endfunction

" Custom Colorcolumn settings
hi colorcolumn ctermbg=red ctermfg=white guibg=#592929
set colorcolumn=81 " Make a colorcolumn for the 81st symbol
set textwidth=80 " Also automatically split at 80

autocmd VimEnter * autocmd WinEnter * let w:created=1
autocmd VimEnter * let w:created=1

" Enable silent ctags compilation
au BufWritePost .c,.cpp,.h silent! :UpdateTags<CR>
"au BufWritePost .c,.cpp,.h silent! call ForceTags()
au! BufRead,BufNewFile *.json set filetype=json
au! BufRead,BufNewFile *.proto set filetype=proto
au! BufRead,BufNewFile *.doxygen set filetype=doxygen

nnoremap <C-F12> :UpdateTags<CR>
"map <C-F12> : call ForceTags()<CR>
"func! ForceTags()
  "exec "!ctags -R --sort=yes --c++-kinds=+pxl --fields=+iaS --extra=+q . &"
"endfunc

" Alt-right/left to navigate forward/backward in the tags stack
map <M-Left> <C-T>
map <M-Right> <C-]>

" Proper tag finding
set tags=./tags;/
set tags+=$VIMRUNTIME/tags/stdcpp

" Some useful bindings for various panes {{{
nnoremap <F2> :NERDTreeToggle<CR>
nnoremap <F3> :TagbarToggle<CR>
nnoremap <F4> :UndotreeToggle<CR>
" }}}

" NerdTree settings
let NERDTreeMinimalUI=1
let NERDTreeDirArrows=1
" Do not display .o, backup files, python compilation files and unity meta files
let NERDTreeIgnore=['\.o$', '\~$', '\.pyc$', '\.meta']
let NERDTreeChDirMode=1
let NERDTreeHijackNetrw=1

" NerdCommenter {{{
map <C-C> <leader>c<space>
map <M-C> <leader>cs
" }}}

" Some completion options {{{
set completeopt=menuone,menu,longest,preview
set pumheight=15 " Max items in the insert mode completion
" automatically open and close the popup menu / preview window
au CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endi

" Fix for quickfix window popping up in taglist.
autocmd! FileType qf wincmd J
" }}}

" Undotree settings
let g:undotree_WindowLayout=3

" Changed split behavior to open splits by default below and on the right
set splitbelow
set splitright

" Stop it, hash key.
inoremap # X<BS>#

" Short startup message
set shortmess+=I

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

" Quickfix window for latest search {{{
nnoremap <silent> <leader>/ :execute 'vimgrep /'.@/.'/g %'<CR>:copen<CR>
nnoremap <silent> <leader>C :copen<CR>
nnoremap <silent> <leader>c :cclose<CR>
" }}}

" Disable annoying keys
nnoremap <F1> <nop>
nnoremap Q <nop>
nnoremap K <nop>

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

" Change tab settings for four-space projects
nnoremap <leader>o :Tabchange<CR>
vnoremap <leader>o :Tabchange<CR>
command -bar Tabchange call ToggleTab()
" helper function to toggle tabbing mode
function ToggleTab()
  set tabstop=4
  set shiftwidth=4
  set softtabstop=4
endfunction

" Easytags settings
let g:easytags_file = '~/.config/nvim/tags/tags'
let g:easytags_dynamic_files=1
let g:easytags_auto_update=0
let g:easytags_auto_highlight=0
let g:easytags_updatetime_min=1000

" Gist Vim settings
let g:gist_open_browser_after_post=1

" YouCompleteMe settings
let g:ycm_confirm_extra_conf = 0

" Lua Vim settings
let g:lua_complete_omni = 0

" Startify settings
let g:startify_change_to_dir = 0  " I define my own dir with .lvimrc

" Airline settings
function! AirlineInit()
  let g:airline_section_z=airline#section#create_right(['%3l/%L:%3c'])
endfunction
autocmd VimEnter * call AirlineInit()
let g:airline_theme='powerlineish'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline_powerline_fonts=1
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
let g:airline_symbols.space = "\ua0"

let g:fzf_files_options = '--depth=10'
let $FZF_DEFAULT_COMMAND = 'ag -l -g "" `git rev-parse --show-toplevel` --silent'
nnoremap <C-P> :FZF %:p:h<CR>

" Ultisnips settings
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"

" Nvim terminal settings
tnoremap <Esc> <C-\><C-n> " Enter normal mode on escape

" Neomake settings
fun! CustomNeo()
  if &ft =~ 'rust'
    Neomake! cargo
  else
    Neomake
  endif
endfun
autocmd! BufWritePost * call CustomNeo()

" Deoplete Settings
let g:deoplete#enable_at_startup=1

" Supertab Settings
let g:SuperTabDefaultCompletionType = "context"
let g:SuperTabContextTextOmniPrecedence=['&omnifunc', '&completefunc']

" Local vimrc settings
let g:localvimrc_ask=0

" Automagically run goimports on save
let g:go_fmt_command = "goimports"

" Better highlighting
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1

" Run lint and vet on save
let g:go_metalinter_autosave = 1

" Go code needs to look standard, so we take a 4 space size for it
autocmd FileType go setlocal shiftwidth=4 tabstop=4

let g:rustfmt_autosave = 1
