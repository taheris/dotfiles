{
  lib,
  stdenv,
  kernel,
}:

stdenv.mkDerivation {
  pname = "apple-display-backlight";
  version = "0.1.0";

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
    install -D apple_bl_usb.ko $out/lib/modules/${kernel.modDirVersion}/extra/apple_bl_usb.ko
    runHook postInstall
  '';

  meta = {
    description = "Apple Studio Display / Pro Display XDR backlight driver";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
