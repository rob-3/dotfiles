" freespeech's .vimrc

" Omnicomplete
filetype plugin on
set omnifunc=syntaxcomplete#Complete

" Relative line numbers
set relativenumber number

" code folding
set foldmethod=manual

" setting up incsearch
set incsearch
set nohlsearch

" write with sudo trick
cnoremap w!! w !sudo tee > /dev/null %

" Keep at least 2 lines above/below cursor showing
set scrolloff=3

" Do not recognize octal numbers for Ctrl-A and Ctrl-X, most users find it
" confusing.
set nrformats-=octal

" Keep way too much history
set history=500

" Show @@@ in the last line if it is truncated.
set display=truncate

"Better autocomplete
"inoremap <Tab> <c-n>
"inoremap <s-tab> <c-p>

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
" Revert with: ":delcommand DiffOrig".
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif

" Only do this part when compiled with support for autocommands.
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
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
endif " has("autocmd")

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
" Revert with ":iunmap <C-U>".
inoremap <C-U> <C-G>u<C-U>

" show partial commands
set showcmd

" Syntax highlighting
syntax on

" searches case insensitive
set ignorecase

" show mode on bottom
set showmode

" backup files and send all mess files to the same place
set backup		" keep a backup file (restore to previous version)
set backupdir=~/.config/nvim/.neovim_backups
set dir=~/.config/nvim/.neovim_tmp

" The matchit plugin makes the % command work better, but it is not backwards
" compatible.
"if has('syntax') && has('eval')
"  packadd matchit
"endif

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


inoremap " ""<Left>
inoremap (<CR> ()<CR>{<CR>}<C-o>O
inoremap )<CR> )<Space>{<CR>}<C-o>O
inoremap {<CR> {<CR>}<C-o>O
inoremap ;; ();
inoremap {{ {<CR>}<C-o>O
inoremap "" ""<Left>
inoremap (( ()<CR>{<CR>}<Up><Up><Esc>$F(a


nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

let g:python3_host_prog = "/usr/bin/python3"
let g:deoplete#enable_at_startup = 1

inoremap <silent><expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"
inoremap <silent><expr><s-tab> pumvisible() ? "\<c-p>" : "\<s-tab>"
call deoplete#custom#option('ignore_case', v:false)
call deoplete#custom#option('auto_refresh_delay', 1)
call deoplete#custom#option('auto_complete_delay', 0)


"force wrapping in a special way
set tw=0
set wm=0
set nowrap
set fo-=tcwa
nnoremap <Leader>c :call Code()<CR>
function! Code()
	set tw=0
	set nowrap
endfunction

"change to prose settings
nnoremap <Leader>p :call Prose()<CR>
function! Prose()
	set textwidth=80
	set fo=tcwqa
endfunction

"character encoding fix
set encoding=utf-8

nnoremap ; :

set tabstop=4
set shiftwidth=4
set expandtab

nnoremap <Leader>t i [todo: ]<Esc>i
set pastetoggle=<F3>

cnoremap Q q

nnoremap <Leader>s :call ToggleSpelling()<CR>

function! ToggleSpelling()
	set spell! spelllang=en
endfunction

set tabstop=4
set softtabstop=0
set shiftwidth=4
set noexpandtab
set fillchars=vert:\|,fold:-

set runtimepath^=/usr/share/vim/vimfiles
