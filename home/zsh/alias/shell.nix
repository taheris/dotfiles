{ pkgs, ... }:

let
  inherit (pkgs.stdenv) isDarwin;

  taheris = "~/src/github.com/taheris";
  dotfiles = "${taheris}/dotfiles";

in
{
  programs.zsh.shellAliases = {
    # terminal
    e = "\${(z)EDITOR}";
    o = (if isDarwin then "open" else "xdg-open");
    ts = "cd ${taheris}";
    dfs = "cd ${dotfiles}";
    org = "cd ${taheris}/org";
    sec = "cd ${taheris}/secrets";

    # cd
    cdb = "cd -";
    cdl = "cd $(ls -tr1 | tail -n-1)";
    "..." = "cd ../..";
    "...." = "cd ../../../";
    "....." = "cd ../../../..";

    # ls
    ls = "ls --color=auto";
    l = "ls -1A";
    ll = "ls -lh";
    la = "ll -A";
    lr = "ll -R";
    lt = "ll -tr";
    lc = "lt -c";
    lu = "lt -u";
    lk = "ll -Sr";
    lh = "ll -at | head";
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
    sudo = "sudo ";
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
    scp = "noglob scp";
    sftp = "noglob sftp";

    # fzf
    f = "fzf";
    fj = "fzf-json";
    fp = "fzf --preview";

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
  };
}
