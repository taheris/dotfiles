# get platform
platform='unknown'
unamestr=$(uname)
if [[ $unamestr == 'Linux' ]]; then
  platform='linux'
elif [[ $unamestr == 'Darwin' ]]; then
  platform='darwin'
fi

# alias editing
TRAPHUP() {
  source $HOME/.zsh/aliases.zsh
}

alias ae='vim $HOME/.zsh/aliases.zsh'      #alias edit
alias ar='source $HOME/.zsh/aliases.zsh'   #alias reload
alias gar="killall -HUP -u \"$USER\" zsh"  #global alias reload

# dotfile editing
alias dfs='cd $HOME/src/github.com/taheris/dotfiles'
alias ve='vim ~/.vimrc'
alias zee='vim ~/.zshenv'
alias zer='source ~/.zshrc'
alias zre='vim ~/.zshrc'
alias zrr='source ~/.zshrc'

# cd
alias cdb='cd -'
alias -g ...='cd ../..'
alias -g ....='cd ../../..'
alias -g .....='cd ../../../..'

# ls
if [[ $platform == 'linux' ]]; then
  alias ls='ls --color=auto'
elif [[ $platform == 'darwin' ]]; then
  alias ls='ls -Gh'
fi

alias l='ls -1A'         # Lists in one column, hidden files.
alias ll='ls -lh'        # Lists human readable sizes.
alias la='ll -A'         # Lists hidden files.
alias lg='la | grep'     # Lists hidden files through grep.
alias lp='la | "$PAGER"' # Lists hidden files through pager.
alias lr='ll -R'         # Lists recursively.
alias lt='ll -tr'        # Lists sorted by time.
alias lc='lt -c'         # Lists sorted by time, shows change time.
alias lu='lt -u'         # Lists sorted by time, shows access time.
alias lk='ll -Sr'        # Lists sorted by size, largest last.
alias lh='ll -at | head' # Lists the most recently modified files.

# interactive
alias mv="mv -i"
alias cp="cp -i"
alias ln="ln -i"

# global expansions
alias -g H=' --help'
alias -g V=' --version'
alias -g C='| gsed -z "$ s/\n$//" | pbcopy '
alias -g G='| grep'
alias -g EG='| egrep'
alias -g FG='| fgrep'
alias -g L="| less"
alias -g S='| sort'
alias -g U='| uniq '
alias -g X='| xargs '
alias -g XI='| xargs -I{} '
alias -g HH='| head -n 1'
alias -g TT='| tail -n -1'
alias -g T='| tail -n +2'
alias -g CC='| wc -c | tr -d " "'
alias -g CL='| wc -l | tr -d " "'
alias -g CW='| wc -w | tr -d " "'
alias -g LC='| tr "[:upper:]" "[:lower:]"'
alias -g UC='| tr "[:lower:]" "[:upper:]"'
alias -g OC='| openssl s_client -ign_eof -connect'
alias -g XL=' -- . ":!Cargo.lock"'

# redirects
alias -g N='>/dev/null'
alias -g ON='1>/dev/null'
alias -g EN='2>/dev/null'
alias -g EO='2>&1'
alias -g IR='</dev/urandom'
alias -g IZ='</dev/zero'

# awk
alias -g A1='| awk '"'"'{print $1}'"'"''
alias -g A2='| awk '"'"'{print $2}'"'"''
alias -g A3='| awk '"'"'{print $3}'"'"''
alias -g A4='| awk '"'"'{print $4}'"'"''
alias -g A5='| awk '"'"'{print $5}'"'"''
alias -g A6='| awk '"'"'{print $6}'"'"''
alias -g A7='| awk '"'"'{print $7}'"'"''
alias -g A8='| awk '"'"'{print $8}'"'"''
alias -g A9='| awk '"'"'{print $9}'"'"''
alias -g AL='| awk '"'"'{print $NF}'"'"''

# du
alias du='du -h'
alias du0='du -d 0'
alias du1='du -d 1'
alias du1s='du -d 1 | sort --human-numeric-sort'
alias du2='du -d 2'
alias du2s='du -d 2 | sort --human-numeric-sort'
alias du3='du -d 3'
alias du3s='du -d 3 | sort --human-numeric-sort'

