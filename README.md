# Unite Filelist

Based on Lucky Mike's answer for the stack overflow topic: [Navigating through a huge project
with vim and unite.vim plugin](http://stackoverflow.com/a/25171430/4542656), this plugin creates
a file list and use its content as source for [Unite.vim](https://github.com/Shougo/unite.vim).

This plugin has two methods to generate the file list: `git ls-files` and `find`. If this plugin
detects that the [current working directory](http://vimdoc.sourceforge.net/htmldoc/eval.html#getcwd())
is (or is inside a) git repository, the file list will be built using `git ls-files` and the
process will in which case not only be very fast, but will also exclude all `gitignored`'ed files.
On the other hand, if the current working directory is not a git repository, this plugin will use a
combination of `find` and `grep` to gnerate the file list while still exclude all `wildignore`'ed files.

