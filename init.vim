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
Plug 'kylechui/nvim-surround'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

Plug 'rob-3/vim-solarized8'

Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' }

"Plug 'github/copilot.vim'

Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.0' }
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' }

Plug 'NMAC427/guess-indent.nvim'

" LSP Support
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/nvim-lsp-installer'

" Autocompletion
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-nvim-lua'

" Snippets
Plug 'L3MON4D3/LuaSnip'
Plug 'rafamadriz/friendly-snippets'

Plug 'VonHeikemen/lsp-zero.nvim'

" AutoPairs
Plug 'windwp/nvim-autopairs'

Plug 'weilbith/nvim-code-action-menu'

call plug#end()

nnoremap <leader>f <cmd>Telescope find_files<cr>
"nnoremap <leader><leader> <cmd>Telescope find_files<cr>
nnoremap <leader>g <cmd>Telescope live_grep<cr>
nnoremap <leader>p <cmd>Telescope buffers<cr>
"nnoremap <leader>fh <cmd>Telescope help_tags<cr>

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
"inoremap <C-U> <C-G>u<C-U>

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

"nnoremap <Right> ;
"nnoremap <Left> ,
"nnoremap <Up> <c-y>
"nnoremap <Down> <c-e>

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

if $THEME
	set bg=light
endif

set nowrap

autocmd BufWritePost *.tex :call jobstart(['pdflatex', expand('%')])
set nomodeline

noremap Y y$

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

set signcolumn=number

"set list
"set listchars=tab:»·,nbsp:·,trail:·

map <C-c> <Nop>

"let g:netrw_banner = 0

:lua << EOF
	local lsp = require('lsp-zero')
	lsp.preset('lsp-compe')
	lsp.setup()

	local cmp = require('cmp')
	local cmp_config = lsp.defaults.cmp_config()
    cmp_config.mapping['<C-p>'] = cmp.mapping.select_prev_item(select_opts)
    cmp_config.mapping['<C-n>'] = cmp.mapping.select_next_item(select_opts)
    cmp_config.mapping['<C-Space>'] = cmp.mapping.complete()
    cmp_config.mapping['<C-l>'] = cmp.mapping.confirm()
	cmp_config.experimental = { ghost_text = true }
	cmp_config.sources = {
		{ name = 'path' },
		{ name = 'nvim_lsp', keyword_length = 1 },
		{ name = 'buffer', keyword_length = 1 },
		{ name = 'luasnip', keyword_length = 2 },
	}
	cmp.setup(cmp_config)

	require('nvim-surround').setup({})

	require('guess-indent').setup()

	local npairs = require'nvim-autopairs'
	npairs.setup({
		check_ts = true,
	})
	local Rule = require'nvim-autopairs.rule'
	npairs.add_rule(Rule("`", "`"))
	local cmp_autopairs = require('nvim-autopairs.completion.cmp')
	local cmp = require('cmp')
	cmp.event:on(
		'confirm_done',
		cmp_autopairs.on_confirm_done()
	)

	require'nvim-treesitter.configs'.setup {
		-- A list of parser names, or "all"
		ensure_installed = {},

		-- Install parsers synchronously (only applied to `ensure_installed`)
		sync_install = false,

		-- Automatically install missing parsers when entering buffer
		auto_install = true,

		-- List of parsers to ignore installing (for "all")
		ignore_install = {},

		highlight = {
			-- `false` will disable the whole extension
			enable = true,

			-- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
			-- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
			-- the name of the parser)
			-- list of language that will be disabled
			disable = {},

			-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
			-- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
			-- Using this option may slow down your editor, and you may see some duplicate highlights.
			-- Instead of true it can also be a list of languages
			additional_vim_regex_highlighting = false,
		},
		indent = {
			enable = true
		},
	}
EOF

set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
set foldlevel=99

let g:code_action_menu_show_details = v:false
let g:code_action_menu_show_diff = v:false
"nnoremap <silent> <leader>ca :CodeActionMenu<cr>
nnoremap <silent> <leader><leader> :CodeActionMenu<cr>
