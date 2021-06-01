" rob's .vimrc

" Watch for VIMrc changes
augroup myvimrc
	au!
	au BufWritePost init.vim so ~/.config/nvim/init.vim | if has('gui_running') | so ~/.config/nvim/init.vim | endif
augroup END

" Vim-Plug
call plug#begin('~/.config/nvim/plugged')

" General plugins
Plug 'farmergreg/vim-lastplace'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'rob-3/vim-ragtag'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'kabouzeid/nvim-lspinstall'

Plug 'neovim/nvim-lspconfig'

Plug 'lifepillar/vim-solarized8'

Plug 'ap/vim-css-color'

"Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

Plug 'leafOfTree/vim-svelte-plugin'

Plug 'neoclide/coc.nvim', {'branch': 'release'}

Plug 'sheerun/vim-polyglot'

call plug#end()

autocmd FileType python setlocal completeopt-=preview

set updatetime=100
let g:gitgutter_override_sign_column_highlight = 0
highlight SignColumn ctermbg=NONE

" fixes moving with wrapping
nnoremap j gj
nnoremap k gk

" use tabs by default; size equivalent to 4 spaces
set shiftwidth=4
set tabstop=4

" line numbers
set number

" code folding manual only
set foldmethod=syntax
set foldlevelstart=99

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

" automatically attempt to insert appropriate indentation as you go
set smartindent

" Map F5 to remove end of line whitespace
nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

" automatically insert comment characters with 'o' or with return
set fo+=or
" textwidth of 80 by default
set tw=80

nnoremap <Right> ;
nnoremap <Left> ,
nnoremap <Up> <c-y>
nnoremap <Down> <c-e>

" A nice spelling remap
nnoremap <Leader>s :call ToggleSpelling()<CR>

function! ToggleSpelling()
	set spell! spelllang=en
endfunction

let g:solarized_statusline = "low"
" something to do with coloring; not sure what
" TODO test to see what this does
if (has("termguicolors"))
  set termguicolors
endif
colo solarized8_flat

set nowrap

nnoremap <Leader>l :silent !pdflatex -shell-escape % && zathura %<.pdf<CR>

tnoremap <Esc><Esc> <c-\><c-n>

"autocmd BufNewFile,BufRead *.tsx setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab
autocmd FileType typescript setlocal tabstop=4 softtabstop=0 expandtab shiftwidth=4 smarttab
autocmd FileType typescript setlocal completeopt-=preview
autocmd FileType javascript setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab
autocmd FileType html setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab
autocmd FileType css setlocal tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab
autocmd FileType fsharp setlocal tabstop=4 softtabstop=0 expandtab shiftwidth=4 smarttab
set nomodeline

nmap <silent> s <Plug>Ysurround
vmap <silent> s S 

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

autocmd FileType markdown setlocal wrap linebreak tw=0
autocmd FileType javascript setlocal completeopt-=preview
autocmd FileType c setlocal completeopt-=preview
autocmd FileType javascript call RagtagInit()
autocmd Filetype typescript setlocal omnifunc=v:lua.vim.lsp.omnifunc

nnoremap <silent> gd    <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap <silent> <c-]> <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR>
"nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
"nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>
"nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
"nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>

noremap Y y$

autocmd Filetype c setlocal omnifunc=v:lua.vim.lsp.omnifunc
autocmd TermOpen * setlocal nonumber norelativenumber
autocmd Filetype text  setlocal tabstop=8 shiftwidth=8

":lua << EOF
	"local nvim_lsp = require('lspconfig')
	"nvim_lsp.clangd.setup({})
"EOF
	"nvim_lsp.rust_analyzer.setup({})
	"nvim_lsp.tsserver.setup({})
	"nvim_lsp.jdtls.setup({})
	"nvim_lsp.svelte.setup({})

nnoremap <Leader>f :FZF<CR>
nnoremap <Leader><Leader> :Rg<CR>

" coc.nvim configuration

" Give more space for displaying messages.
"set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("nvim-0.5.0") || has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
"xmap <leader>f  <Plug>(coc-format-selected)
"nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
"nmap <silent> <C-s> <Plug>(coc-range-select)
"xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
"command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
"command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
"set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings for CoCList
" Show all diagnostics.
"nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions.
"nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
"nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
"nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
"nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
"nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
"nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
"nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>

" fix enter expansions
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
	\: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
