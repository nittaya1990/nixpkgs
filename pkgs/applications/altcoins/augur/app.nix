{ stdenv, pkgs, fetchurl, lib, makeWrapper
, dpkg
, gtk3, gnome3, alsaLib, atk, cairo, pango, gdk_pixbuf, glib, fontconfig
, dbus, libX11, xorg, libXi, libXcursor, libXdamage, libXrandr, libXcomposite
, libXext, libXfixes, libXrender, libXtst, libXScrnSaver, nss, nspr
, cups, expat
}:
let
  rpath = lib.makeLibraryPath [
    alsaLib
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    gdk_pixbuf
    glib
    gnome3.gconf
    gtk3
    pango
    libX11
    libXScrnSaver
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
    libXtst
    nspr
    nss
    stdenv.cc.cc
    xorg.libxcb
  ];
in stdenv.mkDerivation rec {
  name = "augur-app-${version}";
  version = "1.0.5";

  src = fetchurl {
    url = "https://github.com/AugurProject/augur-app/releases/download/v${version}/linux-Augur-${version}.deb";
    sha256 = "0akmwyax6pfffrf5bmmsb8nnh3xyvg7b9sc3pgv2azrn2gs6wyh4";
    name = "${name}.deb";
  };

  buildInputs = [ dpkg ] ;

  phases = ["unpackPhase" "installPhase"];

  unpackCmd = ''
    mkdir pkg
    dpkg-deb -x $curSrc pkg/
    sourceRoot=pkg
  '';

  installPhase = ''
    mkdir $out
    mkdir $out/libexec/
    mv opt/Augur $out/libexec/
    mv usr/share $out/

    # Patch launcher
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
             --set-rpath ${rpath}:$out/libexec/Augur $out/libexec/Augur/augur

    # Symlink to bin
    mkdir -p $out/bin
    ln -s $out/libexec/Augur/augur $out/bin/augur

    # Fix the desktop link
    substituteInPlace $out/share/applications/augur.desktop \
      --replace /opt/Augur/augur $out/bin/augur
  '';

  meta = with stdenv.lib; {
    description = "Augur App is a lightweight Electron app that bundles the Augur UI and Augur Node together.";
    homepage = https://github.com/AugurProject/augur-app;
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ maintainers.coconnor ];
  };
}
