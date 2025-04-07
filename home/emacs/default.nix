{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) concatStringsSep mkIf mkMerge;
  inherit (lib.hm) dag;
  inherit (lib.meta) getExe;
  inherit (pkgs.stdenv) isCygwin isDarwin isLinux;

  package =
    with pkgs;
    (emacsPackagesFor (emacs30-pgtk.override { withNativeCompilation = false; })).emacsWithPackages
      (epkgs: [ epkgs.vterm ]);

  doom = "${config.xdg.configHome}/doom";
  emacs = "${config.xdg.configHome}/emacs";

  path = concatStringsSep ":" [
    "$PATH"
    "${config.programs.emacs.package}/bin"
    "${pkgs.git}/bin"
    "${emacs}/bin"
  ];

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
    activation.doomEmacs = dag.entryAfter [ "writeBoundary" ] ''
      if [[ ! -d ${emacs} ]]; then
        export PATH=${path}
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

        export PATH=${path}
        export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
        export SSL_CERT_DIR=${pkgs.cacert}/etc/ssl/certs

        doom sync -e
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
          sqlite-vss
          yaml-language-server
        ];

        emacsPackages = with pkgs.emacsPackages; [ vterm ];

        nodePackages = with pkgs.nodePackages; [
          prettier
          vscode-langservers-extracted
        ];
      in
      mkMerge [
        basePackages
        emacsPackages
        nodePackages
      ];

    sessionPath = [ "${emacs}/bin" ];
  };

  sops.templates.authinfo = {
    path = "${config.home.homeDirectory}/.authinfo";
    content = ''
      machine api.anthropic.com login apikey password ${config.sops.placeholder.anthropic}
      machine api.cerebras.ai login apikey password ${config.sops.placeholder.cerebras}
      machine api.openai.com login apikey password ${config.sops.placeholder.openai}
      machine irc.libera.chat login proto1 password ${config.sops.placeholder.libera}
    '';
  };
}
