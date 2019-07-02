# Mosh: Run shell commands in multiple directories grouped by tags

For developers who **running the same command in different directories**
repeatedly, Mosh is a productivity tool that saves time by **executing the
command without having to change the directory**. Unlike other similar tools,
Mosh does not bound to a certain software (like Git for example), it can
**execute any shell command**. **It works on any Bash-compitable shell**
(Bash, Zsh, Git Bash on Windows, etc.).

![screencast](https://i.imgur.com/OFKXZMR.gif)

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
for dir in $selected_directories; do
  cd $dir
  $shell_command
done
```

The Mosh word is a reflection of what the program is doing: it runs around the
directories.

https://www.youtube.com/watch?v=fgBseiTlDTE

## Installation

Download the `bin/mosh` script and place it somewhere on your PATH or use
[Basher](https://github.com/basherpm/basher).

Get the source code, report bugs, open pull requests, or just star because
you didn't know that you need it:

* https://gitlab.com/bimlas/bash-mosh (official repository)
* https://github.com/bimlas/bash-mosh (mirror, please star if you like it)

## Usage

## Run: Execute commands in multiple directories

Let's say that you have a bunch of directories that start with the same prefix
(`g`) in `/usr/share`. **You want to issue the same commands to all of them**.
You can use `mosh run` with a wild card for the directory names you want to
interact with:

```
$ mosh run /usr/share/g*
```

This will open up an interactive terminal where you can run one or more
commands. For example list the content of them:

```
mosh > ls

______________________________________________________________________________
@1 gdb (/usr/share)

auto-load

______________________________________________________________________________
@2 git (/usr/share)

msys2-32.ico  ReleaseNotes.css

______________________________________________________________________________
@3 glib-2.0 (/usr/share)

gdb  schemas

...
```

Exiting from the program is done with Control+D.

Of course, this could have been done with the `ls /usr/share/g*` command.
**The real targets of the program are the commands that can only be executed
in the current directory, so we should enter the directory before issuing the
command.** As a useful example, we can check the status for a bunch of Git
repos.

```
$ mosh run ~/src/* "../wip-project"
mosh > git status --short --branch

______________________________________________________________________________
@1 awesome-project (/home/me/src/)

## master
AM README.md
 M package.json

______________________________________________________________________________
@2 git-test (/home/me/src/)

## master...origin/master
 M README.adoc
 M encoding/cp1250-encoding-dos-eol.txt
 M encoding/dos-eol.txt

______________________________________________________________________________
@3 wip-project (/home/me/helping-tom/)

## master...origin/master
 M example-code.js

==============================================================================
mosh > another command and so on ...
```

**Arguments can be tags and paths** (see below for the description of tags).

```
$ mosh run "@git-repos" "../wip-project"
```

Since you will mostly use the `run` command, you may want to **assign an
alias** to execute the command with less typing.

```
# Before
$ mosh run ~/src/* "../wip-project"

alias run="mosh run"

# After
$ run ~/src/* "../wip-project"
```

### Filtering the directory list

If you want to **execute a command only in certain directories**, you can
select them by their index.

```
mosh > @1,3 git status --short --branch

______________________________________________________________________________
@1 awesome-project (/home/me/src/)

## master
AM README.md
 M package.json

______________________________________________________________________________
@3 wip-project (/home/me/helping-tom/)

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
$ mosh run "@git-repos" "../wip-project"
mosh > git status --short --branch

______________________________________________________________________________
@1 awesome-project (/home/me/src/)

## master
AM README.md
...

# Another terminal

$ mosh run
mosh ! WARNING: Using most recently used directory list
mosh > @3 git diff

______________________________________________________________________________
@3 wip-project (/home/me/helping-tom/)

 example-code.js | 1 +
 1 file changed, 1 insertion(+)

diff --git a/example-code.js b/example-code.js
index 12b5e40..733220f 100644
--- a/example-code.js
+++ b/example-code.js
...
```

### Execute non-interactively

If you want to use it within a script or in scheduled tasks, you can also send
commands to stdin.

```
$ echo "cp -r ./ ~/image_backups" | mosh run "@pictures" > /dev/null
```

### Check the exit code of the previous command

If a command requires the success of the same command in the previous
directory, you can check the exit code.

```
mosh > if [[ $? == 0 ]]; then echo "Running"; non_existent_command; else echo "Not running"; fi
______________________________________________________________________________
@1 awesome-project (/home/me/src/)

Running
/bin/bash: non_existent_command: command not found

______________________________________________________________________________
@2 git-test (/home/me/src/)

Not running

______________________________________________________________________________
@3 wip-project (/home/me/helping-tom/)

Not running
```

## Tag: Assign tags to directories

To avoid having to always type the path of directories, you can assign them to
tags (think of them as bookmarks).

The tags can be specified as command-line parameters prefixed with `@`,
directories should be listed in the prompt, or piped to stdin.

```
$ mosh tag "@pictures" "@personal"
/home/myself/photos
/home/mom/my_little_family
../granny

$ echo "./" | mosh tag "@pictures" "@personal"
```

Tag files are stored in `~/.mosh` directory, you can edit them with any text
editor.

### Find Git repositories

**Tagging Git repositories** under the current directory (`./`) with
"git-repos" tag:

```
$ find "./" -name ".git" -printf "%h\n" | mosh tag "@git-repos"
```

### Tag new repositories automatically

In order not to miss any newly created or cloned repositories, one of the [Git
hooks](https://git-scm.com/docs/githooks)
([post-commit](https://git-scm.com/docs/githooks#_post_commit) or
[pre-push](https://git-scm.com/docs/githooks#_pre_push) for example) can be
used to automatically assign the repository path to a default tag.

```
#!/bin/sh
if ( which mosh &> /dev/null ); then
  echo "." | mosh tag "@git" &
fi
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
