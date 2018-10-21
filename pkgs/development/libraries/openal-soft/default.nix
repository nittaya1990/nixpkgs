{ stdenv, fetchurl, cmake
, alsaSupport ? !stdenv.isDarwin, alsaLib ? null
, pulseSupport ? !stdenv.isDarwin, libpulseaudio ? null
, CoreServices, AudioUnit, AudioToolbox
}:

with stdenv.lib;

assert alsaSupport -> alsaLib != null;
assert pulseSupport -> libpulseaudio != null;

stdenv.mkDerivation rec {
  version = "1.19.1";
  name = "openal-soft-${version}";

  src = fetchurl {
    url = "https://github.com/kcat/openal-soft/archive/openal-soft-${version}.tar.gz";
    sha256 = "1iwqiw3n7g3imvrfmhnndg8ys5sbngh62smwzax1sy5p5fmkcdcz";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = []
    ++ optional alsaSupport alsaLib
    ++ optional pulseSupport libpulseaudio
    ++ optionals stdenv.isDarwin [ CoreServices AudioUnit AudioToolbox ];

  NIX_LDFLAGS = []
    ++ optional alsaSupport "-lasound"
    ++ optional pulseSupport "-lpulse";

  meta = {
    description = "OpenAL alternative";
    homepage = http://kcat.strangesoft.net/openal.html;
    license = licenses.lgpl2;
    maintainers = with maintainers; [ftrvxmtrx];
    platforms = platforms.unix;
  };
}
