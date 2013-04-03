" Chaosteils .vimrc

" Initial Setup
set nocompatible
filetype off

" Vundle Settings
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

Bundle 'gmarik/vundle'

Bundle 'Lokaltog/vim-powerline'
Bundle 'MarcWeber/vim-addon-mw-utils'
Bundle 'Valloric/YouCompleteMe'
Bundle 'airblade/vim-gitgutter'
Bundle 'davidhalter/jedi-vim'
Bundle 'derekwyatt/vim-protodef'
Bundle 'garbas/vim-snipmate'
Bundle 'godlygeek/tabular'
Bundle 'gotgenes/vim-yapif'
Bundle 'honza/snipmate-snippets'
Bundle 'kien/ctrlp.vim'
Bundle 'klen/python-mode'
Bundle 'liangfeng/c-syntax'
Bundle 'majutsushi/tagbar'
Bundle 'mattn/gist-vim'
Bundle 'mikewest/vimroom'
Bundle 'myusuf3/numbers.vim'
Bundle 'plasticboy/vim-markdown'
Bundle 'scrooloose/nerdcommenter'
Bundle 'scrooloose/nerdtree'
Bundle 'scrooloose/syntastic'
Bundle 'sjl/gundo.vim'
Bundle 'tomasr/molokai'
Bundle 'tomtom/tlib_vim'
Bundle 'tpope/vim-fugitive'
Bundle 'tpope/vim-obsession'
Bundle 'tpope/vim-surround'
Bundle 'uarun/vim-protobuf'
Bundle 'vim-jp/cpp-vim'
Bundle 'xolox/vim-easytags'

Bundle 'JSON.vim'
Bundle 'a.vim'
Bundle 'google.vim'
Bundle 'localrc.vim'

" Reenable checking of filetypes and filetype indent plugins
filetype plugin indent on

" Colorscheme {{{
" Sets up the specific font and color for individual system settings

syntax on " Enable syntax highlighting
colorscheme molokai " Set up my currently favored colorscheme

" }}}

" System settings {{{

if has('gui_running')
  " Only in gvim
  if has('gui_win32')
    " Windows font
    set guifont=Consolas:h10
  elseif has('gui_macvim')
    " Mac font + Powerline
    " From https://github.com/Lokaltog/vim-powerline/wiki/Patched-fonts
    set guifont=Inconsolata-dz\ for\ Powerline:h10
    let g:Powerline_symbols='fancy'
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

" Nice title!
if has('title') && (has('gui_running') || &title)
    set titlestring=
    set titlestring+=%f " file name
    set titlestring+=%h%m%r%w " flags
    set titlestring+=\ -\ vim " IS THIS REALLY VIM!?
endif

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
"set backupdir=~/.vim/tmp/backup " backups
"set directory=~/.vim/tmp/swap " swap files

" Persistent undo is super cool, but disabled for now
"if has("persistent_undo")
  "set undodir=~/.vim/tmp/undo " undo files
  "set undofile
"endif
" }}}

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

" Default filetype I'm most comfy with
set filetype=cpp
set syntax=cpp

" More comfortable search
set ignorecase " Ignores the case of the searched item
set smartcase " If contains uppercase letter, make it a case-sensitive search

set number  " Show line in front of each line
set showcmd " Show command in the last line of the screen
set ruler   " Show line, column, etc. at the bottom

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
nnoremap <F4> :GundoToggle<CR>
" }}}

" NerdTree settings
let NERDTreeMinimalUI=1
let NERDTreeDirArrows=1
" Do not display .o or backup files
let NERDTreeIgnore=['\.o$', '\~$', '\.pyc$']
let NERDTreeChDirMode=1

" NerdCommenter {{{
map <C-C> <leader>c<space>
map <M-C> <leader>cs
" }}}

" Some completion options
set completeopt=menuone,menu,longest,preview
set pumheight=15 " Max items in the insert mode completion
" automatically open and close the popup menu / preview window
au CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endi

" Fix for quickfix window popping up in taglist.
autocmd! FileType qf wincmd J

" Custom opening of syntastic complete quickfix window
nnoremap <leader>q :cclose<CR>:Errors<CR>
" }}}

" Gundo settings
let g:gundo_right=1

" Jedi Vim settings
let g:jedi#auto_vim_configuration = 0

" SuperTab settings
"let g:SuperTabDefaultCompletionType = "context"

let g:snips_trigger_key = '<C-tab>'

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

" Tabular keybindings
nnoremap <silent> <leader>t= :Tabularize /=<CR>
vnoremap <silent> <leader>t= :Tabularize /=<CR>
nnoremap <silent> <leader>t: :Tabularize /:\zs<CR>
vnoremap <silent> <leader>t: :Tabularize /:\zs<CR>

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

"Sets snipmate author
let g:snips_author="Dominykas Djacenka"

" Easytags settings
let g:easytags_file = '~/.vim/tags/tags'
let g:easytags_dynamic_files=1
let g:easytags_auto_update=0
let g:easytags_auto_highlight=0
let g:easytags_updatetime_min=1000

" Gist Vim settings
let g:gist_open_browser_after_post=1

" YouCompleteMe settings
let g:ycm_confirm_extra_conf = 0
