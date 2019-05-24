# Fo.sh: Execute shell commands in multiple directories grouped by tags

For developers who **running the same command in different directories**
repeatedly, Fosh is a productivity tool that saves time by **executing the
command without having to change the directory**. Unlike other similar tools,
Fosh does not bound to a certain software (like Git for example), it can
**execute any shell command**. **It works on any Bash-compitable shell**
(Bash, Zsh, Git Bash on Windows, etc.).

**If you prefer Node and Npm, have a look at
https://github.com/bimlas/node-fosh/**

* **Manage multiple Git repositors together**
  * `push` and `pull` all of your repos at once
  * Checkout the same branch for project and its submodules
  * Commit with the same message: walk through the repos without
    interruption and copy / paste the same commit message
  * Prevent early push: you do not have to remember which repositories have
    modified, just look at them at the end of the day to see where you need to
    push
* **Control multiple vagrant machines at the same time**

The essence of the logic in a nutshell:

```
for(dir in selectedDirectories) {
  cd(dir);
  shellCommand();
}
```

This also means the name: `for ... shell ...` -> `fo.sh`.

## Installation

TODO

Get the source code, report bugs, open pull requests, or just star because
you didn't know that you need it:

* https://gitlab.com/bimlas/node-fosh (official repository)
* https://github.com/bimlas/node-fosh (mirror, star if you like it)

## Usage

Arguments can be tags and paths.

```
$ fosh run "@git-repos" "../wip-project"
fosh: run > git status --short --branch

__ @1 awesome-project (/home/me/src/) ________________________________________
## master
AM README.md
 M package.json

__ @2 git-test (/home/me/src/) _______________________________________________
## master...origin/master
 M README.adoc
 M encoding/cp1250-encoding-dos-eol.txt
 M encoding/dos-eol.txt

__ @3 wip-project (/home/me/helping-tom/) ____________________________________
## master...origin/master
 M example-code.js

==============================================================================
fosh: run > another command and so on ...
```

### Filtering the directory list

If you want to **execute a command only in certain directories**, you can
select them by their index.

```
fosh: run > @1,3 git status --short --branch

__ @1 awesome-project (/home/me/src/) ________________________________________
## master
AM README.md
 M package.json

__ @3 wip-project (/home/me/helping-tom/) ____________________________________
## master...origin/master
 M example-code.js
```

### Execute in the most recently used directories

**This is useful if the output is long** and you want to execute additional
commands on certain directories. In this case, open a new terminal window (so
you can look back at results in the current terminal) and run the program
without arguments: the directory list is always stored when tag or directory
arguments are given, but if you run it without arguments, it executes the
commands on the last specified directories.

```
$ fosh run "@git-repos" "../wip-project"
fosh: run > git status --short --branch

__ @1 awesome-project (/home/me/src/) ________________________________________
## master
AM README.md
...

# Another terminal

$ fosh run
fosh: WARNING: Using most recently used directory list
fosh: run > @3 git diff

__ @3 wip-project (/home/me/helping-tom/) ____________________________________
 example-code.js | 1 +
 1 file changed, 1 insertion(+)

diff --git a/example-code.js b/example-code.js
index 12b5e40..733220f 100644
--- a/example-code.js
+++ b/example-code.js
...
```

### Check the exit code of the previous command

For example the exit code if a command not found is 127:

```
fo.sh > echo "Exit code: $?"; non_existent_command
____________________________________________________________________
@1 dir1 (.)

Exit code: 0
/bin/bash: non_existent_command: command not found

____________________________________________________________________
@2 non_existent_directory (.)

/.../fo.sh: line 23: pushd: non_existent_directory: No such file or directory

____________________________________________________________________
@3 dir3 (.)

Exit code: 127
/bin/bash: non_existent_command: command not found

____________________________________________________________________
@3 dir4 (.)

Exit code: 127
/bin/bash: non_existent_command: command not found
```

Optionally, you can follow the pushd exit code which is 1 if the directory is
not exists:

```
fo.sh > echo "Exit code: $?"; non_existent_command
____________________________________________________________________
@1 dir1 (.)

Exit code: 0
/bin/bash: non_existent_command: command not found

____________________________________________________________________
@2 non_existent_directory (.)

/.../fo.sh: line 23: pushd: non_existent_directory: No such file or directory

____________________________________________________________________
@3 dir3 (.)

Exit code: 1
/bin/bash: non_existent_command: command not found

____________________________________________________________________
@3 dir4 (.)

Exit code: 127
/bin/bash: non_existent_command: command not found
```

## FAQ

### I use MinTTY on Windows and XY don't work or work differently

Under [MinTTY](https://mintty.github.io/) (default terminal emulator of Git
for Windows), it is not possible to identify exactly that `stdin` is a
terminal or pipe (see https://duckduckgo.com/?q=MinTTY+is+not+a+TTY), so
some things may work differently than in other terminals. Try using another
terminal like system default, your IDE's builtin terminal,
[Conemu](https://conemu.github.io/),
[Alacritty](https://github.com/jwilm/alacritty).

## Similar projects

* https://github.com/joowani/dtags
* https://github.com/coderaiser/node-longrun
* https://github.com/MamadouSy/fed
* https://github.com/isacikgoz/gitbatch
