{ stdenv, fetchurl, autoconf, automake, zip
, wxGTK, libX11, libXau, libXmu
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  version = "0.16.0.729";
  name = "opennx-${version}";

  src = fetchurl {
    url = "http://downloads.sourceforge.net/project/opennx/opennx/CI-source/opennx-${version}.tar.gz";
    sha256 = "0wjmgmnigpa3icgnwg5k4infqizsdjq8b4bc9571plymg0x63mhx";
  };

  buildInputs =
    [ autoconf automake zip
      wxGTK libX11 libXau libXmu
    ];

  meta = {
    homepage = http://www.opennx.net/;
    license = stdenv.lib.licenses.gpl2Plus;
    description = "OpenNX is an open source drop in replacement for NoMachine's NX client";
    maintainers = with stdenv.lib.maintainers; [coconnor];
    platforms = with stdenv.lib.platforms; all;
  };
}
