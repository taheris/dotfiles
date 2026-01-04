{ pkgs, ... }:

let
  inherit (pkgs.stdenv) isDarwin;

  gitPersonal = "~/src/github.com/taheris";
  dotfiles = "${gitPersonal}/dotfiles";
  aliasFile = "${dotfiles}/home/zsh/alias.nix";

  gitLog = {
    medium = "%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B";
    oneline = "%C(blue)%cd %C(yellow)%h%C(red)%d %C(white)%s";
  };
in
{
  programs.zsh.shellGlobalAliases = {
    # flags
    H = " --help";
    V = " --version";

    # misc
    C = "| ${if isDarwin then "pbcopy" else "wl-copy"}";
    F = "| fzf";
    G = "| grep";
    EG = "| egrep";
    FG = "| fgrep";
    L = "| less";
    S = "| sort";
    U = "| uniq ";
    X = "| xargs ";
    XI = "| xargs -I{} ";
    HH = "| head -n 1";
    TT = "| tail -n -1";
    T = "| tail -n +2";
    CC = "| wc -c | tr -d ' '";
    CL = "| wc -l | tr -d ' '";
    CW = "| wc -w | tr -d ' '";
    LC = "| tr '[:upper:]' '[:lower:]'";
    UC = "| tr '[:lower:]' '[:upper:]'";
    OC = "| openssl s_client -ign_eof -connect";

    # redirects
    N = ">/dev/null";
    ON = "1>/dev/null";
    EN = "2>/dev/null";
    EO = "2>&1";
    IR = "</dev/urandom";
    IZ = "</dev/zero";

    # awk
    A1 = "| awk '{print $1}'";
    A2 = "| awk '{print $2}'";
    A3 = "| awk '{print $3}'";
    A4 = "| awk '{print $4}'";
    A5 = "| awk '{print $5}'";
    A6 = "| awk '{print $6}'";
    A7 = "| awk '{print $7}'";
    A8 = "| awk '{print $8}'";
    A9 = "| awk '{print $9}'";
    AL = "| awk '{print $NF}'";

    # kubernetes
    LT = " --selector='app.kubernetes.io/managed-by=tilt' -oname";
    NA = " --all-namespaces";
    NI = " --namespace=ingress-nginx";
    NS = " --namespace=kube-system";
    OJ = " --output=json";
    OY = " --output=yaml";

    # rust
    XL = " -- . ':(exclude)*.lock'";

    # nix
    AS = " --all-systems";
    ST = " --show-trace";
    STV = " --show-trace --print-build-logs --verbose";
  };

  programs.zsh.shellAliases = {
    # terminal
    e = "\${(z)EDITOR}";
    o = (if isDarwin then "open" else "xdg-open");
    ae = "vim ${aliasFile}";
    dfs = "cd ${dotfiles}";
    org = "cd ${gitPersonal}/org";
    sec = "cd ${gitPersonal}/secrets";

    # cd
    cdb = "cd -";
    cdl = "cd $(ls -tr1 | tail -n-1)";
    "..." = "cd ../..";
    "...." = "cd ../../../";
    "....." = "cd ../../../..";

    # ls
    ls = "ls --color=auto";
    l = "ls -1A"; # Lists in one column, hidden files.
    ll = "ls -lh"; # Lists human readable sizes.
    la = "ll -A"; # Lists hidden files.
    lr = "ll -R"; # Lists recursively.
    lt = "ll -tr"; # Lists sorted by time.
    lc = "lt -c"; # Lists sorted by time, shows change time.
    lu = "lt -u"; # Lists sorted by time, shows access time.
    lk = "ll -Sr"; # Lists sorted by size, largest last.
    lh = "ll -at | head"; # Lists the most recently modified files.
    llh = "ll -H";

    # interactive
    mv = "mv -i";
    cp = "cp -i";
    ln = "ln -i";

    # du
    du = "du -h";
    du0 = "du -d 0";
    du1 = "du -d 1";
    du1s = "du -d 1 | sort --human-numeric-sort";
    du2 = "du -d 2";
    du2s = "du -d 2 | sort --human-numeric-sort";
    du3 = "du -d 3";
    du3s = "du -d 3 | sort --human-numeric-sort";

    # fd
    fdh = "fd --hidden --no-ignore --follow";
    fde = "fd --extension";
    fdf = "fd --type file";
    fdfh = "fd --type file --hidden";
    fdd = "fd --type directory";
    fdl = "fd --type symlink";
    fdx = "fd --type executable";
    fdem = "fd --type empty";

    # ps
    psw = "ps ww";
    psa = "ps auxww";

    # misc
    sudo = "sudo "; # use aliases with sudo
    less = "less -R --quit-if-one-screen --redraw-on-quit";
    tf = "tail -f";
    cl = "clear";
    cls = "clear;ls";
    df = "df -h";
    en = "echo -n";
    gz = "tar -zcvf";
    ka9 = "killall -9";
    k9 = "kill -9";
    sedi = "sed -i ''";
    digs = "dig +short";
    pw = "LC_ALL=C tr -dc '[:print:]' < /dev/urandom | head -c";
    bc = "bc --mathlib";
    locf = "loc --files";
    locu = "loc -uu";
    t2 = "tree -L 2";
    iso = "date -u +'%Y-%m-%dT%H:%M:%SZ'";
    sql = "sqlite3 -column -header -batch";

    # noglob
    find = "noglob find";
    git = "noglob git";
    scp = "noglob scp";
    sftp = "noglob sftp";

    # systemctl
    sc = "systemctl";
    scl = "systemctl list-units";
    sclf = "systemctl list-units --state=failed";
    sclr = "systemctl list-units --state=running";
    scs = "systemctl status";
    scst = "systemctl start";
    scsp = "systemctl stop";
    sce = "systemctl enable";
    scd = "systemctl disable";
    scrl = "systemctl reload";
    scrs = "systemctl restart";
    scu = "systemctl --user";
    scus = "systemctl --user status";
    scust = "systemctl --user start";
    scusp = "systemctl --user stop";
    scue = "systemctl --user enable";
    scud = "systemctl --user disable";
    scurl = "systemctl --user reload";
    scurs = "systemctl --user restart";

    # journalctl
    jc = "journalctl";
    jcf = "journalctl --follow";
    jcb = "journalctl --boot";
    jcb1 = "journalctl --boot -1";
    jcb2 = "journalctl --boot -2";
    jcp = "journalctl --boot --priority";
    jcpe = "journalctl --boot --priority err";
    jcpw = "journalctl --boot --priority warning";
    jcu = "journalctl --pager-end --user-unit";
    jcuf = "journalctl --follow --user-unit";

    # fzf
    f = "fzf";
    fj = "fzf-json";
    fp = "fzf --preview";

    # git
    g = "git";

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
    gc = "git commit --verbose";
    gca = "git commit --verbose --all";
    gcam = "git commit --all --message";
    gcamw = "git commit --all --message wip";
    gcaf = "git commit --all --amend --reuse-message HEAD";
    gcafpf = "git commit --all --amend --reuse-message HEAD && git push --force-with-lease";
    gcad = "git commit --amend --date='now'";
    gcas = "git commit --amend --signoff";
    gcm = "git commit --message";
    gcah = "git commit --amend --reuse-message HEAD";
    gcahs = "git commit --amend --reuse-message HEAD --gpg-sign";
    gcams = "git commit --verbose --amend --gpg-sign";
    gcara = "git commit --amend --reset-author";

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
    gcrl = "git-crypt lock";
    gcru = "git-crypt unlock";
    gcra = "git-crypt add-gpg-user";

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
    gt = "git tag";
    gtl = "git tag --list";
    gts = "git tag --sign";
    gvt = "git verify-tag";

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

    # brew
    bi = "brew info";
    bin = "brew install";
    binc = "brew install --cask";
    bun = "brew uninstall";
    bunc = "brew uninstall --cask";
    brin = "brew reinstall";
    brinc = "brew reinstall --cask";
    bl = "brew list";
    blc = "brew list --cask";
    bln = "brew link";
    blno = "brew link --overwrite";
    buln = "brew unlink";
    bo = "brew outdated";
    boc = "brew outdated --cask";
    bs = "brew search";
    bup = ''
      brew update && \
      brew upgrade && \
      brew upgrade --cask && \
      brew cleanup && \
      brew doctor'
    '';

    # brew services
    bsl = "brew services list";
    bsr = "brew services run";
    bsst = "brew services start";
    bssp = "brew services stop";
    bsrs = "brew services restart";
    bsc = "brew services cleanup";

    # doom
    dm = "doom";
    dmb = "doom build";
    dmd = "doom doctor";
    dme = "doom env";
    dmh = "doom help";
    dmi = "doom info";
    dmp = "doom purge";
    dmv = "doom version";
    dmin = "doom install";
    dmpup = "~/bin/doom-pin-update.sh";
    dmpupd = "~/bin/doom-pin-update.sh --dry-run";
    dmsy = "doom sync";
    dmsypr = "doom sync --prune";
    dmsyr = "doom sync --rebuild";
    dmsyu = "doom sync -u";
    dmup = "doom upgrade";
    dmupp = "doom upgrade --packages";

    # gpg
    gpgd = "gpg2 --decrypt";

    # log
    lgcl = "log collect";
    lgc = "log config";
    lge = "log erase";
    lgsh = "log show";
    lgs = "log stream";
    lgsp = "log stream --process";
    lgst = "log stats";

    # plist
    plp = "plutil -p --";
    plj = "plutil -convert json -r -o - --";
    plx = "plutil -convert xml1 -o - --";
    plb = "plutil -convert binary1 -o - --";

    # docker container
    dca = "docker container attach";
    dcc = "docker container commit";
    dccp = "docker container cp";
    dccr = "docker container create";
    dcd = "docker container diff";
    dcx = "docker container exec --interactive --tty";
    dcxr = "docker container exec --interactive --tty --user 0:0";
    dcxu = "docker container exec --interactive --tty --user \"$(id -u):$(id -g)\"";
    dcep = "docker container export";
    dci = "docker container inspect";
    dck = "docker container kill";
    dclg = "docker container logs";
    dclgf = "docker container logs --follow";
    dcl = "docker container ls";
    dcla = "docker container ls --all";
    dcpe = "docker container pause";
    dcp = "docker container port";
    dcpr = "docker container prune";
    dcrn = "docker container rename";
    dcrm = "docker container rm";
    dcrmv = "docker container rm --volumes";
    dcr = "docker container run --interactive --tty --rm";
    dcre = "dcr --entrypoint";
    dcreb = "dcr --entrypoint bash";
    dcres = "dcr --entrypoint sh";
    dcrnh = "dcr --net=host";
    dcrns = "dcr --privileged --pid=host justincormack/nsenter1";
    dcrr = "docker container run --interactive --tty --user 0:0";
    dcru = "$(printf 'docker container run --interactive --tty --user %s:%s' $(id -u) $(id -g))";
    dcst = "docker container start";
    dcsp = "docker container stop";
    dcs = "docker container stats";
    dct = "docker container top";
    dcupe = "docker container unpause";
    dcup = "docker container update";
    dcw = "docker container wait";

    # docker compose
    dcm = "docker compose";
    dcmf = "docker compose --file";
    dcmb = "docker compose build";
    dcmc = "docker compose config";
    dcmcr = "docker compose create";
    dcmd = "docker compose down --timeout 0";
    dcmev = "docker compose events";
    dcmx = "docker compose exec";
    dcmim = "docker compose images";
    dcmk = "docker compose kill";
    dcmlg = "docker compose logs";
    dcmp = "docker compose ps";
    dcmpl = "docker compose pull";
    dcmps = "docker compose push";
    dcmrs = "docker compose restart --timeout 0";
    dcmrm = "docker compose rm";
    dcmrn = "docker compose run";
    dcmst = "docker compose start";
    dcmsp = "docker compose stop --timeout 0";
    dcmt = "docker compose top";
    dcmu = "docker compose up --timeout 0";

    # docker image
    dil = "docker image ls";
    dila = "docker image ls --all";
    dib = "docker image build --force-rm";
    dibt = "docker image build --force-rm --tag";
    dii = "docker image inspect";
    dih = "docker image history";
    diip = "docker image import";
    dild = "docker image load";
    dips = "docker image push";
    dipl = "docker image pull";
    dipr = "docker image prune";
    dipra = "docker image prune --all";
    dirm = "docker image rm";
    dis = "docker image save";
    dit = "docker image tag";

    # docker network
    dnc = "docker network create";
    dncn = "docker network connect";
    dndc = "docker network disconnect";
    dni = "docker network inspect";
    dnl = "docker network ls";
    dnpr = "docker network prune";
    dnrm = "docker network rm";

    # docker system
    dse = "docker system events";
    dsi = "docker system info";
    dsdf = "docker system df";
    dsdfv = "docker system df --verbose";
    dspr = "docker system prune";
    dspra = "docker system prune --all";
    dsprv = "docker system prune --volumes";
    dsprav = "docker system prune --all --volumes";

    # docker volume
    dv = "docker volume";
    dvc = "docker volume create";
    dvi = "docker volume inspect";
    dvl = "docker volume ls";
    dvpr = "docker volume prune";
    dvrm = "docker volume rm";

    # cargo
    cb = "cargo build";
    cbb = "cargo build --bin";
    cbe = "cargo build --examples";
    cbr = "cargo build --release";
    cbrm = "cargo build --release --target=x86_64-unknown-linux-musl";
    cbaf = "cargo build --all-features";
    cbn = "cargo bench";
    cbnaf = "cargo bench --all-features";
    cbnat = "cargo bench --all-targets";
    cbnaft = "cargo clippy --all-features --all-targets --workspace";
    ct = "cargo test";
    ctl = "cargo test --lib";
    ctaf = "cargo test --all-features";
    ctlaf = "cargo test --lib --all-features";
    ctnc = "cargo test -- --nocapture";
    ctafnc = "cargo test --all-features -- --nocapture";
    ctlafnc = "cargo test --lib --all-features -- --nocapture";
    ccln = "cargo clean";
    cdoc = "cargo doc";
    cdoco = "cargo doc --open";
    cn = "cargo new";
    cr = "cargo run";
    cre = "cargo run --example";
    crr = "cargo run --release";
    cck = "cargo check";
    cckaf = "cargo check --all-features";
    cckat = "cargo check --all-targets";
    cckaft = "cargo check --all-features --all-targets --workspace";
    cckw = "cargo check --workspace";
    ccl = "cargo clippy";
    cclaf = "cargo clippy --all-features -- -Dwarnings -Drust-2018-idioms";
    cclat = "cargo clippy --all-targets";
    cclaft = "cargo clippy --all-features --all-targets --workspace";
    cclw = "cargo clippy --workspace";
    cup = "cargo update";
    cupp = "cargo update --package";
    cs = "cargo search";
    cin = "cargo install";
    cinf = "cargo install --force";
    cinp = "cargo install --path";
    cinpd = "cargo install --path .";
    cun = "cargo uninstall";
    cx = "cargo expand";
    cxb = "cargo expand --bin";
    cxl = "cargo expand --lib";
    cxaf = "cargo expand --all-features";
    cod = "cargo outdated";
    codr = "cargo outdated --root-deps-only";

    # cargo +nightly
    cnb = "cargo +nightly build";
    cnbr = "cargo +nightly build --release";
    cnbaf = "cargo +nightly build --all-features";
    cnbc = "cargo +nightly bench";
    cnbcaf = "cargo +nightly bench --all-features";
    cnt = "cargo +nightly test";
    cntaf = "cargo +nightly test --all-features";
    cnn = "cargo +nightly new";
    cnr = "cargo +nightly run";
    cnin = "cargo +nightly install";
    cnun = "cargo +nightly uninstall";

    # rustup
    ru = "rustup";
    rus = "rustup show";
    ruup = "rustup update";
    rusup = "rustup self update";
    rud = "rustup default";
    rutc = "rustup toolchain";
    rutcl = "rustup toolchain list";
    rutcin = "rustup toolchain install";
    rutcun = "rustup toolchain uninstall";
    ruta = "rustup target";
    rutal = "rustup target list";
    rutaa = "rustup target add";
    rutar = "rustup target remove";
    rucl = "rustup component list";
    ruca = "rustup component add";
    rucr = "rustup component remove";
    ruo = "rustup override";
    ruol = "rustup override list";
    ruos = "rustup override set";
    ruou = "rustup override unset";
    rur = "rustup run";
    ruw = "rustup which";
    rudoc = "rustup doc";
    ruh = "rustup help";
    rusp = "rustup set profile";
    ruspm = "rustup set profile minimal";
    ruspd = "rustup set profile default";
    ruspc = "rustup set profile complete";

    # ripgrep
    rg = "rg --sort-files --follow --no-messages --max-columns 180";
    rgf = "rg --files";
    rgfh = "rg --files --hidden";
    rgh = "rg --hidden";
    rgi = "rg --no-ignore";
    rgb = "rg-boundary";
    rgl = "rg-limit";
    rgt = "rg --type";
    rgc = "rg --type c";
    rgcmake = "rg --type cmake";
    rgcpp = "rg --type cpp";
    rgcss = "rg --type css";
    rggo = "rg --type go";
    rghtml = "rg --type html";
    rgjs = "rg --type js";
    rgjson = "rg --type json";
    rgmd = "rg --type markdown";
    rgorg = "rg --type org";
    rgpy = "rg --type py";
    rgrm = "rg --type readme";
    rgrb = "rg --type ruby";
    rgrs = "rg --type rust";
    rgsc = "rg --type scala";
    rgsh = "rg --type sh";
    rgsql = "rg --type sql";
    rgsw = "rg --type swift";
    rgtoml = "rg --type toml";
    rgtxt = "rg --type txt";
    rgxml = "rg --type xml";

    # go
    gor = "go run";
    gog = "go generate";
    got = "go test";
    gotv = "go test -v";
    goti = "go test -tags=integration";
    gotiv = "go test -tags=integration -v";
    gotr = "go test ./...";
    gotrv = "go test ./... -v";
    gob = "go test -run=NONE -bench=.";

    # kubectl
    k = "kubectl";
    ka = "kubectl apply";
    kaf = "kubectl apply --filename";
    klg = "kubectl logs";
    klgf = "kubectl logs --follow";
    klgp = "kubectl logs --previous";
    kp = "kubectl proxy";
    kpf = "kubectl port-forward";
    kr = "kubectl run --rm --stdin --tty";
    kx = "kubectl exec --stdin --tty";

    # kubectl get
    kg = "kubectl get";
    kga = "kubectl get all";
    kgd = "kubectl get deployment";
    kgev = "kubectl get event";
    kgi = "kubectl get ingress";
    kgj = "kubectl get jobs";
    kgp = "kubectl get pods";
    kgpi = "kubectl get pods -o json | jq -r '.items | .[] | (.spec?.containers? | .[]? | .image?)' | sort --unique";
    kgn = "kubectl get nodes";
    kgcm = "kubectl get configmap";
    kgns = "kubectl get namespaces";
    kgpv = "kubectl get persistentvolumes";
    kgpvc = "kubectl get persistentvolumeclaims";
    kgrs = "kubectl get replicaset";
    kgsec = "kubectl get secret";
    kgsvc = "kubectl get service";
    kgss = "kubectl get statefulset";

    # kubectl describe
    kd = "kubectl describe";
    kda = "kubectl describe all";
    kdd = "kubectl describe deployment";
    kdi = "kubectl describe ingress";
    kdj = "kubectl describe jobs";
    kdp = "kubectl describe pods";
    kdn = "kubectl describe nodes";
    kdcm = "kubectl describe configmap";
    kdns = "kubectl describe namespaces";
    kdpv = "kubectl describe persistentvolumes";
    kdpvc = "kubectl describe persistentvolumeclaims";
    kdrs = "kubectl describe replicaset";
    kdsec = "kubectl describe secret";
    kdsvc = "kubectl describe service";
    kdss = "kubectl describe statefulset";

    # kubectl config
    kcv = "kubectl config view";
    kccc = "kubectl config current-context";
    kcdc = "kubectl config delete-context";
    kcdcl = "kubectl config delete-cluster";
    kcgc = "kubectl config get-contexts";
    kcgcl = "kubectl config get-clusters";
    kcrc = "kubectl config rename-context";
    kcs = "kubectl config set";
    kcsc = "kubectl config set-context";
    kcscc = "kubectl config set-context --current";
    kcsccns = "kubectl config set-context --current --namespace";
    kcscl = "kubectl config set-cluster";
    kcscr = "kubectl config set-credentials";
    kcu = "kubectl config unset";
    kcuc = "kubectl config use-context";
    kcucdd = "kubectl config use-context docker-desktop";
    kcucrd = "kubectl config use-context rancher-desktop";

    # kubectl edit
    ked = "kubectl edit";
    keda = "kubectl edit all";
    kedd = "kubectl edit deployment";
    kedi = "kubectl edit ingress";
    kedj = "kubectl edit jobs";
    kedp = "kubectl edit pods";
    kedn = "kubectl edit nodes";
    kedcm = "kubectl edit configmap";
    kedns = "kubectl edit namespaces";
    kedpv = "kubectl edit persistentvolumes";
    kedpvc = "kubectl edit persistentvolumeclaims";
    kedrs = "kubectl edit replicaset";
    kedsec = "kubectl edit secret";
    kedsvc = "kubectl edit service";
    kedss = "kubectl edit statefulset";

    # kubectl delete
    kdel = "kubectl delete";
    kdeld = "kubectl delete deployment";
    kdeli = "kubectl delete ingress";
    kdelj = "kubectl delete jobs";
    kdelp = "kubectl delete pods";
    kdeln = "kubectl delete nodes";
    kdelcm = "kubectl delete configmap";
    kdelns = "kubectl delete namespaces";
    kdelpv = "kubectl delete persistentvolumes";
    kdelpvc = "kubectl delete persistentvolumeclaims";
    kdelrs = "kubectl delete replicaset";
    kdelsec = "kubectl delete secret";
    kdelsvc = "kubectl delete service";
    kdelss = "kubectl delete statefulset";

    # direnv
    de = "direnv";
    dea = "direnv allow";
    der = "direnv reload";

    # nix build
    nb = "nix build";
    nbf = "nix build --file";
    nbk = "nix build --keep-failed";

    # nix channel
    nc = "nix-channel";
    nca = "nix-channel --add";
    ncl = "nix-channel --list";
    ncrm = "nix-channel --remove";
    ncup = "nix-channel --update";

    # nix develop
    nd = "nix develop";
    ndz = "nix develop --command zsh";

    # nix-env
    ne = "nix-env";
    nedg = "nix-env --profile /nix/var/nix/profiles/system --delete-generations";

    # nix flake
    nf = "nix flake";
    nfa = "nix flake archive";
    nfc = "nix flake check";
    nfcl = "nix flake clone";
    nfi = "nix flake init";
    nfl = "nix flake lock";
    nfm = "nix flake metadata";
    nfn = "nix flake new";
    nfp = "nix flake prefetch";
    nfs = "nix flake show";
    nfup = "nix flake update";

    # nix hash
    nh = "nix hash";
    nhc = "nix hash convert";
    nhc16 = "nix hash convert --to nix16";
    nhc32 = "nix hash convert --to nix32";
    nhc64 = "nix hash convert --to nix64";
    nhf = "nix hash file";
    nhp = "nix hash path";

    # nix-locate
    nl = "nix-locate";
    nlp = "nix-locate --package";
    nlr = "nix-locate --regex";
    nlw = "nix-locate --whole-name";

    # nix profile
    np = "nix profile";
    npl = "nix profile list";
    npin = "nix profile install";
    nph = "nix profile history";
    nprb = "nix profile rollback";
    nprbt = "nix profile rollback --to";
    nprm = "nix profile remove";
    npup = "nix profile upgrade";
    npupa = "nix profile upgrade --all";
    npwh = "nix profile wipe-history";

    # nix repl
    nrp = "nix repl";
    nrpf = "expect -c 'spawn nix repl; expect \"nix-repl>\"; send \":load-flake .\\n\"; interact'";
    nrpp = "nix repl --expr 'import <nixpkgs> {}'";

    # nix run
    nr = "nix run";

    # nix search
    ns = "nix search";
    nsp = "nix search nixpkgs";

    # nix-shell
    nsh = "nix-shell";
    nshc = "nix-shell --command";
    nshcs = "nix-shell --command \${SHELL}";
    nshcsp = "nix-shell --command \${SHELL} --packages";
    nshp = "nix-shell --packages";

    # nix store
    nst = "nix store";
    nstgc = "nix store gc";
    nstr = "nix store repair";
    nstra = "nix store repair --all";
    nstv = "nix store verify";
    nstva = "nix store verify --all";
    ncg = "nix-collect-garbage";
    ncgd = "nix-collect-garbage --delete";
    ncgdo = "nix-collect-garbage --delete-older-than 30d";

    # nixos
    nobv = "nixos-build-vms";
    noc = "nixos-container";
    noe = "nixos-enter";
    noft = "nixos-firewall-tool";
    nogc = "nixos-generate-config";
    noh = "nixos-help";
    noin = "nixos-install";
    noo = "nixos-option";
    nov = "nixos-version";

    # nixos-rebuild
    nor = "nixos-rebuild";
    norbt = "nixos-rebuild boot";
    norb = "nixos-rebuild build";
    norbv = "nixos-rebuild build-vm";
    norbvb = "nixos-rebuild build-vm-with-bootloader";
    norlg = "nixos-rebuild list-generations";
    norda = "nixos-rebuild dry-activate";
    nordb = "nixos-rebuild dry-build";
    nors = "nixos-rebuild switch";
    nort = "nixos-rebuild test";

    # home-manager
    hm = "home-manager";
    hmb = "home-manager build";
    hmbf = "home-manager build --flake ${dotfiles}";
    hme = "home-manager edit";
    hmeg = "home-manager expire-generations";
    hmego = "home-manager expire-generations '-30 days'";
    hmg = "home-manager generations";
    hmh = "home-manager help";
    hmn = "home-manager news";
    hmnf = "home-manager news --flake ${dotfiles}";
    hmo = "home-manager option";
    hmp = "home-manager packages";
    hmrmg = "home-manager remove-generations";
    hms = "home-manager switch";
    hmsf = "home-manager switch --flake ${dotfiles}";

    # darwin-rebuild
    dr = "darwin-rebuild";
    drlg = "darwin-rebuild --list-generations";
    drs = "darwin-rebuild switch";
    drsf = "darwin-rebuild switch --flake ${dotfiles}";
    drsg = "darwin-rebuild --switch-generation";
  };
}
