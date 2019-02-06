{ stdenv, lib, fetchurl, openssl, python3Packages, makeWrapper, symlinkJoin
, qgis3-unwrapped
}:
with lib;
symlinkJoin rec {
  inherit (qgis3-unwrapped) version;
  name = "qgis-${version}";

  paths = [ qgis3-unwrapped ];

  nativeBuildInputs = [ makeWrapper python3Packages.wrapPython ];

  # extend to add to the python environment of QGIS without rebuilding QGIS application.
  pythonInputs = qgis3-unwrapped.pythonBuildInputs;

  # use the source archive directly to avoid rebuilding when changing qgis distro
  inherit (qgis3-unwrapped) src;

  postBuild = ''
    unpackPhase

    buildPythonPath "$pythonInputs"

    wrapProgram $out/bin/qgis \
      --prefix PATH : $program_PATH \
      --set PYTHONPATH $program_PYTHONPATH

    # desktop link
    substitute $out/share/applications/org.qgis.qgis.desktop \
               $out/share/applications/org.qgis.qgis.desktop.patched \
               --replace 'Exec=qgis' "Exec=$out/bin/qgis"

    rm $out/share/applications/org.qgis.qgis.desktop
    mv $out/share/applications/org.qgis.qgis.desktop.patched \
       $out/share/applications/org.qgis.qgis.desktop

    # mime types
    mkdir -p $out/share/mime/packages
    cp $sourceRoot/debian/qgis.xml $out/share/mime/packages/
  '';
}
