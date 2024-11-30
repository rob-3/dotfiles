vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set("n", "<Leader>s", function()
  vim.opt.spell = not vim.opt.spell:get()
end)
--vim.keymap.set("n", "<leader>ca", ":CodeActionMenu<CR>", {silent=true})
--vim.keymap.set("i", "<C-l>", "copilot#Accept()", { silent=true, expr=true, nowait=true, script=true })
--vim.cmd("imap <script><silent><nowait><expr> <C-l> copilot#Accept()")
--vim.keymap.set("i", "<M-j>", "copilot#Next()", { silent=true, expr=true, nowait=true, script=true })
--vim.keymap.set("i", "<M-k>", "copilot#Previous()", { silent=true, expr=true, nowait=true, script=true })
--vim.keymap.set("n", "'", "`")
--vim.keymap.set("n", "`", "'")
--vim.cmd("inoremap <expr> <A-l> copilot#Accept() . \"\\<Esc>\"")
vim.keymap.set('n', ']q', ':cn<cr>', { silent = true })
vim.keymap.set('n', '[q', ':cp<cr>', { silent = true })

vim.wo.number = true
vim.g.netrw_banner = false
vim.opt.termguicolors = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.scrolloff = 5
vim.opt.history = 500
vim.opt.display = "truncate"
vim.opt.updatetime = 100
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.backup = true
vim.opt.backupdir = vim.fn.expand("~/.config/nvim/.neovim_backups")
vim.opt.dir = vim.fn.expand("~/.config/nvim/.neovim_tmp")
vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand("~/.config/nvim/.neovim_undo")
vim.opt.modeline = false
vim.opt.wrap = false
vim.opt.signcolumn = "auto"
vim.opt.lbr = true
vim.opt.smartindent = true
vim.opt.formatoptions:append({ "o", "r" })
--vim.opt.textwidth = 80
vim.opt.lcs:append({ space = "·" })
--vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
--vim.opt.foldtext = "v:lua.vim.treesitter.foldtext()"
vim.opt.completeopt = { "menu" }

local function is_file_small(file)
  file = file or "%"
  local file_size = vim.api.nvim_call_function("getfsize", { vim.fn.expand(file) })
  return file_size < 256 * 1024
end

local is_small = is_file_small()

if not is_small then
  vim.api.nvim_command("syntax off")
end

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

vim.g["conjure#log#hud#enabled"] = false
vim.g["conjure#mapping#doc_word"] = ""
vim.g["conjure#mapping#def_word"] = ""

vim.cmd("let g:matchup_matchparen_offscreen = { 'method': '' }")
vim.cmd("let g:disable_virtual_text = 1")