# fd
alias fdh='fd --hidden --no-ignore --follow'
alias fde='fd --extension'
alias fdf='fd --type file'
alias fdfh='fd --type file --hidden'
alias fdd='fd --type directory'
alias fdl='fd --type symlink'
alias fdx='fd --type executable'
alias fdem='fd --type empty'

# ps
alias psw="ps ww"
alias psa="ps auxww"

# editor
alias e='${(z)VISUAL:-${(z)EDITOR}}'
alias less='less -r'

# misc
alias sudo='sudo '
alias llh='ll -H'
alias tf='tail -f'
alias cl='clear'
alias cls='clear;ls'
alias df='df -h'
alias en='echo -n '
alias gz='tar -zcvf'
alias ka9='killall -9'
alias k9='kill -9'
alias sedi="sed -i ''"
alias digs='dig +short'
alias dark='osascript -e '"'"'tell application "System Events" to sleep'"'"''
alias pw='LC_ALL=C tr -dc "[:print:]" < /dev/urandom | head -c'
alias bc='bc --mathlib'
alias locf='loc --files'
alias locu='loc -uu'
alias t2='tree -L 2'
alias iso='date -u +"%Y-%m-%dT%H:%M:%SZ"'
alias sql='sqlite3 -column -header -batch'

# noglob
alias find='noglob find'
alias git='noglob git'
alias scp='noglob scp'
alias sftp='noglob sftp'

# git
alias g='git'

# git branch
alias gb='git branch'
alias gba='git branch --all --verbose'
alias gbc='git checkout -b'
alias gbd='git branch --delete'
alias gbD='git branch --delete --force'
alias gbl='git branch --verbose'
alias gbL='git branch --all --verbose'
alias gbm='git branch --move'
alias gbM='git branch --move --force'
alias gbr='git branch --move'
alias gbR='git branch --move --force'
alias gbv='git branch --verbose'
alias gbV='git branch --verbose --verbose'
alias gbx='git branch --delete'
alias gbX='git branch --delete --force'

# git clone
alias gcl='git clone'
alias gclr='git clone --recurse-submodules'
alias ghcl='github-clone'

# git commit
alias gc='git commit --verbose'
alias gca='git commit --verbose --all'
alias gcam='git commit --all --message'
alias gcaf='git commit --all --amend --reuse-message HEAD'
alias gcafpf='git commit --all --amend --reuse-message HEAD && git push --force-with-lease'
alias gcad='git commit --amend --date="now"'
alias gcas='git commit --amend --signoff'
alias gcm='git commit --message'
alias gcf='git commit --amend --reuse-message HEAD'
alias gcSf='git commit -S --amend --reuse-message HEAD'
alias gcF='git commit --verbose --amend'
alias gcSF='git commit -S --verbose --amend'
alias gcp='git cherry-pick --ff'
alias gcP='git cherry-pick --no-commit'
alias gcr='git revert'
alias gcR='git reset "HEAD^"'
alias gcl='git-commit-lost'
alias gcy='git cherry -v --abbrev'
alias gcY='git cherry -v'

# git conflict
alias gCl='git --no-pager diff --name-only --diff-filter=U'
alias gCa='git add $(gCl)'
alias gCe='git mergetool $(gCl)'
alias gCo='git checkout --ours --'
alias gCO='gCo $(gCl)'
alias gCt='git checkout --theirs --'
alias gCT='gCt $(gCl)'

# git data
alias gd='git ls-files'
alias gdc='git ls-files --cached'
alias gdx='git ls-files --deleted'
alias gdm='git ls-files --modified'
alias gdu='git ls-files --other --exclude-standard'
alias gdk='git ls-files --killed'
alias gdi='git status --porcelain --short --ignored | sed -n "s/^!! //p"'

# git diff
alias gd='git diff'
alias gdc='git diff --cached -w'
alias gds='git diff --staged -w'
alias gdp='git diff --patch'
alias gdw='git diff --ignore-all-space'
alias gdmxl='git diff master -- . ":(exclude)*.lock"'

# git fetch
alias gf='git fetch'
alias gfa='git fetch --all'

alias gfpr='git fetch --prune'
alias gfa='git fetch --all'
alias gfapr='git fetch --all --prune'
alias gfch='git fetch'

# git grep
alias gg='git grep'
alias ggi='git grep --ignore-case'
alias ggl='git grep --files-with-matches'
alias ggL='git grep --files-without-matches'
alias ggv='git grep --invert-match'
alias ggw='git grep --word-regexp'

