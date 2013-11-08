{ fetchgit, stdenv, pkgconfig, libtool, autoconf, automake,
  curl, ncurses, amdappsdk, amdadlsdk, udev, xorg }:

stdenv.mkDerivation rec {
  version = "2.11.4";
  name = "cgminer-${version}";

  src = fetchgit {
    url = "https://github.com/ckolivas/cgminer.git";
    rev = "0bfac827434a30f130423123e7c6fbedf8f2062c";
    sha256  = "0nvcw363ycaa1mwgprrkxdygsq3d6q2j38lbrzpxqry4zgqvhwlf";
  };

  buildInputs = [ autoconf automake pkgconfig libtool curl ncurses amdappsdk amdadlsdk xorg.libX11
                  xorg.libXext xorg.libXinerama udev ];
  configureScript = "./autogen.sh";
  configureFlags = "--enable-scrypt --enable-opencl --enable-bflsc";
  NIX_LDFLAGS = "-lgcc_s -lX11 -lXext -lXinerama";

  preConfigure = ''
    ln -s ${amdadlsdk}/include/* ADL_SDK/
  '';

  postInstall = ''
    chmod 444 $out/bin/*.cl
  '';

  meta = with stdenv.lib; {
    description = "CPU/GPU miner in c for bitcoin";
    longDescription= ''
      This is a multi-threaded multi-pool GPU, FPGA and ASIC miner with ATI GPU
      monitoring, (over)clocking and fanspeed support for bitcoin and derivative
      coins. Do not use on multiple block chains at the same time!
    '';
    homepage = "https://github.com/ckolivas/cgminer";
    license = licenses.gpl3;
    maintainers = [ maintainers.offline ];
    platforms = [ "i686-linux" "x86_64-linux" ];
  };
}
