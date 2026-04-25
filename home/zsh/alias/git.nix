{ ... }:

let
  gitLog = {
    medium = "%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B";
    oneline = "%C(blue)%cd %C(yellow)%h%C(red)%d %C(white)%s";
  };
in
{
  programs.zsh.shellAliases = {
    # git
    g = "git";
    git = "noglob git";

    # git branch
    gb = "git branch";
    gba = "git branch --all --verbose";
    gbd = "git branch --delete";
    gbD = "git branch --delete -D";
    gbm = "git branch --move";
    gbsu = "git branch --set-upstream-to";
    gbsub = "branch=$(git rev-parse --abbrev-ref HEAD); git branch --set-upstream-to='origin/\${branch}' '\${branch}'";
    gbv = "git branch --verbose";
    gbvv = "git branch --verbose --verbose";

    # git checkout
    gco = "git checkout";
    gcob = "git checkout -b";
    gcot = "git checkout --track";
    gcop = "git checkout --patch";

    # git clone
    gcl = "git clone";
    gclr = "git clone --recurse-submodules";
    ghcl = "github-clone";

    # git commit
    gcm = "git commit --verbose";
    gcma = "git commit --verbose --all";
    gcmam = "git commit --all --message";
    gcmamw = "git commit --all --message wip";
    gcmaf = "git commit --all --amend --reuse-message HEAD";
    gcmafpf = "git commit --all --amend --reuse-message HEAD && git push --force-with-lease";
    gcmad = "git commit --amend --date='now'";
    gcmas = "git commit --amend --signoff";
    gcmm = "git commit --message";
    gcmah = "git commit --amend --reuse-message HEAD";
    gcmahs = "git commit --amend --reuse-message HEAD --gpg-sign";
    gcmams = "git commit --verbose --amend --gpg-sign";
    gcmara = "git commit --amend --reset-author";

    # git conflict
    gcfl = "git --no-pager diff --name-only --diff-filter=U";
    gcfa = "git add $(gcfl)";
    gcfe = "git mergetool $(gcfl)";
    gcfo = "git checkout --ours --";
    gcfol = "gcfo $(gcfl)";
    gcft = "git checkout --theirs --";
    gcftl = "gcft $(gcfl)";

    # git-crypt
    gcr = "git-crypt";
    gcri = "git-crypt init";
    gcrs = "git-crypt status";
    gcrlk = "git-crypt lock";
    gcruk = "git-crypt unlock";
    gcrau = "git-crypt add-gpg-user";

    # git ls-files
    gl = "git ls-files";
    glc = "git ls-files --cached";
    glx = "git ls-files --deleted";
    glm = "git ls-files --modified";
    glo = "git ls-files --others --exclude-standard";
    glk = "git ls-files --killed";
    gli = "git status --porcelain --short --ignored | sed -n 's/^!! //p'";

    # git diff
    gd = "git diff";
    gdc = "git diff --cached -w";
    gds = "git diff --staged -w";
    gdp = "git diff --patch";
    gdw = "git diff --ignore-all-space";

    # git fetch
    gf = "git fetch";
    gfa = "git fetch --all";
    gfpr = "git fetch --prune";
    gfapr = "git fetch --all --prune";

    # git grep
    gg = "git grep";
    ggi = "git grep --ignore-case";
    ggf = "git grep --files-with-matches";
    ggfo = "git grep --files-without-matches";
    ggv = "git grep --invert-match";
    ggw = "git grep --word-regexp";

    # git log
    glg = "git log --topo-order --date=short --pretty=format:'${gitLog.oneline}'";
    glgss = "git log --topo-order --pretty=format:'${gitLog.medium}' --show-signature";
    glgst = "git log --topo-order --stat --pretty=format:'${gitLog.medium}'";
    glgd = "git log --topo-order --stat --patch --full-diff --pretty=format:'${gitLog.medium}'";
    glgg = "git log --topo-order --graph --date=short --pretty=format:'${gitLog.oneline}'";
    glgs = "git shortlog --summary --numbered";

    # git merge
    gm = "git merge";
    gma = "git merge --abort";
    gmnc = "git merge --no-commit";
    gmnf = "git merge --no-ff";
    gms = "git merge --squash";
    gmt = "git mergetool";

    # git pull
    gpl = "git pull";
    gpla = "git pull --autostash";
    gplr = "git pull --rebase";
    gplra = "git pull --rebase --autostash";

    # git push
    gp = "git push";
    gpf = "git push --force-with-lease";
    gpa = "git push --all";
    gpat = "git push --all && git push --tags";
    gpt = "git push --tags";
    gpu = "git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)";

    # git rebase
    grb = "git rebase";
    grba = "git rebase --abort";
    grbc = "git rebase --continue";
    grbi = "git rebase --interactive";
    grbs = "git rebase --skip";
    grbso = "git rebase --signoff";

    # git remote
    gre = "git remote";
    grea = "git remote add";
    grerm = "git remote rm";
    grern = "git remote rename";
    grev = "git remote --verbose";
    greup = "git remote update";
    grepr = "git remote prune";
    gresh = "git remote show";

    # git stash
    gst = "git stash";
    gstl = "git stash list";
    gsta = "git stash apply";
    gstp = "git stash pop";
    gstd = "git stash drop";
    gstcl = "git stash clear";
    gsts = "git stash save --include-untracked";
    gstsi = "git stash save --include-untracked --keep-index";
    gstsp = "git stash save --patch --no-keep-index";
    gstsh = "git stash show";
    gstshr = "git stash show | git apply --reverse";
    gstshp = "git stash show --patch --stat";
    gstshpr = "git stash show --patch | patch --reverse";

    # git show
    gsh = "git show";
    gshb = "git show-branch";
    gshba = "git show-branch --all";
    gshp = "git show --pretty=short --show-signature";

    # git submodule
    gsm = "git submodule";
    gsma = "git submodule add";
    gsmf = "git submodule foreach";
    gsmi = "git submodule init";
    gsmm = "git-submodule-move";
    gsms = "git submodule status";
    gsmsy = "git submodule sync";
    gsmup = "git submodule update";
    gsmupr = "git submodule update --recursive";
    gsmuprr = "git submodule update --recursive --remote";
    gsmupir = "git submodule update --init --recursive";
    gsmupirr = "git submodule update --init --recursive --remote";
    gsmpl = "git submodule foreach git pull origin master";
    gsmrm = "git-submodule-remove";

    # git tag
    gtg = "git tag";
    gtgl = "git tag --list";
    gtgs = "git tag --sign";
    gvtg = "git verify-tag";

    # git worktree
    gwt = "git worktree";
    gwta = "git worktree add";
    gwtab = "git worktree add -b";
    gwtaf = "git worktree add --force";
    gwtl = "git worktree list";
    gwtlv = "git worktree list -v";
    gwtm = "git worktree move";
    gwtpr = "git worktree prune";
    gwtprn = "git worktree prune -n";
    gwtr = "git worktree repair";
    gwtrr = "git worktree repair --relative-paths";
    gwtrm = "git worktree remove";
    gwtrmf = "git worktree remove --force";
    gwtlk = "git worktree lock";
    gwtuk = "git worktree unlock";

    # git misc
    gs = "git status";
    gi = "vim .gitignore";
    ga = "git add -A";
    gap = "git add -p";
    guns = "git unstage";
    gunc = "git uncommit";
    grs = "git reset";
    grsh = "git reset --hard";
    gcln = "git clean";
    gclndf = "git clean -df";
    gclndfx = "git clean -dfx";
    gbg = "git bisect good";
    gbb = "git bisect bad";
    gdmb = "git branch --merged | grep -v '\\*' | xargs -n 1 git branch -d";
    gbl = "git blame";
    gcp = "git cherry-pick --ff";
    gcpnc = "git cherry-pick --no-commit";
    grp = "git rev-parse HEAD";
  };
}
