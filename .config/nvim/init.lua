vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set("n", "<Leader>s", function()
  vim.opt.spell = not vim.opt.spell:get()
end)

vim.wo.number = true
vim.g.netrw_banner = false
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.scrolloff = 5
vim.opt.history = 500
vim.opt.display = "truncate"
vim.opt.updatetime = 100
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.backup = true
vim.opt.backupdir = vim.fn.expand("~/.local/state/nvim/backup//")
vim.opt.undofile = true
vim.opt.modeline = false
vim.opt.wrap = false
vim.opt.signcolumn = "auto"
vim.opt.lbr = true
vim.opt.smartindent = true
vim.opt.formatoptions:append({ "o", "r" })
vim.opt.lcs:append({ space = "·" })
vim.opt.completeopt = { "fuzzy", "menu" }
vim.cmd.colorscheme("habamax")

local function is_file_small(file)
  file = file or "%"
  local file_size = vim.api.nvim_call_function("getfsize", { vim.fn.expand(file) })
  return file_size < 256 * 1024
end

vim.api.nvim_create_autocmd({ "BufReadPre" }, {
  callback = function()
    if not is_file_small(vim.fn.expand("<afile>")) then
      vim.cmd("setlocal syntax=off")
      vim.cmd("TSBufDisable highlight")
    end
  end
})

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

vim.g.matchup_matchparen_offscreen = { method = "" }
vim.g.disable_virtual_text = 1

require("lazy").setup({
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
  {"Olical/conjure",
    config = function()
      --vim.keymap.set("n", "<leader><leader>", ":ConjureEvalCurrentForm<cr>", { silent = true })
    end
  },
  {"eraserhd/parinfer-rust",
    build = "nix build && mkdir -p ./target/ && ln -sfn ../result/lib ./target/release",
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
    event = "VeryLazy",
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

      vim.keymap.set("n", "<leader>f", "<cmd>lua require('fzf-lua').files({ cmd = vim.env.FZF_DEFAULT_COMMAND, include_current_session = true, silent = true })<CR>", { noremap = true, silent = true })
      --vim.keymap.set("n", "<leader>g", "<cmd>lua require('fzf-lua').grep_project()<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>g", "<cmd>lua require('fzf-lua').live_grep_native()<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>p", "<cmd>lua require('fzf-lua').oldfiles()<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>c", "<cmd>lua require('fzf-lua').commands()<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>i", "<cmd>lua require('fzf-lua').git_files({ silent = true })<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>a", "<cmd>lua require('fzf-lua').lsp_code_actions({ winopts = { border = true, fullscreen = false, height = 0.85, width = 0.8, preview = { default = 'bat' } } })<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>m", "<cmd>lua require('fzf-lua').git_status()<CR>", { noremap = true, silent = true })

      vim.cmd(":FzfLua register_ui_select")
    end
  },
  -- lazy.nvim
  {
    "Robitx/gp.nvim",
    config = function()
      local system_prompt = 
        "You are a pleasant, clever AI assistant with a dry sense of humor.\n\n"
        .. "The user provided the additional info about how they would like you to respond:\n\n"
        .. "- I am an expert and don't require detailed explanations. Be brutally direct.\n"
        .. "- Be confident, but if you're unsure don't guess and say you don't know instead.\n"
        .. "- Ask questions if you need clarification to provide better answer.\n"
        .. "- Don't elide any code from your output if the answer requires coding.\n"
        .. "- For simple questions, a response with only code or a command is perfect.\n"
        .. "- Please be concise and favor keeping your response short.\n"
        .. "- Take a deep breath; You've got this!\n"
      require("gp").setup({
        providers = {
          anthropic = { disable = false },
          googleai = { disable = false }
        },
        agents = {
          {
            name = "ConciseClaude",
            provider = "anthropic",
            chat = true,
            command = false,
            model = { model = "claude-3-7-sonnet-20250219", temperature = 0.7, top_p = 1 },
            system_prompt = system_prompt
          },
          {
            name = "ConciseGPT4",
            chat = true,
            command = false,
            model = { model = "gpt-4o", temperature = 1.1, top_p = 1 },
            system_prompt = system_prompt
          },
          {
            name = "ConciseGemini",
            provider = "googleai",
            chat = true,
            command = false,
 			      model = { model = "gemini-2.5-pro-preview-05-06", temperature = 1.1, top_p = 1 }, 
            system_prompt = system_prompt
          },
          {
            name = "ChatGPT4",
            chat = true,
            command = false,
            model = { model = "gpt-4o", temperature = 1.1, top_p = 1 },
            system_prompt = system_prompt
          },
          {
            name = "CodeGPT4",
            chat = false,
            command = true,
            model = { model = "gpt-4o", temperature = 0.8, top_p = 1 },
            system_prompt = "You are an AI working as a code editor.\n\n"
              .. "Please AVOID COMMENTARY OUTSIDE OF THE SNIPPET RESPONSE.\n"
              .. "START AND END YOUR ANSWER WITH:\n\n```",
          },
        },
      })

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
})

require('lspconfig').nil_ls.setup {
  autostart = true,
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
require('lspconfig').clojure_lsp.setup {}
require('lspconfig').pyright.setup {}
require('lspconfig').rust_analyzer.setup {}
require('lspconfig').bashls.setup {}
require('lspconfig').clangd.setup {}
require('lspconfig').jdtls.setup {}
require('lspconfig').html.setup {}
require('lspconfig').cssls.setup {}
require('lspconfig').jsonls.setup {}
require('lspconfig').zls.setup {}
require('lspconfig').mdx_analyzer.setup {}
require('lspconfig').lemminx.setup{}
require('lspconfig').yamlls.setup{}

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(event)
    vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>')
    vim.keymap.set({'n', 'x'}, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>')
  end
})

local diagnostic_config = {
  signs = false,
  virtual_lines = false,
  virtual_text = true,
  underline = true,
  severity_sort = false,
}
vim.diagnostic.config(diagnostic_config)
vim.keymap.set('n', 'gl', function()
  if vim.diagnostic.config().virtual_lines then
    vim.diagnostic.config(diagnostic_config)
  else
    vim.diagnostic.config({ virtual_lines = { current_line = true }, virtual_text = false })
  end
end)

-- latex
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  pattern = { "*.tex" },
  callback = function()
    vim.cmd(":call jobstart(['pdflatex', expand('%')])")
  end
})

vim.opt.mouse = ""

vim.o.fixeol = false

-- set mdx filetype
vim.api.nvim_create_autocmd({ "BufReadPre" }, {
  pattern = { "*.mdx" },
  callback = function()
    vim.cmd("setlocal filetype=mdx")
  end
})

vim.opt.clipboard:append("unnamedplus")
vim.g.clipboard = 'osc52'

-- function to flip on gj and gk
vim.keymap.set("n", "j", "v:count ? 'j' : 'gj'", { expr = true, noremap = true })
vim.keymap.set("n", "k", "v:count ? 'k' : 'gk'", { expr = true, noremap = true })

vim.cmd([[cnoremap <expr> <C-P> wildmenumode() ? "\<C-P>" : "\<Up>"]])
vim.cmd([[cnoremap <expr> <C-N> wildmenumode() ? "\<C-N>" : "\<Down>"]])

vim.keymap.set({ "o", "x", "n" }, "]]", "<Plug>(matchup-]%)", { noremap = false, silent = true })
vim.keymap.set({ "o", "x", "n" }, "[[", "<Plug>(matchup-[%)", { noremap = false, silent = true })
