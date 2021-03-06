" This is the portion of init.vim that is just mappings and autocmds, i.e.
" doesn't rely on any plugins. It ought to be sourced near the top of
" init.vim

" call plug#end() also executes the following lines, but since we might only
" be sourcing this file, execute them explicitly here
filetype plugin indent on
syntax on

set termguicolors
set number

" remap leader
let mapleader=" "

" remap escape
imap jk <Esc>
cmap jk <Esc>

" remap Y
map Y y$

" map to execute the current line
nmap <F6> :exec '!'.getline('.')

" turn down timeoutlen (defaults to 1000)
set timeoutlen=500

" Tabs
set softtabstop=2
set shiftwidth=2
set expandtab

" Open hsplit below current window
set splitbelow
" Open vsplit right of current window
set splitright

" Don't use two spaces after a period when joining lines or formatting
set nojoinspaces

" highlight cursor line in the active window only
augroup CursorLineOnlyInActiveWindow
  autocmd!
  autocmd VimEnter,WinEnter,BufWinEnter * setlocal cursorline
  autocmd WinLeave * setlocal nocursorline
augroup END

" Remap window resizing. This is a little weird, since it isn't window
" placement-aware, but it'll do
nnoremap <C-S-Left> :vertical resize -10<CR>
nnoremap <C-S-Right> :vertical resize +10<CR>
nnoremap <C-S-Down> :resize -5<CR>
nnoremap <C-S-Up> :resize +5<CR>

" Search
set ignorecase
set smartcase

" Allows buffer switching without writing. Also for scratch.vim
set hidden

" autoread changed files
set autoread

" Shortcuts for copy/paste to clipboard
" noremap <Leader>y "+y
" noremap <Leader>p "+p
" Yank and paste with the system clipboard
set clipboard+=unnamedplus

" C-h - Find and replace
" <leader>/ - Clear highlighted search terms while preserving history
nnoremap <C-h> :%s/\v//g<left><left><left>
vnoremap <C-h> :s/\v//g<left><left><left>
nnoremap <silent> <leader>/ :nohlsearch<CR>
" actually, highlighting is never useful. just turn it off altogether. note
" there are some weird cases where highlighting still happens, so leave the
" <leader>/ binding in place just in case
set hls!

" move lines up and down with M-k/j (or up/down)
" TODO: these bindings do not play nicely with vim-airline because they
" quickly switch back and forth between modes (to and from command mode, and
" through normal and then command modes for the insert mode version). need to
" figure some workaround...
nnoremap <M-j> :m .+1<CR>==
nnoremap <M-k> :m .-2<CR>==
inoremap <M-j> <Esc>:m .+1<CR>==gi
inoremap <M-k> <Esc>:m .-2<CR>==gi
vnoremap <M-j> :m '>+1<CR>gv=gv
vnoremap <M-k> :m '<-2<CR>gv=gv
nmap <M-Down> <M-j>
nmap <M-Up> <M-k>
imap <M-Down> <M-j>
imap <M-Up> <M-k>
vmap <M-Down> <M-j>
vmap <M-Up> <M-k>

" rebind <Home> to ^ (first non-whitespace character)
nmap <Home> ^
vmap <Home> ^
imap <Home> <C-o>^

" make line wrapping nicer. off by default
set nowrap
set virtualedit=block,onemore
noremap <silent> <Leader>wr :call ToggleWrap()<CR>
function ToggleWrap()
  if &wrap
    echo "Wrap OFF"
    setlocal nowrap
    setlocal virtualedit=block,onemore
    silent! nunmap <buffer> k
    silent! nunmap <buffer> j
    silent! nunmap <buffer> <Up>
    silent! nunmap <buffer> <Down>
    silent! nunmap <buffer> <Home>
    silent! nunmap <buffer> <End>
    silent! iunmap <buffer> <Up>
    silent! iunmap <buffer> <Down>
    silent! iunmap <buffer> <Home>
    silent! iunmap <buffer> <End>
  else
    echo "Wrap ON"
    setlocal wrap linebreak nolist
    setlocal virtualedit=onemore
    setlocal display+=lastline
    noremap  <buffer> <silent> k gk
    noremap  <buffer> <silent> j gj
    noremap  <buffer> <silent> <Up>   gk
    noremap  <buffer> <silent> <Down> gj
    noremap  <buffer> <silent> <Home> g^
    noremap  <buffer> <silent> <End>  g<End>
    inoremap <buffer> <silent> <Up>   <C-o>gk
    inoremap <buffer> <silent> <Down> <C-o>gj
    inoremap <buffer> <silent> <Home> <C-o>g<Home>
    inoremap <buffer> <silent> <End>  <C-o>g<End>
  endif
endfunction

" make window navigation simpler
nnoremap <C-Left> <C-w>h
nnoremap <C-Down> <C-w>j
nnoremap <C-Up> <C-w>k
nnoremap <C-Right> <C-w>l

" on open terminal (:te), start in terminal mode
autocmd TermOpen * startinsert
" allow exit to normal mode with esc
:tnoremap <Esc> <C-\><C-n>

" always trim whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" save in insert mode
inoremap <C-s> <C-o>:w<CR>

" mappings to cut and paste into the "black hole register"
nnoremap <leader>d "_d
xnoremap <leader>d "_d
xnoremap <leader>p "_dP

" global find/replace inside cwd
function! FindReplace()
  " figure out which directory we're in
  let dir = getcwd()

  " ask for pattern
  call inputsave()
  let find = input('Pattern (very magic mode): ')
  call inputrestore()
  if empty(find) | return | endif

  " ask for replacement, noting that empty is a valid replacement
  call inputsave()
  let replace = input({ 'prompt': 'Replacement: ', 'cancelreturn': '<ESC>' })
  call inputrestore()
  if replace == '<ESC>' | return | endif
  :mode " clear echoed message

  " confirm each change individually
  let confirmEach = confirm("Do you want to confirm each individual change?", "&Yes\n&No", 2)
  if confirmEach == 0 | return | endif
  :mode

  " are you sure?
  let confirm = confirm('WARNING: Replacing ' . find . ' with ' . replace . ' in ' . dir . '/**/*. Proceed?', "&Yes\n&No", 2)
  :mode

  if confirm == 1
    " record the current buffer so we can return to it at the end
    let currBuff = bufnr("%")

    " find with rigrep (populate quickfix)
    " note the need to escape special chars to align with very magic mode.
    " this is probably not an exhaustive list
    let rgFind = substitute(find, '\\', '\\\\', 'g')
    let rgFind = substitute(rgFind, '*', '\\*', 'g')
    let rgFind = substitute(rgFind, '[', '\\[', 'g')
    let rgFind = substitute(rgFind, ']', '\\]', 'g')
    let rgFind = substitute(rgFind, '<\|>', '\\\\b', 'g')
    :silent exe 'Rg --hidden --glob !.git ' . rgFind

    " use cfdo to substitute on all quickfix files
    if confirmEach == 1
      :noautocmd exe 'cfdo %s/\v' . find . '/' . replace . '/gc | update'
    else
      :silent noautocmd exe 'cfdo %s/\v' . find . '/' . replace . '/g | update'
    endif

    " close quickfix window
    :silent exe 'cclose'

    " return to start buffer
    :silent exe 'buffer ' . currBuff

    :echom('Replaced ' . find . ' with ' . replace . ' in all files in ' . dir )
  else
    :echom('Aborted')
  endif
endfunction

" and map it
:nnoremap <leader>fr :call FindReplace()<CR>

