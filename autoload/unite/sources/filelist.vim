function! unite#sources#filelist#filename()
  let cwd = getcwd()
  return substitute(substitute(cwd,
    \ "^/", "", ""),
    \ "/", "##", "g")
endfunction

function! unite#sources#filelist#ensure_cache_dir()
  " Ensure file list cache directory exists
  let path = unite#sources#filelist#filesdir()
  if !isdirectory(path)
    call mkdir(path, "p")
  endif
endfunction

function! unite#sources#filelist#filesdir()
  " Use simplify() to ensure extra '/' are removed from the path
  return expand(simplify(g:unite_filelist_cache_dir . "/"))
endfunction

function! unite#sources#filelist#build()
  let filename = unite#sources#filelist#filename()
  let filesdir = unite#sources#filelist#filesdir()
  let filepath = filesdir . filename
  let in_git = strlen(system("git rev-parse")) <= 0

  call unite#sources#filelist#ensure_cache_dir()

  if in_git
    " Use git ls-files to list all the tracked files then pipe the output
    " to awk to add './' in front of each path.
    let cmd = "git ls-files" .
      \ " | awk '{print \"./\" $0}'" .
      \ " > " . filepath
    call system(cmd)

    " Grab current working directory and remove the trailing ^@ (null)
    " character
    let wdpath = substitute(system("pwd"), '\%x00$', '', 'g')

    " Index submodule files by iterating over each submodule, then while
    " inside the submodule directory, call git-ls-files to list all tracked
    " files by that submodule, then pipe those path to awk to prepend the
    " submodule's relative path in front of each path.
    for modpath in split(system("git submodule --quiet foreach pwd"), "\n")
      let relmodpath = substitute(modpath, wdpath, '.', '')
      let modcmd = "cd " . modpath . " && git ls-files" .
        \ " | awk '{print \"" . relmodpath . "/\" $0}' " .
        \ " >> " . filepath
      call system(modcmd)
    endfor
  else
    let cwd = getcwd()
    let cwd_l = strlen(cwd)
    let ignores = &wildignore

    let patterns = map(split(ignores, ","), '
      \ substitute(substitute(substitute(v:val,
        \ "\\.", "\\\\.", "g"),
        \ "\\/", "\\\\/", "g"),
        \ "*", "\\.*", "g")
    \')

    let cmd = "find " . cwd . " -type f" .
      \ " | grep --invert-match -E \"" . join(patterns, "|") . "\"" .
      \ " | cut -c " . (cwd_l + 1) . "-" .
      \ " | sed 's/^/\\./'" .
      \ " > " . filepath

    call system(cmd)
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

  if findfile(filename, filesdir) != filesdir . filename
    call unite#sources#filelist#build()
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

