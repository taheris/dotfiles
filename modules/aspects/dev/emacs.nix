{ ... }:

# Depends on `my.secrets` being included alongside this aspect — the
# `sops.templates.authinfo` block reads `config.sops.placeholder.*`.
{
  my.emacs.homeManager =
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

      package = emacsPackage.emacsWithPackages emacsPackages;
      emacsPackage = with pkgs; emacsPackagesFor emacs30-pgtk;
      emacsPackages =
        epkgs: with epkgs; [
          jupyter
          pdf-tools
          vterm
        ];

      epdfinfo = pkgs.runCommand "epdfinfo" { } ''
        mkdir -p $out/bin
        cp ${emacsPackage.pdf-tools}/share/emacs/site-lisp/elpa/pdf-tools-${emacsPackage.pdf-tools.version}/epdfinfo \
          $out/bin/epdfinfo
      '';

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

      programs.readline.variables = {
        editing-mode = "emacs";
      };

      dconf.settings = mkIf isLinux {
        "org/gnome/desktop/interface" = {
          gtk-key-theme = "Emacs";
        };
      };

      gtk = mkIf isLinux {
        gtk2.extraConfig = ''
          gtk-key-theme-name = "Emacs"
        '';

        gtk3.extraConfig = {
          gtk-key-theme-name = "Emacs";
        };
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
            source = ./_emacs/config.org;
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
              epdfinfo
              hunspell
              hunspellDicts.en-gb-large
              hunspellDicts.en-us-large
              ltex-ls
              prettier
              sqlite
              tinymist
              tree-sitter-grammars.tree-sitter-typst
              (typst.withPackages (ps: [
                ps.fontawesome
                ps.moderner-cv
              ]))
              typstyle
              vscode-langservers-extracted
            ];

            langPackages = with pkgs; [
              d2
              marksman
              yaml-language-server
            ];
          in
          mkMerge [
            basePackages
            langPackages
          ];

        sessionPath = [ "${emacs}/bin" ];
        sessionVariables = {
          QT_QPA_PLATFORM_PLUGIN_PATH = "${pkgs.qt6.qtbase.outPath}/lib/qt-6/plugins";
        };
      };

      sops.templates.authinfo = {
        path = "${config.home.homeDirectory}/.authinfo";
        content = ''
          machine api.anthropic.com login apikey password ${config.sops.placeholder."llm/anthropic/api"}
          machine api.cerebras.ai login apikey password ${config.sops.placeholder."llm/cerebras"}
          machine api.mistral.ai login apikey password ${config.sops.placeholder."llm/mistral"}
          machine api.openai.com login apikey password ${config.sops.placeholder."llm/openai"}
          machine irc.libera.chat login proto1 password ${config.sops.placeholder.libera}
        '';
      };
    };
}
