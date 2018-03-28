{ stdenv, lib, fetchurl, fetchpatch, gdal, cmake, flex, bison, proj, geos, xlibsWrapper, sqlite, gsl
, qwt, fcgi, python3Packages, libspatialindex, libspatialite, postgresql, makeWrapper
, symlinkJoin
, qjson, txt2tags, openssl, libzip
, qtbase, qtwebkit, qtsensors, qca-qt5, qtkeychain, qscintilla
, withGrass ? true, grass
}:
with lib;
let
  pythonBuildInputs = [ python3Packages.qscintilla python3Packages.gdal ] ++
                        (with python3Packages; [ jinja2 numpy psycopg2 pygments pyqt5 sip OWSLib six ]);
  version = "3.0.1";
  src = fetchurl {
    url = "http://qgis.org/downloads/qgis-${version}.tar.bz2";
    sha256 = "1m24kjl784csbv0dgx1wbdwg8r92cpc1j718aaw85p7vgicm8acy";
  };
  meta = {
    description = "User friendly Open Source Geographic Information System";
    homepage = http://www.qgis.org;
    license = stdenv.lib.licenses.gpl2Plus;
    platforms = with stdenv.lib.platforms; linux;
    maintainers = with stdenv.lib.maintainers; [viric];
  };
in rec {
  qgisUnwrapped = stdenv.mkDerivation rec {
    inherit version;
    name = "qgis-unwrapped-${version}";

    buildInputs = [ flex openssl bison proj geos xlibsWrapper sqlite gsl qwt
      fcgi libspatialindex libspatialite postgresql qjson txt2tags libzip
      qtbase qtwebkit qtsensors qca-qt5 qtkeychain qscintilla ] ++
      (stdenv.lib.optional withGrass grass) ++ pythonBuildInputs;

    nativeBuildInputs = [ cmake ];

    # Build processes depend on the built libraries. Extend
    # LD_LIBRARY_PATH as required.
    preConfigure = ''
      export LD_LIBRARY_PATH=`pwd`/build/output/lib:${stdenv.lib.makeLibraryPath [ openssl ]}$LD_LIBRARY_PATH
    '';

    # Force this pyqt_sip_dir variable to point to the sip dir in PyQt5
    #
    # TODO: Correct PyQt5 to provide the expected directory and fix
    # build to use PYQT5_SIP_DIR consistently.
    postPatch = ''
      substituteInPlace cmake/FindPyQt5.py \
        --replace 'pyqtcfg.pyqt_sip_dir' '"${python3Packages.pyqt5}/share/sip/PyQt5"'
    '';

    inherit src;

    cmakeFlags = [ "-DPYQT5_SIP_DIR=${python3Packages.pyqt5}/share/sip/PyQt5"
                   "-DQSCI_SIP_DIR=${python3Packages.qscintilla}/share/sip/PyQt5" ] ++
              stdenv.lib.optional withGrass "-DGRASS_PREFIX7=${grass}/${grass.name}";
  };

  qgis = symlinkJoin {
    inherit version;
    name = "qgis-${version}";

    paths = [ qgisUnwrapped ];

    nativeBuildInputs = [ makeWrapper python3Packages.wrapPython ];

    pythonInputs = pythonBuildInputs ++
                   (with python3Packages; [ chardet dateutil pyyaml pytz requests urllib3 ] );

    # use the source archive directly to avoid rebuilding when changing qgis distro
    inherit src;

    postBuild = ''
      unpackPhase

      buildPythonPath "$pythonInputs"

      wrapProgram $out/bin/qgis \
        --prefix PATH : $program_PATH \
        --prefix PYTHONPATH : $program_PYTHONPATH \
        --prefix LD_LIBRARY_PATH : ${stdenv.lib.makeLibraryPath [ openssl ]}

      # desktop link
      mkdir -p $out/share/applications

      sed "/^Exec=/c\Exec=$out/bin/qgis" \
        < $sourceRoot/debian/qgis.desktop \
        > $out/share/applications/qgis.desktop

      # mime types
      mkdir -p $out/share/mime/packages
      cp $sourceRoot/debian/qgis.xml $out/share/mime/packages

      # vector icon
      mkdir -p $out/share/icons/hicolor/scalable/apps
      cp $sourceRoot/images/icons/qgis_icon.svg $out/share/icons/hicolor/scalable/apps/qgis.svg
    '';
  };
}
