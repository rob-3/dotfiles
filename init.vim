" freespeech's .vimrc

" Watch for VIMrc changes
augroup myvimrc
	au!
	au BufWritePost init.vim so ~/.config/nvim/init.vim | if has('gui_running') | so ~/.config/nvim/init.vim | endif
augroup END

"plugins
call plug#begin('~/.config/nvim/plugged')

Plug 'w0rp/ale'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'airblade/vim-gitgutter'
Plug 'Shougo/deoplete.nvim'
Plug 'tpope/vim-obsession'
Plug 'rstacruz/vim-closer'

Plug 'deoplete-plugins/deoplete-jedi'

" Vim-Plug
Plug 'HerringtonDarkholme/yats.vim'
Plug 'mhartington/nvim-typescript', {'do': './install.sh'}

Plug 'tpope/vim-ragtag'

Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'

call plug#end()

"imap <c-space> <c-x><Space>

let g:ale_fixers = {
\   'javascript': ['prettier'],
\   'css': ['prettier'],
\}
let g:ale_fix_on_save = 1
let g:ale_javascript_prettier_options = '--backtick-quote --trailing-comma'

autocmd FileType python setlocal completeopt-=preview
"set completeopt+=noinsert

set updatetime=100
let g:gitgutter_override_sign_column_highlight = 0
highlight SignColumn ctermbg=NONE


" remap <c-direction> to the appropriate window change
nnoremap <c-k> <c-w>k
nnoremap <c-j> <c-w>j
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" fixes moving with wrapping
nnoremap j gj
nnoremap k gk

" fixes git commit message wrapping
au FileType gitcommit setlocal tw=72 shiftwidth=4 smarttab tabstop=4

" use tabs by default; size equivalent to 4 spaces
set shiftwidth=4
set tabstop=4

" vim theme
colo transparent

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
set scrolloff=5

" Keep way too much history
set history=500

" Show @@@ in the last line if it is truncated.
set display=truncate

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
	  \ |	exe "normal! g`\""
	  \ | endif

  augroup END
"autocmd FileType * setlocal formatoptions-=c formatoptions+=r formatoptions+=o
endif " has("autocmd")

" CTRL-U in insert mode deletes a lot.	Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
" Revert with ":iunmap <C-U>".
inoremap <C-U> <C-G>u<C-U>

" show partial commands
set showcmd

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
"nnoremap <Space> <c-x>
nnoremap <c-n> o<Esc>
nnoremap <c-p> O<Esc>

" automatically attempt to insert appropriate indentation as you go
set smartindent

" Map F5 to remove end of line whitespace
nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" deoplete config
let g:deoplete#enable_at_startup = 1
" use langauge server completions from ale
call deoplete#custom#option('sources', {
\ '_': [],
\})

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
noremap ; :
noremap : ;
nnoremap <Right> ;
nnoremap <Left> ,
nnoremap <Up> ;
nnoremap <Down> ,

" A nice spelling remap
nnoremap <Leader>s :call ToggleSpelling()<CR>

function! ToggleSpelling()
	set spell! spelllang=en
endfunction

" something to do with coloring; not sure what
" TODO test to see what this does
if (has("termguicolors"))
  set termguicolors
endif

set wrap

nnoremap <Leader><Leader> "0p
nnoremap <Leader>p :term python %<CR>i
nnoremap <Leader>m :r !./tools/mission-codename<CR>kJE
nnoremap <Leader>c :!g++ % -o $(basename % .cpp) && ./$(basename % .cpp)<CR>

tnoremap <Esc><Esc> <c-\><c-n>

autocmd FileType typescript setlocal tabstop=4 softtabstop=0 expandtab shiftwidth=4 smarttab
autocmd FileType typescript setlocal completeopt-=preview
autocmd FileType javascript setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab
autocmd FileType css setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab
set nomodeline

nnoremap <c-d> i<c-d>
nmap s <Plug>Ysurround
vmap s S 

nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

inoremap <c-space> <nop>

nnoremap <Leader>a :ALEToggle<CR>
inoremap <c-o> <nop>

function! CreateBox()
	normal! I│
	normal! A│
	let wordLength = strwidth(getline('.')) - 2
	let counter = 0
	let pastestring = ''
	while counter < wordLength
		let counter += 1
		let pastestring .= '─'
	endwhile
	normal! O
	call setline('.', '┌'.pastestring.'┐')
	normal! jo
	call setline('.', '└'.pastestring.'┘')
endfunction
nnoremap <silent> <Leader>b :call CreateBox()<CR>
function! UnBox()
	normal! dd
	call setline('.', getline('.')[3:-4])
	normal! jdd
endfunction
nnoremap <silent> <Leader>u :call UnBox()<CR>
