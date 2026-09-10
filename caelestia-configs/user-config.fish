# env
export EDITOR=nvim
export VISUAL=nvim

# Abbrs
abbr lg lazygit
abbr gd 'git diff'
abbr ga 'git add '
abbr gc 'git commit -am'
abbr gcn 'git commit -m'
abbr gcp 'git commit --amend --no-edit'
abbr gce 'git commit --amend'
abbr gcl 'git clone'
abbr gco 'git checkout'
abbr gl 'git log --oneline'
abbr gs 'git status'
abbr gst 'git stash'
abbr gsp 'git stash pop'
abbr gp 'git push'
abbr gpl 'git pull'
abbr gsw 'git switch'
abbr gsm 'git switch main'
abbr gsh 'git show'
abbr gb 'git branch'
abbr gbd 'git branch -d'
abbr gf 'git fetch'
abbr grr 'git reset --hard'
abbr wt 'git worktree'

abbr ee yazi
abbr vv nvim
abbr op opencode
abbr bt btop
abbr ff fastfetch
abbr reload 'source ~/.config/fish/config.fish'
abbr zd 'zeditor ./'
abbr hrds 'herdr session'
# opencode
fish_add_path $HOME/.opencode/bin

# User-local npm global binaries
fish_add_path ~/.npm-global/bin

# fnm
fish_add_path $HOME/.local/bin
fnm env --shell fish | source
