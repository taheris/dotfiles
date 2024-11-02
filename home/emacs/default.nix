{
  config,
  lib,
  pkgs,
  host,
  ...
}:

let
  inherit (builtins) toPath;
  inherit (lib) mkIf;

  package = pkgs.emacs29-pgtk;

  doom = "${config.xdg.configHome}/doom";
  emacs = "${config.xdg.configHome}/emacs";
  path = "$PATH:${config.programs.emacs.package}/bin:${pkgs.git}/bin:${emacs}/bin";

  configChange = ''
    export PATH=${path}
    run emacs --batch --eval "${tangleConfig}"
    run doom sync -e
    run ln -sf ${./init.el} ${doom}/init.el
    run ln -sf ${./config.el} ${doom}/config.el
    run ln -sf ${./packages.el} ${doom}/packages.el
  '';

  tangleConfig = ''
    (progn
      (require 'org)
      (setq org-confirm-babel-evaluate t
            IS-LINUX ${if host ? isLinux then "t" else "nil"}
            IS-MAC ${if host ? isDarwin then "t" else "nil"}
            IS-WINDOWS nil)
      (org-babel-tangle-file \"${toPath ./config.org}\"))
  '';
in
{
  programs.emacs = {
    enable = true;
    inherit package;
  };

  services.emacs = mkIf (host ? isLinux) ({
    enable = true;
    inherit package;
    client.enable = true;
  });

  home = {
    activation.doomEmacs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH=${path}
      if [[ ! -d ${emacs} ]]; then
        git clone --depth 1 https://github.com/doomemacs/doomemacs ${emacs}
        doom install
      fi
    '';

    file."${doom}/config.org" = {
      source = ./config.org;
      onChange = mkIf (host ? isLinux) configChange;
    };

    packages =
      let
        basePackages = with pkgs; [
          aspell
          d2
          ltex-ls
          marksman
          sqlite
          yaml-language-server
        ];

        emacsPackages = with pkgs.emacsPackages; [ vterm ];
      in
      basePackages ++ emacsPackages;

    sessionPath = [ "${emacs}/bin" ];
  };
}
