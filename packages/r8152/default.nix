{
  lib,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
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

  makeFlags = kernelModuleMakeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)"
    "INSTALL_MOD_PATH=$(out)"
    "INSTALL_MOD_DIR=updates"
    "DEPMOD=true"
  ];

  buildFlags = [ "modules" ];
  installTargets = [ "modules_install" ];

  postInstall = ''
    install -D -m 0644 50-usb-realtek-net.rules \
      $out/lib/udev/rules.d/50-usb-realtek-net.rules
  '';

  meta = {
    description = "Realtek RTL8152/RTL8153 USB Ethernet driver";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
