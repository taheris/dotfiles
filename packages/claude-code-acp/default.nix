{ pkgs, ... }:

let
  version = "0.5.5";

in
pkgs.buildNpmPackage {
  pname = "claude-code-acp";
  inherit version;

  meta = {
    description = "An agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://github.com/zed-industries/claude-code-acp";
    downloadPage = "https://www.npmjs.com/package/@zed-industries/claude-code-acp";
    license = pkgs.lib.licenses.asl20;
    mainProgram = "claude-code-acp";
  };

  src = pkgs.fetchFromGitHub {
    owner = "zed-industries";
    repo = "claude-code-acp";
    rev = "75b44e945ed091dfe24384a543e706d4e7a1ad35";
    hash = "sha256-WkDTzA6MepcuuAk8vTRav/ixzxlIBNaYEugyvt/nlIY=";
  };

  doCheck = false;
  npmDepsHash = "sha256-IaP7/W17ESA5C2xy0YUiL2xcLQJglC/K6YXw/ijbqLk=";

  nativeBuildInputs = [
    pkgs.patchelf
  ];

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  AUTHORIZED = "1";

  postInstall = ''
    wrapProgram $out/bin/claude-code-acp \
      --set DISABLE_AUTOUPDATER 1
  '';

  passthru.updateScript = ./update.sh;
}
