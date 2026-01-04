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
    let
      pkg = if isDarwin then emacs30-pgtk.override { withNativeCompilation = false; } else emacs30-pgtk;
    in
    (emacsPackagesFor pkg).emacsWithPackages (epkgs: [ epkgs.vterm ]);

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
  programs = {
    emacs = {
      enable = true;
      inherit package;
    };

    calibre = mkIf isLinux {
      enable = true;
    };
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

    file = {
      doomConfig = {
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

      ".config/emacs/.local/cache/tree-sitter".source =
        "${pkgs.emacsPackages.treesit-grammars.with-all-grammars}/lib";
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
          hunspell
          hunspellDicts.en-gb-large
          hunspellDicts.en-us-large
          ltex-ls
          sqlite
          tinymist
          tree-sitter-grammars.tree-sitter-typst
          (typst.withPackages (ps: [
            ps.fontawesome
            ps.moderner-cv
          ]))
          typstyle
        ];

        emacsPackages = with pkgs.emacs.pkgs; [
          jupyter
          vterm
        ];

        langPackages = with pkgs; [
          d2
          marksman
          yaml-language-server
        ];

        nodePackages = with pkgs.nodePackages; [
          prettier
          vscode-langservers-extracted
        ];
      in
      mkMerge [
        basePackages
        emacsPackages
        langPackages
        nodePackages
      ];

    sessionPath = [ "${emacs}/bin" ];
    sessionVariables = {
      QT_QPA_PLATFORM_PLUGIN_PATH = "${pkgs.qt6.qtbase.outPath}/lib/qt-6/plugins";
    };
  };

  sops.templates.authinfo = {
    path = "${config.home.homeDirectory}/.authinfo";
    content = ''
      machine api.anthropic.com login apikey password ${config.sops.placeholder."llm/anthropic"}
      machine api.cerebras.ai login apikey password ${config.sops.placeholder."llm/cerebras"}
      machine api.mistral.ai login apikey password ${config.sops.placeholder."llm/mistral"}
      machine api.openai.com login apikey password ${config.sops.placeholder."llm/openai"}
      machine irc.libera.chat login proto1 password ${config.sops.placeholder.libera}
    '';
  };
}
