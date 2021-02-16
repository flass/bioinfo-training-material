# (Bio)Informatics FAQ: basics and more

## Linux/shell

### \[Bash aliases\] - You seem to use `ll` instead of `ls -l`  is that a short-cut you've created yourself for something that you do often, like an Excel Macro?

yes it's like a macro - in Bash language it's called an alias. the `ll` alias for `ls -l` is one that's commonly used and usually is already defined in Ubuntu distributions. Aliases are defined by the `alias` command. The syntax to declare an alias is like this:
```sh
alias nameofalias="complex command line"
```
if you just type `alias` you get the list of what has been declared and is active in your session. In mine I have these aliases active:
```sh
[florent@mypc ~]$ alias
alias aptx='archaeopteryx'
alias conda2_activate='source /Users/fl4/miniconda2/etc/profile.d/conda.sh && conda activate'
alias conda3_activate='source /Users/fl4/miniconda3/etc/profile.d/conda.sh && conda activate'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias gl='git log --graph --abbrev-commit --decorate --date=relative --format=format:'\''%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)'\'' --all'
alias grep='grep --color=auto'
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias ls='gls --color=auto'
alias panup='cd ~/software/pantagruel/ && git pull && git submodule update && cd -'
alias rsync='/Users/fl4/homebrew/bin/rsync -avzuL'
```
To declare your own, try typing `alias ll='ls -alF'` and then the `ll` alias should be active.

Note that you can override basic commands; for instance my `rsync` alias, which includes some options, overrides the basic `rsync`. 
If you have such an overriding alias declared and want to use the native command, you should use `\` ahead of it; in the case above, use `\rsync` to call the native, basic command.

Aliases disapear every time you close the session, so best writing the declaration command `alias nameofalias="complex command line"` in your `~/.bash_profile` file so that they're automatically loaded every time you start a Bash session.

_______
