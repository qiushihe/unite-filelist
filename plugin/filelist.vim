" Set this variable to change the filelist cache directory.
if !exists("g:unite_filelist_cache_dir")
  let g:unite_filelist_cache_dir = "~/.vim/filelists"
endif

" Set this variable to control max cache age in seconds.
" Set it to a value less or equal to 0 to disable caching (the cache file will
" still be created).
if !exists("g:unite_filelist_cache_timeout")
  let g:unite_filelist_cache_timeout = 300
endif

" Expose delete and rebuild commands
command! UniteFilelistDelete call unite#sources#filelist#delete()
command! UniteFilelistRebuild call unite#sources#filelist#rebuild()
