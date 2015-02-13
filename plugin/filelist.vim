" Set this variable to change the filelist cache directory
if !exists("g:unite_filelist_cache_dir")
  let g:unite_filelist_cache_dir = "~/.vim/filelists"
endif

" Expose delete and rebuild commands
command UniteFilelistDelete call unite#sources#filelist#delete()
command UniteFilelistRebuild call unite#sources#filelist#rebuild()
