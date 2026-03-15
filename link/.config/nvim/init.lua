local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git', '--branch=stable',
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ' '
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

require('lazy').setup({
  -- editing
  'alvan/vim-closetag',
  'editorconfig/editorconfig-vim',
  'jiangmiao/auto-pairs',
  'junegunn/vim-easy-align',
  'tpope/vim-surround',
  'scrooloose/nerdcommenter',

  -- snippets
  'honza/vim-snippets',
  { 'sirver/ultisnips', config = function()
    vim.g.UltiSnipsExpandTrigger = '<c-j>'
    vim.g.UltiSnipsJumpForwardTrigger = '<c-j>'
    vim.g.UltiSnipsJumpBackwardTrigger = '<c-k>'
  end },

  -- fuzzy finder
  { 'junegunn/fzf', build = ':call fzf#install()' },
  'junegunn/fzf.vim',

  -- writing
  'junegunn/goyo.vim',
  { 'junegunn/limelight.vim', config = function()
    vim.g.limelight_conceal_ctermfg = '240'
  end },

  -- formatting
  { 'prettier/vim-prettier', build = 'npm i' },

  -- languages
  'sheerun/vim-polyglot',

  -- indent detection
  { 'ciaranm/detectindent', config = function()
    vim.g.detectindent_preferred_expandtab = 1
    vim.g.detectindent_preferred_indent = 2
    vim.api.nvim_create_autocmd('BufReadPost', { command = 'DetectIndent' })
  end },

  -- lsp
  { 'neovim/nvim-lspconfig', config = function()
    vim.lsp.config('ts_ls', {})
    vim.lsp.config('pyright', {})
    vim.lsp.config('lua_ls', {})
    vim.lsp.enable({ 'ts_ls', 'pyright', 'lua_ls' })
  end },

  -- completion
  { 'hrsh7th/nvim-cmp', dependencies = {
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
  }, config = function()
    local cmp = require('cmp')
    cmp.setup({
      sources = cmp.config.sources(
        { { name = 'nvim_lsp' } },
        { { name = 'buffer' }, { name = 'path' } }
      ),
      mapping = cmp.mapping.preset.insert({
        ['<c-space>'] = cmp.mapping.complete(),
        ['<cr>'] = cmp.mapping.confirm({ select = true }),
        ['<tab>'] = cmp.mapping.select_next_item(),
        ['<s-tab>'] = cmp.mapping.select_prev_item(),
      }),
    })
  end },
}, { rocks = { enabled = false } })

-- lsp keymaps
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>a', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
  end,
})

-- plugin settings
vim.g.NERDSpaceDelims = 1
vim.g.closetag_filenames = '*.html,*.md'
vim.g.closetag_xhtml_filenames = '*.jsx'
vim.g.fzf_buffers_jump = 1
vim.g.fzf_commands_expect = 'ctrl-x'
vim.g.fzf_tags_command = 'ctags -R'
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.node_host_prog = '~/.bun/bin/neovim-node-host'

-- options
vim.opt.autoindent = true
vim.opt.autoread = true
vim.opt.backspace = 'indent,eol,start'
vim.opt.confirm = true
vim.opt.expandtab = true
vim.opt.fillchars = { vert = '|' }
vim.opt.hidden = true
vim.opt.hlsearch = true
vim.opt.laststatus = 0
vim.opt.linebreak = true
vim.opt.listchars = { space = ' ', tab = '→ ', eol = '¬' }
vim.opt.mouse = 'nv'
vim.opt.scrolloff = 5
vim.opt.shiftwidth = 2
vim.opt.sidescroll = 1
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.softtabstop = 2
vim.opt.statusline = '%F %y'
vim.opt.tabstop = 2
vim.opt.textwidth = 0
vim.opt.wildmenu = true
vim.opt.wrap = true
vim.opt.wrapmargin = 0

-- highlights
vim.cmd('highlight Normal guibg=NONE ctermbg=NONE')
vim.cmd('highlight NormalFloat guibg=NONE ctermbg=NONE')
vim.cmd('highlight VertSplit cterm=NONE')

-- keymaps
local map = vim.keymap.set

map('n', 'ga', '<Plug>(EasyAlign)')
map('x', 'ga', '<Plug>(EasyAlign)')
map('n', ',', '@@')
map('n', '<ScrollWheelDown>', '3<c-E>')
map('n', '<ScrollWheelUp>', '3<c-Y>')
map('n', '<c-b>', ':Buffers<cr>')
map('n', '<c-f>', ':Rg<cr>')
map('n', '<c-p>', ':Files<cr>')
map('n', '<c-s>', ':update<cr>')
map('n', '<leader>0', ':tablast<cr>')
for i = 1, 9 do
  map('n', '<leader>' .. i, i .. 'gt')
end
map('n', '<leader>d', ':bdelete<cr>')
map('n', '<leader>e', ':Explore<cr>')
map('n', '<leader>t', ':tabedit .<cr>')
map('n', 'j', 'gj', { silent = true })
map('n', 'k', 'gk', { silent = true })
map('n', '<c-m>', ':nohl<cr>:syntax sync fromstart<cr>:set list!<cr>:set number!<cr>', { silent = true })
map('n', '<leader>cd', ':cd %:h<cr>', { silent = true })
map('v', '<c-s>', '<c-c>:update<cr>', { silent = true })
