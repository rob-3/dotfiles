" freespeech's .vimrc

" Watch for VIMrc changes
augroup myvimrc
    au!
    au BufWritePost init.vim so ~/.config/nvim/init.vim | if has('gui_running') | so ~/.config/nvim/init.vim | endif
augroup END

"plugins
call plug#begin('~/.config/nvim/plugged')

Plug 'w0rp/ale'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'flazz/vim-colorschemes'
Plug 'airblade/vim-gitgutter'
""Plug 'altercation/vim-colors-solarized'

call plug#end()

set updatetime=100
let g:gitgutter_override_sign_column_highlight = 0
highlight SignColumn ctermbg=NONE

" remap arrow keys in normal mode to move windows
nnoremap <Up> <c-w>k
nnoremap <Down> <c-w>j
nnoremap <Left> <c-w>h
nnoremap <Right> <c-w>l

" remap <c-direction> to the appropriate window change
nnoremap <c-k> <c-w>k
nnoremap <c-j> <c-w>j
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" remap arrow keys to no-op in insert mode
inoremap <Up> <nop>
inoremap <Down> <nop>
inoremap <Left> <nop>
inoremap <Right> <nop>

" fixes moving with wrapping
nnoremap j gj
nnoremap k gk

" fixes git commit message wrapping
au FileType gitcommit setlocal tw=72

" use tabs by default; size equivalent to 4 spaces
set shiftwidth=4
set smarttab
set tabstop=4

" in the robotics project use 2 spaces instead of tab
autocmd BufNewFile,BufRead ~/robotics/2019Main/* set softtabstop=0 expandtab shiftwidth=2

" Theming
"let g:airline_powerline_fonts = 1
"let g:airline_theme='solarized'
"let g:airline_solarized_bg='dark'

" vim theme
colo solarized8_dark_low

" Omnicomplete
"filetype plugin on
"set omnifunc=syntaxcomplete#Complete

" line numbers
set number
" Relative line numbers
set relativenumber

" code folding manual only
set foldmethod=manual

" setting up highlighting for search
set incsearch

" only highlight the first match
set nohlsearch

" Keep at least 20 lines above/below cursor showing
set scrolloff=20

" Do not recognize octal numbers for Ctrl-A and Ctrl-X, most users find it
" confusing.
set nrformats-=octal

" Keep way too much history
set history=500

" Show @@@ in the last line if it is truncated.
set display=truncate

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
" Revert with: ":delcommand DiffOrig".
"if !exists(":DiffOrig")
"  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
"		  \ | wincmd p | diffthis
"endif

" Only do this part when compiled with support for autocommands.
" TODO check if neovim ever is compiled without autocommands
if has("autocmd")

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  " Revert with ":filetype off".
  filetype plugin indent on

  " Put these in an autocmd group, so that you can revert them with:
  " ":augroup vimStartup | au! | augroup END"
  augroup vimStartup
    au!

    " When editing a file, always jump to the last known cursor position.
    " Don't do it when the position is invalid, when inside an event handler
    " (happens when dropping a file on gvim) and for a commit message (it's
    " likely a different one than last time).
    autocmd BufReadPost *
      \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
      \ |   exe "normal! g`\""
      \ | endif

  augroup END
autocmd FileType * setlocal formatoptions-=c formatoptions+=r formatoptions-=o
endif " has("autocmd")

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
" Revert with ":iunmap <C-U>".
inoremap <C-U> <C-G>u<C-U>

" show partial commands
set showcmd

" Syntax highlighting
"syntax on

" searches case insensitive
"set ignorecase

" show mode on bottom
"set showmode

" backup files and send all mess files to the same place
set backup
set backupdir=~/.config/nvim/.neovim_backups
set dir=~/.config/nvim/.neovim_tmp

"persistent undo
set undofile
set undodir=~/.config/nvim/.neovim_undo
set undolevels=1000
set undoreload=10000

"never split a word
set lbr

"create new line from normal mode with space
nnoremap <Space> o<Esc>

let mapleader=","

" automatically attempt to insert appropriate indentation as you go
set smartindent

" Map F5 to remove end of line whitespace
nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" deoplete config
let g:python3_host_prog = "/usr/bin/python3"
let g:deoplete#enable_at_startup = 1

inoremap <silent><expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"
inoremap <silent><expr><s-tab> pumvisible() ? "\<c-p>" : "\<s-tab>"
call deoplete#custom#option('ignore_case', v:false)
call deoplete#custom#option('auto_refresh_delay', 1)
call deoplete#custom#option('auto_complete_delay', 0)

" automatically insert comment characters with 'o' or with return
set fo+=or
" textwidth of 80 by default
set tw=80
"set wm=80

"character encoding fix
" TODO test to see if this is still needed
set encoding=utf-8

" self-explanatory
nnoremap ; :

" A nice spelling remap
nnoremap <Leader>s :call ToggleSpelling()<CR>

function! ToggleSpelling()
	set spell! spelllang=en
endfunction

" Uses default arch vim plugin directory for sourcing
"set runtimepath^=/usr/share/vim/vimfiles

" something to do with coloring; not sure what
" TODO test to see what this does
"if (has("termguicolors"))
"  set termguicolors
"endif
