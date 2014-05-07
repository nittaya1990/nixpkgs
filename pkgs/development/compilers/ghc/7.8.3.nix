{ stdenv, git, openssh, fetchgit, ghc, perl, gmp, ncurses }:

stdenv.mkDerivation rec {
  version = "7.8.3";
  name = "ghc-${version}";

  src = fetchgit {
    url = https://git.haskell.org/ghc.git;
    rev = "8404e800a35380281a218c78a6799ed6836b6fad";
    sha256 = "0an14h2rbwjs0cglznzl6a5s7hyr3w4brn6kmspw0xlsbgww1ns6";
    leaveDotGit = true;
    fetchSubmodules = false;
  };

  buildInputs = [ ghc perl gmp ncurses git openssh ];

  enableParallelBuilding = true;

  buildMK = ''
    libraries/integer-gmp_CONFIGURE_OPTS += --configure-option=--with-gmp-libraries="${gmp}/lib"
    libraries/integer-gmp_CONFIGURE_OPTS += --configure-option=--with-gmp-includes="${gmp}/include"
    DYNAMIC_BY_DEFAULT = NO
  '';

  preConfigure = ''
    echo "${buildMK}" > mk/build.mk
    perl ./sync-all get
    perl ./boot
    sed -i -e 's|-isysroot /Developer/SDKs/MacOSX10.5.sdk||' configure
  '' + stdenv.lib.optionalString (!stdenv.isDarwin) ''
    export NIX_LDFLAGS="$NIX_LDFLAGS -rpath $out/lib/ghc-${version}"
  '';

  configureFlags = "--with-gcc=${stdenv.gcc}/bin/gcc";

  # required, because otherwise all symbols from HSffi.o are stripped, and
  # that in turn causes GHCi to abort
  stripDebugFlags = [ "-S" "--keep-file-symbols" ];

  meta = {
    homepage = "http://haskell.org/ghc";
    description = "The Glasgow Haskell Compiler";
    maintainers = [
      stdenv.lib.maintainers.marcweber
      stdenv.lib.maintainers.andres
      stdenv.lib.maintainers.simons
    ];
    inherit (ghc.meta) license platforms;
  };

}
