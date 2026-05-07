{ lib, pkgs, ... }:

let
  inherit (lib) optionalAttrs;
  inherit (pkgs.stdenv) isDarwin isLinux;

  gitPersonal = "~/src/github.com/taheris";
  dotfiles = "${gitPersonal}/dotfiles";
  sshBuilder = "ssh -i /etc/nix/builder_ed25519 builder@linux-builder";

in
{
  programs.zsh.shellAliases =
    { }

    # darwin-specific
    // optionalAttrs isDarwin {
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
      bsr = "brew search";
      bup = ''
        brew update && \
        brew upgrade && \
        brew upgrade --cask && \
        brew cleanup && \
        brew doctor'';

      # brew services
      bsvl = "brew services list";
      bsvr = "brew services run";
      bsvst = "brew services start";
      bsvsp = "brew services stop";
      bsvrs = "brew services restart";
      bsvc = "brew services cleanup";

      # log
      lgcl = "log collect";
      lgc = "log config";
      lge = "log erase";
      lgsh = "log show";
      lgs = "log stream";
      lgsp = "log stream --process";
      lgsa = "log stats";

      # plist
      plp = "plutil -p --";
      plj = "plutil -convert json -r -o - --";
      plx = "plutil -convert xml1 -o - --";
      plb = "plutil -convert binary1 -o - --";

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
      lbvr = "sudo ${sshBuilder} 'nix-store --verify --repair'";
      lbvcr = "sudo ${sshBuilder} 'nix-store --verify --check-contents --repair'";

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

    # linux-specific
    // optionalAttrs isLinux {
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