require("lazy").setup({
  {"folke/tokyonight.nvim",
    config = function()
      require("tokyonight").setup({
        on_highlights = function (hl, c)
          hl.EndOfBuffer = {
            fg = c.dark3
          }
        end
      })
      vim.cmd.colorscheme("tokyonight-storm")
    end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    --commit="42acc3f6e778dd6eb6e0e92690c7d56eab859b6a",
    build = function()
      local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
      ts_update()
    end,
    config=function()
      -- treesitter
      require("nvim-treesitter.configs").setup {
        -- A list of parser names, or "all"
        ensure_installed = {
          "lua",
          "javascript",
          "typescript",
          "svelte",
          "html",
          "markdown",
          "markdown_inline",
          "python",
        },

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
          disable = function(_, bufnr)
            if vim.api.nvim_buf_get_option(bufnr, "filetype") == "gitcommit" then
              return false
            end
            local buf_name = vim.api.nvim_buf_get_name(bufnr)
            local file_size = vim.api.nvim_call_function("getfsize", { buf_name })
            return file_size > 256 * 1024
          end,

          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on "syntax" being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          additional_vim_regex_highlighting = {"gitcommit", "markdown"},
        },
        indent = {
          enable = true,
          disable = { "python" }
        },
        matchup = {
          enable = true,
          disable_virtual_text = true,
        },
      }
    end
  },
  "Olical/conjure",
--  {
--    "gpanders/nvim-parinfer",
--    config = function ()
--      vim.keymap.set('n', '<F5>', '<cmd>ParinferToggle<cr>', opts)
--    end
--  },
  {"eraserhd/parinfer-rust",
    build = "nix-shell --run \"cargo build --release\""
  },
  "tpope/vim-fugitive",
  "farmergreg/vim-lastplace",
  {"kylechui/nvim-surround",
    config = function()
      require("nvim-surround").setup({})
    end
  },
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    opts = function()
      --- @type Gitsigns.Config
      local C = {
        on_attach = function(buffer)
          local gs = package.loaded.gitsigns
          local function map(mode, l, r, desc)
            vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
          end
          map("n", "]g", gs.next_hunk, "Next Hunk")
          map("n", "[g", gs.prev_hunk, "Prev Hunk")
        end,
      }
      return C
    end,
  },
  "nvchad/nvim-colorizer.lua",
  {"NMAC427/guess-indent.nvim",
    config = function()
      require('guess-indent').setup {
        filetype_exclude = {
          --"clojure"
        }
      }
    end
  },

  -- new stuff
  -- LSP Support
  'neovim/nvim-lspconfig',
  'williamboman/mason.nvim',
  'williamboman/mason-lspconfig.nvim',

  "andymass/vim-matchup",
  {
    'ibhagwan/fzf-lua',
    config = function()
      require("fzf-lua").setup {
        winopts = {
          border = false,
          fullscreen = true,
          preview = {
            default = "bat",
            border = "noborder",
          },
        },
        grep = {
          rg_opts = "--glob '!.git/' --hidden --column --line-number --no-heading --color=always --smart-case --max-columns=4096 -F -e"
        },
        oldfiles = {
          include_current_session = true
        }
      }

      vim.keymap.set("n", "<leader>f", "<cmd>lua require('fzf-lua').files({ cmd = vim.env.FZF_DEFAULT_COMMAND, include_current_session = true })<CR>", { noremap = true, silent = true })
      --vim.keymap.set("n", "<leader>g", "<cmd>lua require('fzf-lua').grep_project()<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>g", "<cmd>lua require('fzf-lua').live_grep_native()<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>p", "<cmd>lua require('fzf-lua').oldfiles()<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>c", "<cmd>lua require('fzf-lua').commands()<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>i", "<cmd>lua require('fzf-lua').git_files()<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>a", "<cmd>lua require('fzf-lua').lsp_code_actions({ winopts = { border = true, fullscreen = false, height = 0.85, width = 0.8, preview = { default = 'bat' } } })<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>m", "<cmd>lua require('fzf-lua').git_status()<CR>", { noremap = true, silent = true })
    end
  },
  -- lazy.nvim
  {
    "Robitx/gp.nvim",
    config = function()
      local API_KEYS = require("rob-3.secrets")
      require("gp").setup({
        providers = {
          openai = {
            endpoint = "https://api.openai.com/v1/chat/completions",
            secret = API_KEYS.OPENAI_API_KEY
          },
          anthropic = {
            endpoint = "https://api.anthropic.com/v1/messages",
            secret = API_KEYS.ANTHROPIC_API_KEY
          }
        },
        agents = {
          {
            name = "ConciseClaude",
            provider = "anthropic",
            chat = true,
            command = false,
            -- string with model name or table with model name and parameters
            model = { model = "claude-3-5-sonnet-latest", temperature = 0.7, top_p = 1 },
            -- system prompt (use this to specify the persona/role of the AI)
            system_prompt = "You are a pleasant, clever AI assistant with a dry sense of "
              .. "humor.\n\n"
              .. "The user provided the additional info about how they would like you to respond:\n\n"
              --.. "- If there's a good chance, use a short and clever response.\n"
              .. "- I am an expert and don't require detailed explanations. Be brutally direct.\n"
              .. "- Be confident, but if you're unsure don't guess and say you don't know instead.\n"
              --.. "- Feel free to speculate, but mention if you are speculating.\n"
              .. "- Ask questions if you need clarification to provide better answer.\n"
              --.. "- Think deeply and carefully from first principles step by step.\n"
              --.. "- Zoom out first to see the big picture and then zoom in to details.\n"
              --.. "- Use Socratic method to improve your thinking and coding skills.\n"
              .. "- Don't elide any code from your output if the answer requires coding.\n"
              .. "- For simple questions, a response with only code or a command is perfect.\n"
              .. "- Please be concise and favor keeping your response short.\n"
              .. "- Take a deep breath; You've got this!\n",
          },
          {
            name = "ConciseGPT4",
            chat = true,
            command = false,
            -- string with model name or table with model name and parameters
            model = { model = "gpt-4o", temperature = 1.1, top_p = 1 },
            -- system prompt (use this to specify the persona/role of the AI)
            system_prompt = "You are a pleasant, clever AI assistant with a dry sense of "
              .. "humor.\n\n"
              .. "The user provided the additional info about how they would like you to respond:\n\n"
              --.. "- If there's a good chance, use a short and clever response.\n"
              .. "- I am an expert and don't require detailed explanations. Be brutally direct.\n"
              .. "- Be confident, but if you're unsure don't guess and say you don't know instead.\n"
              --.. "- Feel free to speculate, but mention if you are speculating.\n"
              .. "- Ask questions if you need clarification to provide better answer.\n"
              --.. "- Think deeply and carefully from first principles step by step.\n"
              --.. "- Zoom out first to see the big picture and then zoom in to details.\n"
              --.. "- Use Socratic method to improve your thinking and coding skills.\n"
              .. "- Don't elide any code from your output if the answer requires coding.\n"
              .. "- For simple questions, a response with only code or a command is perfect.\n"
              .. "- Please be concise and favor keeping your response short.\n"
              .. "- Take a deep breath; You've got this!\n",
          },
          {
            name = "ChatGPT4",
            chat = true,
            command = false,
            -- string with model name or table with model name and parameters
            model = { model = "gpt-4o", temperature = 1.1, top_p = 1 },
            -- system prompt (use this to specify the persona/role of the AI)
            system_prompt = "You are a pleasant, clever AI assistant with a dry, subtle sense of "
              .. "callback humor, but you have a deep, cosmopolitan intelligence under the surface.\n\n"
              .. "The user provided the additional info about how they would like you to respond:\n\n"
              --.. "- If there's a good chance, use a short and clever response.\n"
              .. "- I am an expert and don't require detailed explanations. Be brutally direct.\n"
              .. "- Be confident, but if you're unsure don't guess and say you don't know instead.\n"
              --.. "- Feel free to speculate, but mention if you are speculating.\n"
              .. "- Ask questions if you need clarification to provide better answer.\n"
              --.. "- Think deeply and carefully from first principles step by step.\n"
              --.. "- Zoom out first to see the big picture and then zoom in to details.\n"
              --.. "- Use Socratic method to improve your thinking and coding skills.\n"
              .. "- Don't elide any code from your output if the answer requires coding.\n"
              .. "- For simple questions, a response with only code or a command is perfect.\n"
              .. "- Please be concise and favor keeping your response short.\n"
              .. "- Take a deep breath; You've got this!\n",
          },
          { name = "ChatGPT3-5", disable = true },
          {
            name = "CodeGPT4",
            chat = false,
            command = true,
            -- string with model name or table with model name and parameters
            model = { model = "gpt-4o", temperature = 0.8, top_p = 1 },
            -- system prompt (use this to specify the persona/role of the AI)
            system_prompt = "You are an AI working as a code editor.\n\n"
              .. "Please AVOID COMMENTARY OUTSIDE OF THE SNIPPET RESPONSE.\n"
              .. "START AND END YOUR ANSWER WITH:\n\n```",
          },
          { name = "CodeGPT3-5", disable = true },
        },
      })

      -- or setup with your own config (see Install > Configuration in Readme)
      -- require("gp").setup(config)

      -- shortcuts might be setup here (see Usage > Shortcuts in Readme)
      local function keymapOptions(desc)
        return {
          noremap = true,
          silent = true,
          nowait = true,
          desc = "GPT prompt " .. desc,
        }
      end
      vim.keymap.set("v", "<leader>r", ":<C-u>'<,'>GpRewrite<cr>", keymapOptions("Visual Rewrite"))
      vim.keymap.set("v", "<leader>a", ":<C-u>'<,'>GpAppend<cr>", keymapOptions("Visual Append (after)"))
      vim.keymap.set("v", "<leader>p", ":<C-u>'<,'>GpPrepend<cr>", keymapOptions("Visual Prepend (before)"))
      --vim.keymap.set("v", "<leader><leader>", ":<C-u>'<,'>GpChatNew tabnew<cr>", keymapOptions("Visual Chat tabnew"))
      --vim.keymap.set("n", "<leader><leader>", "<cmd>GpChatNew<cr>", keymapOptions("New Chat tabnew"))
      --vim.keymap.set("v", "<leader>c", ":<C-u>'<,'>GpVnew<cr>", keymapOptions("Visual Chat New vsplit"))
    end,
  }
},
  {
    git = {
      timeout = 600,
    },
    ui = {
      icons = {
        cmd = "⌘",
        config = "🛠",
        event = "📅",
        ft = "📂",
        init = "⚙",
        keys = "🗝",
        plugin = "🔌",
        runtime = "💻",
        source = "📄",
        start = "🚀",
        task = "📌",
        lazy = "💤 ",
      },
    },
})

