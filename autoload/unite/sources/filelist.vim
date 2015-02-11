function! unite#sources#filelist#filename()
  let cwd = getcwd()
  return substitute(substitute(cwd,
    \ "^/", "", ""),
    \ "/", "##", "g")
endfunction

function! unite#sources#filelist#filesdir()
  return expand("~/.vim/filelists/")
endfunction

function! unite#sources#filelist#build()
  let filename = unite#sources#filelist#filename()
  let filesdir = unite#sources#filelist#filesdir()
  let filepath = filesdir . filename
  let in_git = strlen(system("git rev-parse")) <= 0

  if in_git
    let cmd = "git ls-files" .
      \ " | sed 's/^/\\.\\//'" .
      \ " > " . filepath

    call system(cmd)
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

