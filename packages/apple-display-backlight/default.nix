{
  lib,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
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

  makeFlags = kernelModuleMakeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)"
    "INSTALL_MOD_PATH=$(out)"
    "INSTALL_MOD_DIR=extra"
    "DEPMOD=true"
  ];

  buildFlags = [ "modules" ];
  installTargets = [ "modules_install" ];

  meta = {
    description = "Apple Studio Display / Pro Display XDR backlight driver";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
