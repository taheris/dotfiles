{ ... }:

{
  programs.zsh.shellAliases = {
    # direnv
    de = "direnv";
    dea = "direnv allow";
    der = "direnv reload";

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

    # gpg
    gpgd = "gpg2 --decrypt";

    # beads
    bdr = "bd ready";
    bds = "bd status";
    bdsh = "bd show";
    bdcr = "bd create";
    bdup = "bd update";
    bdcl = "bd close";
    bdro = "bd reopen";
    bdsr = "bd search";
    bdsa = "bd stats";
    bdd = "bd doctor";

    # beads list
    bdl = "bd list";
    bdla = "bd list --all";
    bdlo = "bd list --status=open";
    bdli = "bd list --status=in_progress";
    bdlc = "bd list --status=closed";
    bdlbl = "bd list --status=blocked";
    bdbl = "bd blocked";

    # beads memories
    bdm = "bd memories";
    bdre = "bd remember";

    # beads dependencies
    bdde = "bd dep";
    bddea = "bd dep add";

    # beads sync
    bdp = "beads-push";
    bddp = "bd dolt push";
    bddpl = "bd dolt pull";
    bdds = "beads-dolt status";
    bddst = "beads-dolt start";
    bddsp = "beads-dolt stop";
    bddrs = "beads-dolt restart";
    bdpf = "bd preflight";
  };
}
