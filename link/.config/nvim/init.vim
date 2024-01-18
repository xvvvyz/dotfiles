call plug#begin('~/.local/share/nvim/plugged')
Plug 'alvan/vim-closetag'
Plug 'ciaranm/detectindent'
Plug 'editorconfig/editorconfig-vim'
Plug 'honza/vim-snippets'
Plug 'jiangmiao/auto-pairs'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/limelight.vim'
Plug 'junegunn/vim-easy-align'
Plug 'prettier/vim-prettier', { 'do': 'npm i' }
Plug 'scrooloose/nerdcommenter'
Plug 'sheerun/vim-polyglot'
Plug 'sirver/ultisnips'
Plug 'tpope/vim-surround'
call plug#end()

let g:NERDSpaceDelims = 1
let g:UltiSnipsExpandTrigger = '<tab>'
let g:UltiSnipsJumpBackwardTrigger = '<s-tab>'
let g:UltiSnipsJumpForwardTrigger = '<tab>'
let g:closetag_filenames = '*.html,*.md'
let g:closetag_xhtml_filenames = '*.jsx'
let g:detectindent_preferred_expandtab = 1
let g:detectindent_preferred_indent = 2
let g:fzf_buffers_jump = 1
let g:fzf_commands_expect = 'ctrl-x'
let g:fzf_tags_command = 'ctags -R'
let g:limelight_conceal_ctermfg = '240'
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:node_host_prog = '~/.bun/bin/neovim-node-host'
let g:prettier#config#arrow_parens = 'always'
let g:prettier#config#single_quote = 1
let g:prettier#config#trailing_comma = 'es5'
let g:python3_host_prog = '/usr/bin/python3'
let mapleader = " "

set autoindent
set autoread
set backspace=indent,eol,start
set confirm
set expandtab
set fillchars=vert:\|
set hidden
set hlsearch
set laststatus=0
set linebreak
set listchars=space:\ ,tab:→\ ,eol:¬
set mouse=nv
set nocompatible
set scrolloff=5
set shiftwidth=2
set sidescroll=1
set smartcase
set smartindent
set smarttab
set softtabstop=2
set statusline=%F\ %y
set tabstop=2
set textwidth=0
set wildmenu
set wrap
set wrapmargin=0

highlight VertSplit cterm=NONE

inoremap <silent> <c-s> <c-o>:update<cr>
nmap ga <Plug>(EasyAlign)
nnoremap , @@
nnoremap <ScrollWheelDown> 3<c-E>
nnoremap <ScrollWheelUp> 3<c-Y>
nnoremap <c-b> :Buffers<cr>
nnoremap <c-f> :Ag<cr>
nnoremap <c-p> :Files<cr>
nnoremap <c-s> :update<cr>
nnoremap <leader>0 :tablast<cr>
nnoremap <leader>1 1gt
nnoremap <leader>2 2gt
nnoremap <leader>3 3gt
nnoremap <leader>4 4gt
nnoremap <leader>5 5gt
nnoremap <leader>6 6gt
nnoremap <leader>7 7gt
nnoremap <leader>8 8gt
nnoremap <leader>9 9gt
nnoremap <leader>d :bdelete<cr>
nnoremap <leader>e :Explore<cr>
nnoremap <leader>t :tabedit .<cr>
nnoremap <silent> <buffer> j gj
nnoremap <silent> <buffer> k gk
nnoremap <silent> <c-m> :nohl<cr>:syntax sync fromstart<cr>:set list!<cr>:set number!<cr>
nnoremap <silent> <leader>cd :cd %:h<cr>
vnoremap <silent> <c-s> <c-c>:update<cr>
xmap ga <Plug>(EasyAlign)

autocmd BufReadPost * :DetectIndent
