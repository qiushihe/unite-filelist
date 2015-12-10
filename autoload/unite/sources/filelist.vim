function! unite#sources#filelist#filename()
  let cwd = getcwd()
  return substitute(substitute(cwd,
    \ "^/", "", ""),
    \ "/", "##", "g")
endfunction

function! unite#sources#filelist#ensure_cache_dir()
  " Ensure the file list cache directory exists
  let path = unite#sources#filelist#filesdir()
  if !isdirectory(path)
    call mkdir(path, "p")
  endif
endfunction

function! unite#sources#filelist#filesdir()
  " Use simplify() to ensure extra '/' are removed from the path
  return expand(simplify(g:unite_filelist_cache_dir . "/"))
endfunction

function! unite#sources#filelist#index_git(index, root, current)
  " Use `git ls-file` to list all tracked files. An unfortunate consequence of
  " this is that newly added unstaged files will not be indexed.
  let cmd = "cd " . a:current . " && git ls-files" .
    \ " | awk '{print \"" . substitute(a:current, a:root, '.', '') . "/\" $0}' " .
    \ " >> " . a:index
  call system(cmd)

  " Recursively call this function to index all submodule directories
  " (including any submodule's submodules).
  for module in split(system("cd " . a:current . " && git submodule --quiet foreach pwd"), "\n")
    call unite#sources#filelist#index_git(a:index, a:root, module)
  endfor
endfunction

function! unite#sources#filelist#index_dir(index, path)
  let path_l = strlen(a:path)
  let ignores = &wildignore

  " Convert wildignore pattern into regex pattern.
  " * Escape . and / because in wildignore they are literal matches
  " * Replace * with .* in regex
  let patterns = map(split(ignores, ","), '
    \ substitute(substitute(substitute(v:val,
      \ "\\.", "\\\\.", "g"),
      \ "\\/", "\\\\/", "g"),
      \ "*", "\\.*", "g")
  \')

  " It's actually faster to tell `find` to simply list all the files then pass
  " them to `grep` for a inverse match, then it is to tell `find` to perform
  " regex match.
  " Another reason for matching this way is regex match for `find` can only be
  " perform on the entire path which is less flexible than using `grep` for
  " partial match which result in more accurate results.
  " The `cut` and `sed` part replaces the current path prefix of the result
  " with just `./` in the index file.
  let cmd = "find " . a:path . " -type f" .
    \ " | grep --invert-match -E \"" . join(patterns, "|") . "\"" .
    \ " | cut -c " . (path_l + 1) . "-" .
    \ " | sed 's/^/\\./'" .
    \ " > " . a:index

  call system(cmd)
endfunction

function! unite#sources#filelist#build()
  let cwd = getcwd()
  let index = unite#sources#filelist#filesdir() . unite#sources#filelist#filename()
  let in_git = strlen(system("git rev-parse")) <= 0

  call unite#sources#filelist#ensure_cache_dir()

  if in_git
    call unite#sources#filelist#index_git(index, cwd, cwd)
  else
    call unite#sources#filelist#index_dir(index, cwd)
  endif
endfunction

function! unite#sources#filelist#delete()
  let filename = unite#sources#filelist#filename()
  let filesdir = unite#sources#filelist#filesdir()
  call system("rm -f " . filesdir . filename)
endfunction

function! unite#sources#filelist#rebuild()
  call unite#sources#filelist#delete()
  call unite#sources#filelist#build()
endfunction

let s:unite_source = { 'name': 'filelist' }

function! s:unite_source.gather_candidates(args, context)
  let filename = unite#sources#filelist#filename()
  let filesdir = unite#sources#filelist#filesdir()
  let fileage = localtime() - getftime(filesdir . filename)

  if fileage > g:unite_filelist_cache_timeout
    call unite#sources#filelist#rebuild()
  endif

  let files = readfile(filesdir . filename)

  return map(files, '{
    \ "word": v:val,
    \ "source": "filelist",
    \ "kind": "filelist",
  \ }')
endfunction

function! unite#sources#filelist#define()
  return s:unite_source
endfunction

