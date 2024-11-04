{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkMerge;
  inherit (lib.meta) getExe;
  inherit (pkgs.stdenv) isCygwin isDarwin isLinux;

  package = pkgs.emacs29-pgtk;

  doom = "${config.xdg.configHome}/doom";
  emacs = "${config.xdg.configHome}/emacs";

in
{
  programs.emacs = {
    enable = true;
    inherit package;
  };

  services.emacs = mkIf isLinux {
    enable = true;
    inherit package;
    client.enable = true;
  };

  home = {
    activation.doomEmacs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="$PATH:${config.programs.emacs.package}/bin:${pkgs.git}/bin:${emacs}/bin"
      if [[ ! -d ${emacs} ]]; then
        git clone --depth 1 https://github.com/doomemacs/doomemacs ${emacs}
        doom install
      fi
    '';

    file.doomConfig = {
      source = ./config.org;
      target = "${doom}/config.org";
      onChange = ''
        ${getExe package} --batch \
          --eval "(require 'ob-tangle)" \
          --eval "(setq org-confirm-babel-evaluate t)" \
          --eval "(setq IS-LINUX ${if isLinux then "t" else "nil"})" \
          --eval "(setq IS-MAC ${if isDarwin then "t" else "nil"})" \
          --eval "(setq IS-WINDOWS ${if isCygwin then "t" else "nil"})" \
          --eval "(org-babel-tangle-file \"${doom}/config.org\")"

        ${emacs}/bin/doom sync -e
      '';
    };

    packages =
      let
        basePackages = with pkgs; [
          (aspellWithDicts (
            dicts: with dicts; [
              en
              en-computers
              en-science
            ]
          ))
          d2
          ltex-ls
          marksman
          sqlite
          yaml-language-server
        ];

        emacsPackages = with pkgs.emacsPackages; [ vterm ];
      in
      mkMerge [
        basePackages
        emacsPackages
      ];

    sessionPath = [ "${emacs}/bin" ];
  };
}