# git index
alias gia='git add'
alias giA='git add --patch'
alias giu='git add --update'
alias gid='git diff --no-ext-diff --cached'
alias giD='git diff --no-ext-diff --cached --word-diff'
alias gii='git update-index --assume-unchanged'
alias giI='git update-index --no-assume-unchanged'
alias gir='git reset'
alias giR='git reset --patch'
alias gix='git rm -r --cached'
alias giX='git rm -rf --cached'

# git log
alias gl='git log --topo-order --pretty=format:"${_git_log_medium_format}"'
alias gls='git log --topo-order --stat --pretty=format:"${_git_log_medium_format}"'
alias gld='git log --topo-order --stat --patch --full-diff --pretty=format:"${_git_log_medium_format}"'
alias glo='git log --topo-order --pretty=format:"${_git_log_oneline_format}"'
alias glg='git log --topo-order --graph --pretty=format:"${_git_log_oneline_format}"'
alias glb='git log --topo-order --pretty=format:"${_git_log_brief_format}"'
alias glc='git shortlog --summary --numbered'
alias glS='git log --show-signature'

# git merge
alias gm='git merge'
alias gmC='git merge --no-commit'
alias gmF='git merge --no-ff'
alias gma='git merge --abort'
alias gmt='git mergetool'

# git pull
alias gpl='git pull'
alias gpla='git pull --autostash'
alias gplr='git pull --rebase'
alias gplra='git pull --rebase --autostash'

# git push
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpF='git push --force'
alias gpa='git push --all'
alias gpat='git push --all && git push --tags'
alias gpt='git push --tags'
alias gpsh='git push -u origin `git rev-parse --abbrev-ref HEAD`'

# git rebase
alias gr='git rebase'
alias gra='git rebase --abort'
alias grc='git rebase --continue'
alias gri='git rebase --interactive'
alias grs='git rebase --skip'

# git remote
alias gre='git remote'
alias grea='git remote add'
alias grerm='git remote rm'
alias grern='git remote rename'
alias grev='git remote --verbose'
alias greup='git remote update'
alias grepr='git remote prune'
alias gresh='git remote show'

# git stash
alias gst='git stash'
alias gstl='git stash list'
alias gsta='git stash apply'
alias gstp='git stash pop'
alias gstd='git stash drop'
alias gstcl='git stash clear'
alias gsts='git stash save --include-untracked'
alias gstsi='git stash save --include-untracked --keep-index'
alias gstsp='git stash save --patch --no-keep-index'
alias gstsh='git stash show'
alias gstshp='git stash show --patch --stat'
alias gstshpr='git stash show --patch | patch --reverse'

# git show
alias gsh='git show'
alias gshb='git show-branch'
alias gshba='git show-branch --all'
alias gshp='git show --pretty=short --show-signature'

# git submodule
alias gsm='git submodule'
alias gsma='git submodule add'
alias gsmf='git submodule foreach'
alias gsmi='git submodule init'
alias gsml='git submodule status'
alias gsmm='git-submodule-move'
alias gsms='git submodule sync'
alias gsmup='git submodule update'
alias gsmupr='git submodule update --recursive'
alias gsmuprr='git submodule update --recursive --remote'
alias gsmupir='git submodule update --init --recursive'
alias gsmupirr='git submodule update --init --recursive --remote'
alias gsmpl='git submodule foreach git pull origin master'
alias gsmrm='git-submodule-remove'

# git tag
alias gt='git tag'
alias gtl='git tag -l'
alias gts='git tag -s'
alias gtv='git verify-tag'

# git working copy
alias gwd='git diff --no-ext-diff'
alias gwD='git diff --no-ext-diff --word-diff'
alias gwr='git reset --soft'
alias gwR='git reset --hard'
alias gwc='git clean -n'
alias gwC='git clean -f'
alias gwx='git rm -r'
alias gwX='git rm -rf'

# git misc
alias gs='git status'
alias gi='vim .gitignore'
alias gcm='git ci -m'
alias gcim='git ci -m'
alias gci='git ci'
alias gco='git co'
alias gcp='git cp'
alias ga='git add -A'
alias gap='git add -p'
alias guns='git unstage'
alias gunc='git uncommit'
alias gm='git merge'
alias gms='git merge --squash'
alias gam='git amend --reset-author'
alias gl='git l'
alias glg='git l'
alias glog='git l'
alias co='git co'
alias gb='git b'
alias gpub='grb publish'
alias gtr='grb track'
alias gnb='git checkout -b'
alias grs='git reset'
alias grsh='git reset --hard'
alias gcln='git clean'
alias gclndf='git clean -df'
alias gclndfx='git clean -dfx'
alias gbg='git bisect good'
alias gbb='git bisect bad'
alias gdmb='git branch --merged | grep -v "\*" | xargs -n 1 git branch -d'
alias gbl='git blame'

