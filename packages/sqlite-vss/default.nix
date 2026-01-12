{ lib, pkgs, ... }:

let
  inherit (lib) optional;
  inherit (pkgs) fetchFromGitHub;
  inherit (pkgs.stdenv) mkDerivation;
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
  inherit (pkgs.stdenv.hostPlatform.extensions) staticLibrary sharedLibrary;

in
mkDerivation (finalAttrs: {
  pname = "sqlite-vss";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "asg017";
    repo = "sqlite-vss";
    rev = "v${finalAttrs.version}";
    hash = "sha256-cb9UlSUAZp8B5NpNDBvJ2+ung98gjVKLxrM2Ek9fOcs=";
  };

  patches = [ ./use-nixpkgs-libs.patch ];

  nativeBuildInputs = [ pkgs.cmake ];

  buildInputs = [
    pkgs.faiss
    pkgs.nlohmann_json
    pkgs.sqlite
  ]
  ++ optional isLinux pkgs.gomp
  ++ optional isDarwin pkgs.llvmPackages.openmp;

  SQLITE_VSS_CMAKE_VERSION = finalAttrs.version;

  installPhase = ''
    runHook preInstall

    install -Dm444 -t "$out/lib" \
      "libsqlite_vector0${staticLibrary}" \
      "libsqlite_vss0${staticLibrary}" \
      "vector0${sharedLibrary}" \
      "vss0${sharedLibrary}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "SQLite extension for efficient vector search based on Faiss";
    homepage = "https://github.com/asg017/sqlite-vss";
    changelog = "https://github.com/asg017/sqlite-vss/releases/tag/v${finalAttrs.version}";
    license = licenses.mit;
    platforms = platforms.unix;
  };
})