--require('lspconfig').ruff_lsp.setup {
--  init_options = {
--    settings = {
--      -- Any extra CLI arguments for `ruff` go here.
--      args = {},
--    }
--  }
--}

require('lspconfig').nil_ls.setup {
  autostart = true,
  capabilities = caps,
  cmd = { "nil" },
  settings = {
    ['nil'] = {
      testSetting = 42,
      formatting = {
        command = { "nixpkgs-fmt" },
      },
    },
  },
}

require('lspconfig').ts_ls.setup {}

---- note: diagnostics are not exclusive to lsp servers
-- so these can be global keybindings
vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>')
vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev({ float = false })<cr>')
vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next({ float = false })<cr>') 

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(event)
    --local client = vim.lsp.get_client_by_id(event.data.client_id)
    --if client.server_capabilities.inlayHintProvider then
    --  vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
    --end
    --local opts = {buffer = event.buf}

    -- these will be buffer-local keybindings
    -- because they only work if you have an active language server

    vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
    vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
    vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
    --vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
    vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
    --vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
    vim.keymap.set('n', 'grr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
    vim.keymap.set('i', '<c-s>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
    vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
    --vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
    vim.keymap.set('n', 'grn', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
    vim.keymap.set({'n', 'x'}, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
    vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
  end
})

--local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()

local default_setup = function(server)
  -- graciously adapted from nvim-cmp
  -- https://github.com/hrsh7th/cmp-nvim-lsp/blob/main/lua/cmp_nvim_lsp/init.lua
  override = {}
  local if_nil = function(val, default)
    if val == nil then return default end
    return val
  end
  if server == "tsserver" then 
    return
  end
  require('lspconfig')[server].setup({
    capabilities = {
      textDocument = {
        completion = {
          dynamicRegistration = if_nil(override.dynamicRegistration, false),
          completionItem = {
            snippetSupport = if_nil(override.snippetSupport, true),
            commitCharactersSupport = if_nil(override.commitCharactersSupport, true),
            deprecatedSupport = if_nil(override.deprecatedSupport, true),
            preselectSupport = if_nil(override.preselectSupport, true),
            tagSupport = if_nil(override.tagSupport, {
              valueSet = {
                1, -- Deprecated
              }
            }),
            insertReplaceSupport = if_nil(override.insertReplaceSupport, true),
            resolveSupport = if_nil(override.resolveSupport, {
              properties = {
                "documentation",
                "detail",
                "additionalTextEdits",
                "sortText",
                "filterText",
                "insertText",
                "textEdit",
                "insertTextFormat",
                "insertTextMode",
              },
            }),
            insertTextModeSupport = if_nil(override.insertTextModeSupport, {
              valueSet = {
                1, -- asIs
                2, -- adjustIndentation
              }
            }),
            labelDetailsSupport = if_nil(override.labelDetailsSupport, true),
          },
          contextSupport = if_nil(override.snippetSupport, true),
          insertTextMode = if_nil(override.insertTextMode, 1),
          completionList = if_nil(override.completionList, {
            itemDefaults = {
              'commitCharacters',
              'editRange',
              'insertTextFormat',
              'insertTextMode',
              'data',
            }
          })
        },
      },
    }
  })
end

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {},
  handlers = {
    default_setup,
  },
})

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
  vim.lsp.handlers.hover,
  {border = 'rounded'}
)

vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
  vim.lsp.handlers.signature_help,
  {border = 'rounded'}
)

vim.diagnostic.config({
  float = {
    border = 'rounded',
    header = '',
    prefix = '',
    source = 'if_many'
  },
  virtual_text = true,
  signs = false,
  --update_in_insert = true,
  underline = true,
  severity_sort = false,
})

-- nvim-surround
require("colorizer").setup()

-- latex
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  pattern = { "*.tex" },
  callback = function()
    vim.cmd(":call jobstart(['pdflatex', expand('%')])")
  end
})
--vim.api.nvim_create_user_command("Format", function() vim.lsp.buf.format() end, {})

vim.opt.mouse = ""

require("colorizer").setup({
  user_default_options = {
    mode = "background",
    tailwind = true,
    css = true,
    always_update = true,
  },
})

vim.api.nvim_create_autocmd({ "BufReadPre" }, {
  callback = function()
    if not is_file_small(vim.fn.expand("<afile>")) then
      vim.cmd("setlocal syntax=off")
      vim.cmd("TSBufDisable highlight")
    end
  end
})

vim.o.fixeol = false

-- set mdx filetype
vim.api.nvim_create_autocmd({ "BufReadPre" }, {
  pattern = { "*.mdx" },
  callback = function()
    vim.cmd("setlocal filetype=mdx")
  end
})