alias gcob='git checkout -'
alias gcot='git checkout --track'
alias gco='git checkout'
alias gcO='git checkout --patch'
alias glgff='git log --format=full'
alias glsm='git ls-files --modified'
alias glsu='git ls-files --others --exclude-standard'
alias grp='git rev-parse HEAD'
alias gpu='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'
alias gbsu='branch=$(git rev-parse --abbrev-ref HEAD); git branch --set-upstream-to="origin/${branch}" "${branch}"'

# log
alias lgcl='log collect'
alias lgc='log config'
alias lge='log erase'
alias lgsh='log show'
alias lgs='log stream'
alias lgsp='log stream --process'
alias lgst='log stats'

# plist
alias plp='plutil -p --'
alias plj='plutil -convert json -r -o - --'
alias plx='plutil -convert xml1 -o - --'
alias plb='plutil -convert binary1 -o - --'

# brew
alias bi='brew info'
alias bin='brew install'
alias binc='brew install --cask'
alias bun='brew uninstall'
alias bunc='brew uninstall --cask'
alias brin='brew reinstall'
alias brinc='brew reinstall --cask'
alias bl='brew list'
alias blc='brew list --cask'
alias bln='brew link'
alias blno='brew link --overwrite'
alias buln='brew unlink'
alias bo='brew outdated'
alias boc='brew outdated --cask'
alias bs='brew search'
alias bup='brew update \
  && brew upgrade \
  && brew upgrade --cask \
  && brew cleanup \
  && brew doctor'

# brew services
alias bsl='brew services list'
alias bsr='brew services run'
alias bsst='brew services start'
alias bssp='brew services stop'
alias bsrs='brew services restart'
alias bsc='brew services cleanup'

# doom
alias dm='doom'
alias dmb='doom build'
alias dmd='doom doctor'
alias dme='doom env'
alias dmh='doom help'
alias dmi='doom info'
alias dmp='doom purge'
alias dmv='doom version'
alias dmin='doom install'
alias dmsy='doom sync'
alias dmsypr='doom sync --prune'
alias dmsyu='doom sync -u'
alias dmup='doom upgrade'
alias dmupp='doom upgrade --packages'

# go
alias gor='go run'
alias gog='go generate'
alias got='go test'
alias gotv='go test -v'
alias goti='go test -tags=integration'
alias gotiv='go test -tags=integration -v'
alias gotr='go test ./...'
alias gotrv='go test ./... -v'
alias gob='go test -run=NONE -bench=.'

# docker container
alias dca='docker container attach'
alias dcc='docker container commit'
alias dccp='docker container cp'
alias dccr='docker container create'
alias dcd='docker container diff'
alias dcx='docker container exec --interactive --tty'
alias dcxr='docker container exec --interactive --tty --user 0:0'
alias dcxu='docker container exec --interactive --tty --user "$(id -u):$(id -g)"'
alias dcep='docker container export'
alias dci='docker container inspect'
alias dck='docker container kill'
alias dclg='docker container logs'
alias dclgf='docker container logs --follow'
alias dcl='docker container ls'
alias dcla='docker container ls --all'
alias dcpe='docker container pause'
alias dcp='docker container port'
alias dcpr='docker container prune'
alias dcprf='docker container prune --force'
alias dcrn='docker container rename'
alias dcrm='docker container rm'
alias dcrmf='docker container rm --force'
alias dcrmv='docker container rm --volumes'
alias dcrmvf='docker container rm --volumes --force'
alias dcr='docker container run --interactive --tty --rm'
alias dcrr='docker container run --interactive --tty --user 0:0'
alias dcru="$(printf 'docker container run --interactive --tty --user %s:%s' $(id -u) $(id -g))"
alias dcrnh='docker container run --interactive --tty --rm --net=host'
alias dcrns='docker container run -it --rm --privileged --pid=host justincormack/nsenter1'
alias dcst='docker container start'
alias dcsp='docker container stop'
alias dcs='docker container stats'
alias dct='docker container top'
alias dcupe='docker container unpause'
alias dcup='docker container update'
alias dcw='docker container wait'

