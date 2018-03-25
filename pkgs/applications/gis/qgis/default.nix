{ stdenv, lib, fetchurl, fetchpatch, gdal, cmake, flex, bison, proj, geos, xlibsWrapper, sqlite, gsl
, qwt, fcgi, python3Packages, libspatialindex, libspatialite, postgresql, makeWrapper
, qjson, txt2tags, openssl, libzip
, qtbase, qtwebkit, qtsensors, qca-qt5, qtkeychain, qscintilla
, withGrass ? true, grass
}:
with lib;
let pythonBuildInputs = [ python3Packages.qscintilla ] ++ (with python3Packages; [ jinja2 numpy psycopg2 pygments requests sip ]);
in stdenv.mkDerivation rec {
  name = "qgis-3.0.1";

  buildInputs = [ gdal flex openssl bison proj geos xlibsWrapper sqlite gsl qwt
    fcgi libspatialindex libspatialite postgresql qjson txt2tags libzip
    qtbase qtwebkit qtsensors qca-qt5 qtkeychain qscintilla ] ++
    (stdenv.lib.optional withGrass grass) ++ pythonBuildInputs;

  nativeBuildInputs = [ cmake makeWrapper ];

  # `make -f src/providers/wms/CMakeFiles/wmsprovider_a.dir/build.make src/providers/wms/CMakeFiles/wmsprovider_a.dir/qgswmssourceselect.cpp.o`:
  # fatal error: ui_qgsdelimitedtextsourceselectbase.h: No such file or directory
  # enableParallelBuilding = false;

  # To handle the lack of 'local' RPATH; required, as they call one of
  # their built binaries requiring their libs, in the build process.
  preConfigure = ''
    export LD_LIBRARY_PATH=`pwd`/build/output/lib:${stdenv.lib.makeLibraryPath [ openssl ]}$LD_LIBRARY_PATH
  '';

  postPatch = ''
    substituteInPlace cmake/FindPyQt5.py \
      --replace 'pyqtcfg.pyqt_sip_dir' '"${python3Packages.pyqt5}/share/sip/PyQt5"'
  '';

  src = fetchurl {
    url = "http://qgis.org/downloads/${name}.tar.bz2";
    sha256 = "1m24kjl784csbv0dgx1wbdwg8r92cpc1j718aaw85p7vgicm8acy";
  };

  cmakeFlags = [ "-DPYQT5_SIP_DIR=${python3Packages.pyqt5}/share/sip/PyQt5"
                 "-DQSCI_SIP_DIR=${python3Packages.qscintilla}/share/sip/PyQt5" ] ++
             stdenv.lib.optional withGrass "-DGRASS_PREFIX7=${grass}/${grass.name}";

  postInstall = ''
    wrapProgram $out/bin/qgis \
      --prefix PYTHONPATH : "$(toPythonPath '${concatStringsSep " " pythonBuildInputs}')" \
      --prefix LD_LIBRARY_PATH : ${stdenv.lib.makeLibraryPath [ openssl ]}
  '';

  meta = {
    description = "User friendly Open Source Geographic Information System";
    homepage = http://www.qgis.org;
    license = stdenv.lib.licenses.gpl2Plus;
    platforms = with stdenv.lib.platforms; linux;
    maintainers = with stdenv.lib.maintainers; [viric];
  };
}
