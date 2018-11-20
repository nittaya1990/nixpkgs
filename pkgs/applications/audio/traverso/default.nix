{ stdenv, fetchgit, cmake
, alsaLib, fftw, flac, lame, libjack2, libmad, libpulseaudio
, libsamplerate, libsndfile, libvorbis, portaudio, qtbase, wavpack
}:
stdenv.mkDerivation rec {
  name = "traverso-${version}";
  version = "0.49.5";

  src = fetchgit {
    url = "https://git.savannah.gnu.org/git/traverso.git";
    rev = "2e215feaa9aebe104658c14d1820abdece7fb287";
    sha256 = "1bmfaxi3f4ppk9dp8zj5lllrkmzq3s04h066j9cqsm4v27vra6bg";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ alsaLib fftw flac.dev libjack2 lame
                  libmad libpulseaudio libsamplerate.dev libsndfile.dev libvorbis
                  portaudio qtbase wavpack ];

  cmakeFlags = [ "-DWANT_PORTAUDIO=1" "-DWANT_PULSEAUDIO=0" "-DWANT_MP3_ENCODE=1" ];

  meta = with stdenv.lib; {
    description = "Cross-platform multitrack audio recording and audio editing suite";
    homepage = http://traverso-daw.org/;
    license = with licenses; [ gpl2Plus lgpl21Plus ];
    platforms = platforms.all;
    maintainers = with maintainers; [ coconnor ];
  };
}
