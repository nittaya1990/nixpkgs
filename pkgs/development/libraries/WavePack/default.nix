{ stdenv, autoreconfHook, fetchgit }:
stdenv.mkDerivation rec {
  name = "WavePack-${version}";
  version = "5.1.0";

  src = fetchgit {
    url = "https://github.com/dbry/WavPack.git";
    rev = "90fb5f1af8ce449448b53244b0e64a066e15d959";
    sha256 = "1bsdmczql2kpd7z026j4agp71vnw222b9aj5fybl9y9wdimh17zf";
  };

  nativeBuildInputs = [ autoreconfHook ];
}
