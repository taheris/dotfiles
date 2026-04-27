{ flakeUser, ... }:

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
    nsr = "nix search";
    nsrp = "nix search nixpkgs";

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
    hmbf = "home-manager build --flake ${flakeUser}";
    hme = "home-manager edit";
    hmeg = "home-manager expire-generations";
    hmego = "home-manager expire-generations '-30 days'";
    hmg = "home-manager generations";
    hmh = "home-manager help";
    hmn = "home-manager news";
    hmnf = "home-manager news --flake ${flakeUser}";
    hmo = "home-manager option";
    hmp = "home-manager packages";
    hmrmg = "home-manager remove-generations";
    hms = "home-manager switch";
    hmsf = "home-manager switch --flake ${flakeUser}";
  };
}
