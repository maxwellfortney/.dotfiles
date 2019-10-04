set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Place plugins here
Plugin 'tomasiser/vim-code-dark'
Plugin 'tpope/vim-surround'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'airblade/vim-gitgutter'
Plugin 'itchyny/lightline.vim'
Plugin 'itchyny/vim-gitbranch'
Plugin 'tpope/vim-fugitive'
Plugin 'raimondi/delimitmate'
Plugin 'yggdroot/indentline'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

set spell				" Enable spellcheck
set number				" Show number lines
syntax enable			" Enable syntax highlighting
colorscheme codedark	" Set the color scheme
set expandtab
set shiftwidth=4
set tabstop=4			" Set the number of spaces per tab when loading a file
let g:indentLine_enabled = 1
let g:indentLine_color_term = 239
"let g:indentLine_char = '|'
set showcmd				" Show the command bar in the bottom of the screen
set wildmenu			" Visual selection menu for tab completion
set showmatch			" Highlight the matching '('
set incsearch			" Search while charachters are being typed
set hlsearch			" Highlight search matches
nnoremap <silent> <Esc><Esc> <Esc>:nohlsearch<CR><Esc> " Set Esc to also clear search highlighting
nnoremap j gj			" Remap movement keys to move visually instead of literally
nnoremap k gk

" Statusline
set laststatus=2
set noshowmode



let g:lightline = {
      \ 'colorscheme': 'one',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified', 'syntastic' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'fugitive#head'
      \ },
      \ }

" Syntastic checks
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 0 " Don't auto open/close location list
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0
let g:syntastic_mode="passive"
let g:syntastic_enable_signs=1
nnoremap <C-w>E :SyntasticCheck<CR> :lopen<CR>


" air-line
let g:airline_powerline_fonts = 1

if !exists('g:airline_symbols')
	let g:airline_symbols = {}
endif

" Unicode Symbols
let g:airline_left_sep = '»'
let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = '∥'
let g:airline_symbols.whitespace = 'Ξ'

" Airline Symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ''