# docker compose
alias dcm='docker compose'
alias dcmf='docker compose --file'
alias dcmb='docker compose build'
alias dcmc='docker compose config'
alias dcmcr='docker compose create'
alias dcmd='docker compose down --timeout 0'
alias dcmev='docker compose events'
alias dcmx='docker compose exec'
alias dcmim='docker compose images'
alias dcmk='docker compose kill'
alias dcmlg='docker compose logs'
alias dcmps='docker compose ps'
alias dcmpl='docker compose pull'
alias dcmps='docker compose push'
alias dcmrs='docker compose restart --timeout 0'
alias dcmrm='docker compose rm'
alias dcmrn='docker compose run'
alias dcmst='docker compose start'
alias dcmsp='docker compose stop --timeout 0'
alias dcmt='docker compose top'
alias dcmu='docker compose up --timeout 0'

# docker image
alias dil='docker image ls'
alias dila='docker image ls --all'
alias dib='docker image build --force-rm'
alias dibt='docker image build --force-rm --tag'
alias dii='docker image inspect'
alias dihi='docker image history'
alias diip='docker image import'
alias dild='docker image load'
alias dips='docker image push'
alias dipl='docker image pull'
alias dipr='docker image prune'
alias dipra='docker image prune --all'
alias diprf='docker image prune --force'
alias dipraf='docker image prune --all --force'
alias dipraf='docker image prune --all --force'
alias dirm='docker image rm'
alias dirmf='docker image rm --force'
alias dis='docker image save'
alias dit='docker image tag'

# docker network
alias dnc='docker network create'
alias dncn='docker network connect'
alias dndc='docker network disconnect'
alias dni='docker network inspect'
alias dnl='docker network ls'
alias dnpr='docker network prune'
alias dnprf='docker network prune --force'
alias dnrm='docker network rm'

# docker system
alias dse='docker system events'
alias dsi='docker system info'
alias dsdf='docker system df'
alias dsdfv='docker system df --verbose'
alias dspr='docker system prune'
alias dspra='docker system prune --all'
alias dsprf='docker system prune --force'
alias dsprv='docker system prune --volumes'
alias dsprvf='docker system prune --volumes --force'
alias dsprav='docker system prune --all --volumes'
alias dspravf='docker system prune --all --volumes --force'

# docker volume
alias dv='docker volume'
alias dvc='docker volume create'
alias dvi='docker volume inspect'
alias dvl='docker volume ls'
alias dvpr='docker volume prune'
alias dvprf='docker volume prune --force'
alias dvrm='docker volume rm'

# cargo
alias cb='cargo build'
alias cbb='cargo build --bin'
alias cbe='cargo build --examples'
alias cbr='cargo build --release'
alias cbrm='cargo build --release --target=x86_64-unknown-linux-musl'
alias cbaf='cargo build --all-features'
alias cbc='cargo bench'
alias cbca='cargo clippy --all-features --all-targets --workspace'
alias cbcaf='cargo bench --all-features'
alias cbcat='cargo bench --all-targets'
alias ct='cargo test'
alias ctaf='cargo test --all-features'
alias ctnc='cargo test -- --nocapture'
alias ctafnc='cargo test --all-features -- --nocapture'
alias ccln='cargo clean'
alias cdoc='cargo doc'
alias cdoco='cargo doc --open'
alias cn='cargo new'
alias cr='cargo run'
alias cre='cargo run --example'
alias crr='cargo run --release'
alias cck='cargo check'
alias ccka='cargo check --all-features --all-targets --workspace'
alias cckaf='cargo check --all-features'
alias cckaf='cargo check --all-targets'
alias cckw='cargo check --workspace'
alias ccl='cargo clippy'
alias ccla='cargo clippy --all-features --all-targets --workspace'
alias cclaf='cargo clippy --all-features'
alias cclat='cargo clippy --all-targets'
alias cckw='cargo clippy --workspace'
alias cup='cargo update'
alias cupp='cargo update --package'
alias cs='cargo search'
alias cin='cargo install'
alias cinf='cargo install --force'
alias cinp='cargo install --path'
alias cinpd='cargo install --path .'
alias cinpdf='cargo install --path . --force'
alias cun='cargo uninstall'
alias cx='cargo expand'
alias cxb='cargo expand --bin'
alias cxl='cargo expand --lib'

