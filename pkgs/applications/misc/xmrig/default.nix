{ stdenv, lib, fetchFromGitHub, cmake, libuv, libmicrohttpd, openssl, hwloc
, jansson
, donateLevel ? 0
}:

stdenv.mkDerivation rec {
  pname = "xmrig";
  version = "6.8.0";

  src = fetchFromGitHub {
    owner = "xmrig";
    repo = "xmrig";
    rev = "v${version}";
    sha256 = "1pkq54vg3jv25zwyd5kw9lqkc6zgfal307rq8n50nvfrcpfkkb81";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ libuv libmicrohttpd openssl hwloc jansson ];

  patches = [ ./msr.patch ];

  postPatch = ''
    substituteInPlace src/donate.h \
      --replace "kDefaultDonateLevel = 5;" "kDefaultDonateLevel = ${toString donateLevel};" \
      --replace "kMinimumDonateLevel = 1;" "kMinimumDonateLevel = ${toString donateLevel};"
  '';

  installPhase = ''
    install -vD xmrig $out/bin/xmrig
  '';

  meta = with lib; {
    description = "Monero (XMR) CPU miner";
    homepage = "https://github.com/xmrig/xmrig";
    license = licenses.gpl3Plus;
    platforms   = [ "x86_64-linux" "x86_64-darwin" ];
    maintainers = with maintainers; [ fpletz kim0 ];
  };
}
