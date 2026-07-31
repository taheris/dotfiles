{
  bluez,
  cmake,
  fetchFromGitHub,
  lib,
  libpulseaudio,
  openssl,
  pkg-config,
  qt6,
  stdenv,
  systemd,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "librepods";
  version = "1.0.0-rc1";

  src = fetchFromGitHub {
    owner = "librepods-org";
    repo = "librepods";
    rev = "b5a3eaee8fbe5a0c83c360bb0fdcd6705a59cc25";
    hash = "sha256-Xd206WMtfwluK8boJ7Lg4K9wGiAQc/YndHVqWhfjXBQ=";
  };

  sourceRoot = "source/linux";

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    libpulseaudio
    openssl
    qt6.qtbase
    qt6.qtconnectivity
    qt6.qtquick3d
    qt6.qttools
  ];

  qtWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        bluez
        systemd
      ]
    }"
  ];

  meta = {
    description = "AirPods liberated from Apple's ecosystem";
    homepage = "https://github.com/librepods-org/librepods";
    license = lib.licenses.gpl3Only;
    mainProgram = "librepods";
    platforms = lib.platforms.linux;
  };
})