# cargo +nightly
alias cnb='cargo +nightly build'
alias cnbr='cargo +nightly build --release'
alias cnbaf='cargo +nightly build --all-features'
alias cnbc='cargo +nightly bench'
alias cnbcaf='cargo +nightly bench --all-features'
alias cnt='cargo +nightly test'
alias cntaf='cargo +nightly test --all-features'
alias cnn='cargo +nightly new'
alias cnr='cargo +nightly run'
alias cnin='cargo +nightly install'
alias cninf='cargo +nightly install --force'
alias cnun='cargo +nightly uninstall'

# rustup
alias ru='rustup'
alias rus='rustup show'
alias ruup='rustup update'
alias rusup='rustup self update'
alias rud='rustup default'
alias rutc='rustup toolchain'
alias rutcl='rustup toolchain list'
alias rutcin='rustup toolchain install'
alias rutcun='rustup toolchain uninstall'
alias ruta='rustup target'
alias rutal='rustup target list'
alias rutaa='rustup target add'
alias rutar='rustup target remove'
alias rucl='rustup component list'
alias ruca='rustup component add'
alias rucr='rustup component remove'
alias ruo='rustup override'
alias ruol='rustup override list'
alias ruos='rustup override set'
alias ruou='rustup override unset'
alias rur='rustup run'
alias ruw='rustup which'
alias rudoc='rustup doc'
alias ruh='rustup help'
alias rusp='rustup set profile'
alias ruspm='rustup set profile minimal'
alias ruspd='rustup set profile default'
alias ruspc='rustup set profile complete'

# ripgrep
alias rg='rg --sort-files --follow --no-messages --max-columns 180'
alias rgh='rg --hidden'
alias rgi='rg --no-ignore'
alias rgb='rg-boundary'
alias rgl='rg-limit'
alias rgt='rg --type'
alias rgc='rg --type c'
alias rgcmake='rg --type cmake'
alias rgcpp='rg --type cpp'
alias rgcss='rg --type css'
alias rggo='rg --type go'
alias rghtml='rg --type html'
alias rgjs='rg --type js'
alias rgjson='rg --type json'
alias rgmd='rg --type markdown'
alias rgorg='rg --type org'
alias rgpy='rg --type py'
alias rgrm='rg --type readme'
alias rgrb='rg --type ruby'
alias rgrs='rg --type rust'
alias rgsc='rg --type scala'
alias rgsh='rg --type sh'
alias rgsql='rg --type sql'
alias rgsw='rg --type swift'
alias rgtoml='rg --type toml'
alias rgtxt='rg --type txt'
alias rgxml='rg --type xml'

# jira
alias jas='jira assign'
alias jcr='jira create'
alias jatc='jira attach create'
alias jatg='jira attach get'
alias jatl='jira attach list'
alias jatrm='jira attach remove'
alias jblk='jira block'
alias jbr='jira browse'
alias jco='jira comment'
alias jed='jira edit'
alias jea='jira epic add'
alias jec='jira epic create'
alias jel='jira epic list'
alias jerm='jira epic remove'
alias jln='jira issuelink'
alias jlnt='jira issuelinktypes'
alias jit='jira issuetypes'
alias jla='jira labels add'
alias jlrm='jira labels remove'
alias jls='jira labels set'
alias jl='jira list'
alias jli='jira login'
alias jlo='jira logout'
alias jsub='jira subtask'
alias juas='jira unassign'
alias jv='jira view'
alias jwa='jira watch'
alias jwla='jira worklog add'
alias jwll='jira worklog list'

# jira state transitions
alias jack='jira acknowledge'
alias jbl='jira backlog'
alias jcl='jira close'
alias jd='jira done'
alias jip='jira in-progress'
alias jro='jira reopen'
alias jres='jira resolve'
alias jst='jira start'
alias jsp='jira stop'
alias jtd='jira todo'
alias jt='jira transition'
alias jtl='jira transitions'

# kubernetes
alias k='kubectl'
alias ka='kubectl apply'
alias kaf='kubectl apply --filename'
alias klg='kubectl logs'
alias klgf='kubectl logs --follow'
alias klgp='kubectl logs --previous'
alias kp='kubectl proxy'
alias kpf='kubectl port-forward'
alias kr='kubectl run --rm --stdin --tty'
alias kx='kubectl exec --stdin --tty'

