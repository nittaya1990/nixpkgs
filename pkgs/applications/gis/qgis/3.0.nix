{ stdenv, lib, fetchurl, cmake, ninja, flex, bison, proj, geos, xlibsWrapper, sqlite, gsl
, qwt, fcgi, python3Packages, libspatialindex, libspatialite, postgresql
, txt2tags, openssl, libzip
, qtbase, qtwebkit, qtsensors, qtserialport, qca-qt5, qtkeychain, qscintilla, qtxmlpatterns
, withGrass ? true, grass
}:
with lib;
let
  pythonBuildInputs = with python3Packages;
    [ python3Packages.qscintilla-qt5 gdal jinja2 numpy psycopg2
      chardet dateutil pyyaml pytz requests urllib3 pygments pyqt5 sip OWSLib six ];
in stdenv.mkDerivation rec {
  version = "3.4.4";
  name = "qgis-unwrapped-${version}";

  src = fetchurl {
    url = "http://qgis.org/downloads/qgis-${version}.tar.bz2";
    sha256 = "1nmwcxfjbhz0x028mizwrl2w6pxvvisdifmn58kpnfgl2kvjnzgl";
  };

  inherit pythonBuildInputs;

  buildInputs = [ flex openssl bison proj geos xlibsWrapper sqlite gsl qwt
    fcgi libspatialindex libspatialite postgresql txt2tags libzip
    qtbase qtwebkit qtsensors qtserialport qca-qt5 qtkeychain qscintilla qtxmlpatterns] ++
    (stdenv.lib.optional withGrass grass) ++ pythonBuildInputs;

  nativeBuildInputs = [ cmake ninja ];

  # Force this pyqt_sip_dir variable to point to the sip dir in PyQt5
  #
  # TODO: Correct PyQt5 to provide the expected directory and fix
  # build to use PYQT5_SIP_DIR consistently.
  postPatch = ''
    substituteInPlace cmake/FindPyQt5.py \
      --replace 'pyqtcfg.pyqt_sip_dir' '"${python3Packages.pyqt5}/share/sip/PyQt5"'
  '';

  cmakeFlags = [ "-DPYQT5_SIP_DIR=${python3Packages.pyqt5}/share/sip/PyQt5"
                 "-DQSCI_SIP_DIR=${python3Packages.qscintilla}/share/sip/PyQt5"
                 "-DCMAKE_SKIP_BUILD_RPATH=OFF" ] ++
            stdenv.lib.optional withGrass "-DGRASS_PREFIX7=${grass}/${grass.name}";

  meta = {
    description = "User friendly Open Source Geographic Information System";
    homepage = http://www.qgis.org;
    license = stdenv.lib.licenses.gpl2Plus;
    platforms = with stdenv.lib.platforms; linux;
    maintainers = with stdenv.lib.maintainers; [viric];
  };
}
