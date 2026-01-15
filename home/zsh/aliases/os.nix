{ lib, pkgs, ... }:

let
  inherit (pkgs.stdenv) isDarwin isLinux;

  gitPersonal = "~/src/github.com/taheris";
  dotfiles = "${gitPersonal}/dotfiles";
in
{
  programs.zsh.shellAliases = {
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
    nflk = "nix flake lock";
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
  }

  # darwin-specific aliases
  // lib.optionalAttrs isDarwin {
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
      brew doctor'';

    # brew services
    bsl = "brew services list";
    bsr = "brew services run";
    bsst = "brew services start";
    bssp = "brew services stop";
    bsrs = "brew services restart";
    bsc = "brew services cleanup";

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

    # apple container
    ac = "container";
    acb = "container build";
    accr = "container create";
    ack = "container kill";
    acl = "container list";
    acla = "container list --all";
    aclg = "container logs";
    acr = "container run";
    acrm = "container delete";
    acsa = "container stats";
    acsp = "container stop";
    acst = "container start";

    # apple container image
    aci = "container image";
    acii = "container image inspect";
    acil = "container image list";
    acild = "container image load";
    acipl = "container image pull";
    acipr = "container image prune";
    acirm = "container image delete";
    acis = "container image save";
    acitg = "container image tag";

    # apple container network
    acn = "container network";
    acncr = "container network create";
    acni = "container network inspect";
    acnl = "container network list";
    acnrm = "container network delete";

    # apple container system
    acs = "container system";
    acsd = "container system dns";
    acsdf = "container system df";
    acsk = "container system kernel";
    acslg = "container system logs";
    acss = "container system status";
    acssp = "container system stop";
    acsst = "container system start";

    # apple container volume
    acv = "container volume";
    acvcr = "container volume create";
    acvi = "container volume inspect";
    acvl = "container volume list";
    acvpr = "container volume prune";
    acvrm = "container volume delete";

    # darwin-rebuild
    dr = "darwin-rebuild";
    drlg = "darwin-rebuild --list-generations";
    drs = "darwin-rebuild switch";
    drsf = "darwin-rebuild switch --flake ${dotfiles}";
    drsg = "darwin-rebuild --switch-generation";

    # linux-builder
    lbp = "launchctl print system/org.nixos.linux-builder";
    lbst = "sudo launchctl start org.nixos.linux-builder";
    lbsp = "sudo launchctl stop org.nixos.linux-builder";

    # wrapix-builder
    wb = "wrapix-builder";
    wbc = "wrapix-builder config";
    wbs = "wrapix-builder status";
    wbsu = "wrapix-builder setup";
    wbsur = "wrapix-builder setup-routes";
    wbsush = "wrapix-builder setup-ssh";
    wbst = "wrapix-builder start";
    wbsp = "wrapix-builder stop";
    wbsh = "wrapix-builder ssh";
  }

  # linux-specific aliases
  // lib.optionalAttrs isLinux {
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
  };
}