alias kg='kubectl get'
alias kga='kubectl get all'
alias kgd='kubectl get deployment'
alias kgev='kubectl get event'
alias kgi='kubectl get ingress'
alias kgj='kubectl get jobs'
alias kgp='kubectl get pods'
alias kgpv="kubectl get pods -o json | jq -r '.items | .[] | (.spec?.containers? | .[]? | .image?)' | sort --unique"
alias kgn='kubectl get nodes'
alias kgcm='kubectl get configmap'
alias kgns='kubectl get namespaces'
alias kgpv='kubectl get persistentvolumes'
alias kgpvc='kubectl get persistentvolumeclaims'
alias kgsec='kubectl get secret'
alias kgsvc='kubectl get service'
alias kgss='kubectl get statefulset'

alias kd='kubectl describe'
alias kda='kubectl describe all'
alias kdd='kubectl describe deployment'
alias kdi='kubectl describe ingress'
alias kdj='kubectl describe jobs'
alias kdp='kubectl describe pods'
alias kdn='kubectl describe nodes'
alias kdcm='kubectl describe configmap'
alias kdns='kubectl describe namespaces'
alias kdpv='kubectl describe persistentvolumes'
alias kdpvc='kubectl describe persistentvolumeclaims'
alias kdsec='kubectl describe secret'
alias kdsvc='kubectl describe service'
alias kdss='kubectl describe statefulset'

alias kccc='kubectl config current-context'
alias kcdc='kubectl config delete-context'
alias kcdcl='kubectl config delete-cluster'
alias kcgc='kubectl config get-contexts'
alias kcgcl='kubectl config get-clusters'
alias kcrc='kubectl config rename-context'
alias kcs='kubectl config set'
alias kcsc='kubectl config set-context'
alias kcscc='kubectl config set-context --current'
alias kcsccns='kubectl config set-context --current --namespace'
alias kcscl='kubectl config set-cluster'
alias kcscr='kubectl config set-credentials'
alias kcu='kubectl config unset'
alias kcuc='kubectl config use-context'
alias kcucdd='kubectl config use-context docker-desktop'
alias kcv='kubectl config view'

alias ked='kubectl edit'
alias keda='kubectl edit all'
alias kedd='kubectl edit deployment'
alias kedi='kubectl edit ingress'
alias kedj='kubectl edit jobs'
alias kedp='kubectl edit pods'
alias kedn='kubectl edit nodes'
alias kedcm='kubectl edit configmap'
alias kedns='kubectl edit namespaces'
alias kedpv='kubectl edit persistentvolumes'
alias kedpvc='kubectl edit persistentvolumeclaims'
alias kedsec='kubectl edit secret'
alias kedsvc='kubectl edit service'
alias kedss='kubectl edit statefulset'

alias kdel='kubectl delete'
alias kdeld='kubectl delete deployment'
alias kdeli='kubectl delete ingress'
alias kdelj='kubectl delete jobs'
alias kdelp='kubectl delete pods'
alias kdeln='kubectl delete nodes'
alias kdelcm='kubectl delete configmap'
alias kdelns='kubectl delete namespaces'
alias kdelpv='kubectl delete persistentvolumes'
alias kdelpvc='kubectl delete persistentvolumeclaims'
alias kdelsec='kubectl delete secret'
alias kdelsvc='kubectl delete service'
alias kdelss='kubectl delete statefulset'

alias krm='kubectl delete'
alias krmd='kubectl delete deployment'
alias krmi='kubectl delete ingress'
alias krmj='kubectl delete jobs'
alias krmp='kubectl delete pods'
alias krmn='kubectl delete nodes'
alias krmcm='kubectl delete configmap'
alias krmns='kubectl delete namespaces'
alias krmpv='kubectl delete persistentvolumes'
alias krmpvc='kubectl delete persistentvolumeclaims'
alias krmsec='kubectl delete secret'
alias krmsvc='kubectl delete service'
alias krmss='kubectl delete statefulset'

alias -g LT=' --selector="app.kubernetes.io/managed-by=tilt" -oname'
alias -g NA=' --all-namespaces'
alias -g NI=' --namespace=ingress-nginx'
alias -g NS=' --namespace=kube-system'
alias -g OJ=' --output=json'
alias -g OY=' --output=yaml'