--vim.keymap.set('n', '<F5>', function() require('dap').continue() end)
--vim.keymap.set('n', '<F10>', function() require('dap').step_over() end)
--vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
--vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
--vim.keymap.set('n', '<Leader>b', function() require('dap').toggle_breakpoint() end)
--vim.keymap.set('n', '<Leader>B', function() require('dap').set_breakpoint() end)
--vim.keymap.set('n', '<Leader>lp', function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
--vim.keymap.set('n', '<Leader>dr', function() require('dap').repl.open() end)
--vim.keymap.set('n', '<Leader>dl', function() require('dap').run_last() end)
--vim.keymap.set({'n', 'v'}, '<Leader>dh', function()
--  require('dap.ui.widgets').hover()
--end)
--vim.keymap.set({'n', 'v'}, '<Leader>dp', function()
--  require('dap.ui.widgets').preview()
--end)
--vim.keymap.set('n', '<Leader>df', function()
--  local widgets = require('dap.ui.widgets')
--  widgets.centered_float(widgets.frames)
--end)
--vim.keymap.set('n', '<Leader>ds', function()
--  local widgets = require('dap.ui.widgets')
--  widgets.centered_float(widgets.scopes)
--end)

vim.cmd("set clipboard+=unnamedplus")

-- function to flip on gj and gk
vim.keymap.set("n", "j", "v:count ? 'j' : 'gj'", { expr = true, noremap = true })
vim.keymap.set("n", "k", "v:count ? 'k' : 'gk'", { expr = true, noremap = true })

--vim.cmd("filetype indent off")
--vim.cmd("autocmd BufRead,BufNewFile *.cljc lua vim.diagnostic.disable(0)")

vim.cmd([[cnoremap <expr> <C-P> wildmenumode() ? "\<C-P>" : "\<Up>"]])
vim.cmd([[cnoremap <expr> <C-N> wildmenumode() ? "\<C-N>" : "\<Down>"]])

vim.cmd("omap ]] <Plug>(matchup-]%)")
vim.cmd("omap [[ <Plug>(matchup-[%)")
vim.cmd("nmap ]] <Plug>(matchup-]%)")
vim.cmd("nmap [[ <Plug>(matchup-[%)")
vim.cmd("xmap ]] <Plug>(matchup-]%)")
vim.cmd("xmap [[ <Plug>(matchup-[%)")
