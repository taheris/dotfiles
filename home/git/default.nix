{ pkgs, ... }:

{
  home.packages = with pkgs; [
    git
    git-crypt
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Shaun Taheri";
    userEmail = "gpg@taheris.net";

    signing = {
      key = "1C2BE6B85F923891";
      signByDefault = true;
    };

    includes = [
      {
        condition = "hasconfig:remote.*.url:git@github.com:blockjoy/**";
        contents = {
          user = {
            email = "shaun@blockjoy.com";
            signingKey = "ED2521879B846B13";
          };
        };
      }
    ];

    extraConfig = {
      init.defaultBranch = "main";
      merge.conflictstyle = "diff3";
      merge.tool = "merged";
      mergetool.merged.cmd = "vim $MERGED";
      pull.rebase = "true";
    };

    delta = {
      enable = true;

      options = {
        features = "decorations";
        syntax-theme = "Dracula";
        plus-style = "bold syntax auto";
        minus-style = "bold syntax auto";

        decorations = {
          commit-style = "raw";
          commit-decoration-style = "bold yellow box ul";

          file-style = "bold yellow ul";
          file-decoration-style = "none";

          hunk-header-decoration-style = "blue box";
          hunk-header-file-style = "red";
          hunk-header-style = "file line-number syntax";
          hunk-header-line-number-style = "cyan";
        };
      };
    };
  };
}
