{
  config,
  lib,
  pkgs,
  ...
}:

let
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
            IS-LINUX t
            IS-MAC nil
            IS-WINDOWS nil)
      (org-babel-tangle-file \"${builtins.toPath ./config.org}\"))
  '';
in
{
  programs.emacs = {
    enable = true;
    inherit package;
  };

  services.emacs = {
    enable = true;
    inherit package;
    client.enable = true;
  };

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
      onChange = configChange;
    };

    packages = with pkgs; [
      ltex-ls
      marksman
      emacsPackages.vterm
      yaml-language-server
    ];

    sessionPath = [ "${emacs}/bin" ];
  };
}
