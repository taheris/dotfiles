# Credit to https://github.com/RobinKD/dotfiles/blob/main/pkgs/ib-tws/default.nix
{
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs) fetchurl makeDesktopItem;

  version = "10.40.1b";

  libPath = lib.makeLibraryPath (with pkgs; [
    atk
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    ffmpeg
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    (javaPackages.openjfx17.override { withWebKit = true; })
    libdrm
    libgbm
    libGL
    libxkbcommon
    libz
    pango
    nss_latest
    nspr
    mesa
    systemd
    wayland
    xorg.libXfixes
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libXi
    xorg.libXxf86vm
    xorg.libxcb
    xorg.libX11
  ]);

in
pkgs.stdenv.mkDerivation {
  pname = "ib-tws-native";
  inherit version;

  meta = with lib; {
    description = "Trader Work Station of Interactive Brokers";
    homepage = "https://www.interactivebrokers.com";
    license = licenses.unfree;
    platforms = platforms.linux;
  };

  src = fetchurl {
    url = "https://download2.interactivebrokers.com/installers/tws/latest-standalone/tws-latest-standalone-linux-x64.sh";
    sha256 = "sha256-rw7yGa5OLFuPyW8xQ5ICWl42UM95CwVaFzqKKpfIR08";
    executable = true;
  };

  preferLocalBuild = true;
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = with pkgs; [
    bash
    makeWrapper
  ];

  installPhase = ''
    set +o pipefail
    mkdir -p $out
    mkdir -p $out/bin
    mkdir -p $out/jre
    mkdir install4j

    sfx_archive_byte_count=`sed -nE 's/^tail -c ([0-9]+).*/\1/p' $src`
    tws_byte_count=`wc -c $src | cut -d" " -f1`

    # Extract the archive.
    tail --bytes $sfx_archive_byte_count "$src" > sfx_archive.tar.gz

    # Unpack the installer and JRE.
    tar -xf sfx_archive.tar.gz -C install4j
    tar -xf install4j/jre.tar.gz -C $out/jre
    # Extract data file
    data_byte_count=`sed -nE 's/^file\\.size\\.0=([0-9]+)/\\1/p' install4j/stats.properties`
    installer_offset=$(expr $tws_byte_count - $sfx_archive_byte_count - $data_byte_count)
    tail --bytes +$(expr $installer_offset + 1) "$src" 2> /dev/null | head --bytes $data_byte_count > install4j/0.dat
    # Patch JRE binaries.
    for file in $out/jre/bin/*
    do
      patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${lib.makeLibraryPath [ pkgs.zlib ]}:$out/jre/lib" \
      $file 2> /dev/null || true
    done

    # Unpack jars.
    unpack () {
    jar="`echo "$1" | awk '{ print substr($0,1,length($0)-5) }'`"
    $out/jre/bin/unpack200 -r "$1" "$jar"
    chmod a+r "$jar"
    }
    for jarpack in $out/jre/lib/*.jar.pack
    do
      unpack $jarpack
    done
    for jarpack in $out/jre/lib/ext/*.jar.pack
    do
      unpack $jarpack
    done

    # Run the bundled JRE, if this fails the build should also fail.
    $out/jre/bin/java -version

    installer_version=`sed -nE 's/.*Installer([0-9]+).*/\1/p' $src | head -n 1`
    # Run the installer, storing artifacts in $out.
    cd install4j && \
    LD_LIBRARY_PATH="${libPath}:$LD_LIBRARY_PATH" \
    INSTALL4J_JAVA_HOME="$out/jre" \
    $out/jre/bin/java \
    -DjtsConfigDir="/home/jts" \
    -classpath "i4jruntime.jar:launcher0.jar:$out/jre/lib/ext/*:$out/jre/jre/lib/ext/*" \
    install4j.Installer$installer_version "-q" "-dir" "$out"

    makeWrapper $out/tws $out/bin/tws \
    --argv0 "ib-tws" \
    --run "mkdir -p \$HOME/.tws/" \
    --prefix LD_LIBRARY_PATH : "${libPath}" \
    --set INSTALL4J_JAVA_HOME "$out/jre" \
    --add-flags "-J-DjtsConfigDir=\$HOME/.tws" \
    --add-flags "-J-Dawt.useSystemAAFontSettings=lcd" \
    --add-flags "-J-Dswing.aatext=true"

    # Copy icon to share/icons
    mkdir -p $out/share/icons/hicolor/128x128/apps
    ln -s $out/.install4j/tws.png $out/share/icons/hicolor/128x128/apps/tws.png

    # Install desktop item
    install -m 644 -D -t $out/share/applications $desktopItem/share/applications/*

    runHook postInstall
  '';

  postInstall = ''
    # Make the tws launcher script read $HOME/.tws/tws.vmoptions
    # instead of the unmutable version in $out.
    substituteInPlace $out/tws \
      --replace-fail 'read_vmoptions "$prg_dir/$progname.vmoptions' 'read_vmoptions "$HOME/.tws/$progname.vmoptions'

    # Fix javafx.web & com.sun.webkit exports
    substituteInPlace $out/tws \
      --replace-fail '"--add-exports=javafx.web/com.sun.javafx.webkit=ALL-UNNAMED"' '"--add-exports=javafx.web/com.sun.javafx.webkit=ALL-UNNAMED" "--add-exports=javafx.web/com.sun.webkit=ALL-UNNAMED"'
  '';

  desktopItem = makeDesktopItem {
    name = "ib-tws";
    desktopName = "IBKR Trade Workstation";
    terminal = false;
    categories = [ "Application" ];
    exec = "tws";
    startupWMClass = "install4j-jclient-LoginFrame";
    icon = "tws";
  };
}
