{ lib, fetchzip }:

let
  version = "8fb4e5b411ce47cbdd69e5bbaec51fc1e04b44a6";
in
(fetchzip {
  name = "monaco-nerd-font-${version}";
  url = "https://github.com/Karmenzind/monaco-nerd-fonts/archive/${version}.zip";
  sha256 = "sha256-TVcGTRhDQgsKTBhFyP2p8KLnN8NJTBTKkAeH9Cn+/1w=";

  meta = with lib; {
    description = "Terminal-friendly monaco font, with extra nerd glyphs, patched with ryanoasis's nerd patcher";
    homepage = "https://github.com/Karmenzind/monaco-nerd-fonts";
  };
}).overrideAttrs
  (_: {
    postFetch = ''
      unzip -j $downloadedFile
      for i in *.ttf; do
        local destname="$(echo "$i" | sed -E 's|-[[:digit:].]+\.ttf$|.ttf|')"
        install -Dm 644 "$i" "$out/share/fonts/truetype/$destname"
      done
    '';
  })
