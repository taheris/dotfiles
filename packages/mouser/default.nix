{
  lib,
  stdenv,
  python3Packages,
  python3,
  fetchFromGitHub,
  qt6,
  hidapi,
  makeWrapper,
}:

let
  version = "3.0";

  # cython-hidapi must use the hidraw backend (not libusb) so it can open
  # /dev/hidraw* devices that the kernel HID driver already claims.
  python-hidapi = python3Packages.hidapi.overrideAttrs (old: {
    env = (old.env or { }) // {
      HIDAPI_WITH_HIDRAW = "1";
      HIDAPI_WITH_LIBUSB = "0";
    };
  });

  python = python3.withPackages (_: [
    python-hidapi
    python3Packages.pyside6
    python3Packages.pillow
    python3Packages.evdev
  ]);

in
stdenv.mkDerivation {
  pname = "mouser";
  inherit version;

  src = fetchFromGitHub {
    owner = "TomBadash";
    repo = "Mouser";
    rev = "v${version}";
    hash = "sha256-IkzmrgutLVQjTYS1RFLADhfvZUcpl5HQ86DdA884rUQ=";
  };

  nativeBuildInputs = [
    makeWrapper
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    hidapi
    qt6.qtbase
    qt6.qtdeclarative
  ];

  patches = [
    ./linux-hidapi-usage-page.patch
    ./mx-vertical-gesture-cid.patch
    ./gesture-swipe-up-fix.patch
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/mouser
    cp -r core ui images main_qml.py $out/lib/mouser/

    makeWrapper ${python}/bin/python3 $out/bin/mouser \
      --add-flags "$out/lib/mouser/main_qml.py" \
      "''${qtWrapperArgs[@]}"

    runHook postInstall
  '';

  dontWrapQtApps = true;

  meta = {
    description = "Open-source Logitech mouse remapper alternative to Logitech Options+";
    homepage = "https://github.com/TomBadash/Mouser";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "mouser";
  };
}
