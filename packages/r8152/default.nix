{
  lib,
  stdenv,
  kernel,
}:

stdenv.mkDerivation {
  pname = "r8152";
  version = "2.22.1";

  src = ./.;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  hardeningDisable = [
    "format"
    "pic"
  ];

  buildPhase = ''
    runHook preBuild
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M=$PWD \
      modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D -m 0644 r8152.ko \
      $out/lib/modules/${kernel.modDirVersion}/updates/r8152.ko
    install -D -m 0644 50-usb-realtek-net.rules \
      $out/lib/udev/rules.d/50-usb-realtek-net.rules
    runHook postInstall
  '';

  meta = {
    description = "Realtek RTL8152/RTL8153 USB Ethernet driver";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
