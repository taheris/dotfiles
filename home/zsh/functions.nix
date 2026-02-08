{ config, ... }:

let
  home = config.home.homeDirectory;
in
{
  home.file = {
    "bin/doom-pin-update.sh" = {
      source = ./doom-pin-update.sh;
      executable = true;
    };
  };

  programs.zsh.initContent = ''
    chpwd() {
      echo "$PWD" > "$TMPDIR/last-dir";
    }

    github-clone() {
      local repo=$*
      local outdir="${home}/src/github.com/$repo"
      local regex="^([[:alnum:]_\.-]+)/([[:alnum:]_\.-]+)$"
      [[ $repo =~ $regex ]] || { echo "$repo not in valid format"; return 1; }
      command git clone "git@github.com:$repo.git" $outdir || return 1
      cd $outdir
    }

    rg-boundary() {
      command rg --sort-files --follow --max-columns 180 "\\b$*\\b"
    }

    rg-limit() {
      command rg --sort-files --follow --max-columns 180 -oe ".{0,50}$*.{0,50}"
    }

    calc() {
      bc -l <<< "$@"
    }

    tarball() {
      local file=$1
      tar cf - $file \
        | pv -s $(du -sb $file | awk '{print $1}') \
        | gzip > $file.tar.gz
    }

    fzf-json() {
      local file=$1
      echo "" | fzf --preview 'jq {q} < '"$file"' ' --query "."
    }
  '';
}
