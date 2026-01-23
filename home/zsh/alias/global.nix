{ pkgs, ... }:

let
  inherit (pkgs.stdenv) isDarwin;
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
}
