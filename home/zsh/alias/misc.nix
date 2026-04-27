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
    bds = "bd show";
    bdcr = "bd create";
    bdup = "bd update";
    bdcl = "bd close";
    bdbl = "bd blocked";
    bdd = "bd doctor";
    bdsr = "bd search";
    bdsa = "bd stats";

    # beads list
    bdl = "bd list";
    bdla = "bd list --all";
    bdlo = "bd list --status=open";
    bdli = "bd list --status=in_progress";
    bdlc = "bd list --status=closed";
    bdlbl = "bd list --status=blocked";

    # beads memories
    bdm = "bd memories";
    bdre = "bd remember";

    # beads dependencies
    bdde = "bd dep";
    bddea = "bd dep add";

    # beads sync
    bp = "beads-push";
    bddp = "bd dolt push";
    bddpl = "bd dolt pull";
    bdds = "beads-dolt status";
    bddst = "beads-dolt start";
    bddsp = "beads-dolt stop";
    bddrs = "beads-dolt restart";
    bdpf = "bd preflight";

    # gascity
    gcyi = "gc init";
    gcys = "gc status";
    gcyst = "gc start";
    gcysp = "gc stop";
    gcyrs = "gc restart";
    gcyrl = "gc reload";
    gcysu = "gc suspend";
    gcyre = "gc resume";
    gcyd = "gc doctor";
    gcyv = "gc version";
    gcysl = "gc sling";
    gcyev = "gc events";
    gcybd = "gc bd";
    gcyho = "gc handoff";

    # gascity session
    gcyse = "gc session";
    gcysea = "gc session attach";
    gcysel = "gc session list";
    gcysen = "gc session new";
    gcyses = "gc session submit";
    gcysep = "gc session peek";

    # gascity mail
    gcym = "gc mail";
    gcymi = "gc mail inbox";
    gcyms = "gc mail send";
    gcymc = "gc mail check";
    gcymr = "gc mail read";

    # gascity rig
    gcyrg = "gc rig";
    gcyrga = "gc rig add";
    gcyrgl = "gc rig list";
  };
}
