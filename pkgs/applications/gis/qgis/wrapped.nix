{ stdenv, lib, fetchurl, openssl, python3Packages, makeWrapper, symlinkJoin
, qgis-unwrapped
}:
with lib;
symlinkJoin rec {
  inherit (qgis-unwrapped) version;
  name = "qgis-${version}";

  paths = [ qgis-unwrapped ];

  nativeBuildInputs = [ makeWrapper python3Packages.wrapPython ];

  pythonInputs = qgis-unwrapped.pythonBuildInputs ++
                 (with python3Packages; [ chardet dateutil pyyaml pytz requests urllib3 ] );

  # use the source archive directly to avoid rebuilding when changing qgis distro
  inherit (qgis-unwrapped) src;

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
}
