-- Loaded via programs.neovim.initLua. Edit this file, then rebuild.
-- After you're comfortable, you can split this into lua/ modules and
-- point initLua at a require() instead.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.wrap = false
vim.opt.breakindent = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Write file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })

-- Colorscheme is injected by Stylix (stylix.targets.neovim).
require("lualine").setup({
  options = { theme = "auto" },
})

require("which-key").setup({})

require("telescope").setup({})
local telescope = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", telescope.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", telescope.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", telescope.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", telescope.help_tags, { desc = "Help tags" })

require("nvim-treesitter.configs").setup({
  highlight = { enable = true },
  indent = { enable = true },
})

local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
  }),
  sources = {
    { name = "nvim_lsp" },
    { name = "path" },
    { name = "buffer" },
  },
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- nil is the Nix language server. More servers: add the package to
-- extraPackages in neovim.nix, then vim.lsp.config / vim.lsp.enable here.
vim.lsp.config("nil_ls", {
  cmd = { "nil" },
  filetypes = { "nix" },
  root_markers = { "flake.nix", ".git" },
  capabilities = capabilities,
  settings = {
    ["nil"] = {
      formatting = { command = { "nixfmt" } },
    },
  },
})
vim.lsp.enable("nil_ls")

vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
vim.keymap.set("n", "<leader>f", function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format" })
