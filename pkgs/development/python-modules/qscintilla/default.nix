<<<<<<< HEAD
{ lib
, buildPythonPackage
, fetchPypi
, python
, qscintillaCpp
, lndir
, pyqt4
}:

let base = import ./base.nix { inherit lib qscintillaCpp; };
in buildPythonPackage (base // rec {
  buildInputs = [ lndir pyqt4.qt qscintillaCpp ];
  propagatedBuildInputs = [ pyqt4 ];

  # TODO: with qscintilla 2.10 this will have to use configure.py
  preConfigure = ''
    mkdir -p $out
    lndir ${pyqt4} $out
    rm -rf "$out/nix-support"
    cd Python
    ${python.executable} ./configure-old.py \
        --destdir $out/lib/${python.libPrefix}/site-packages/PyQt4 \
        --apidir $out/api/${python.libPrefix} \
        -n ${qscintillaCpp}/include \
        -o ${qscintillaCpp}/lib \
        --sipdir $out/share/sip
  '';
})
=======
{ stdenv
, buildPythonPackage
, disabledIf
, isPy3k
, isPyPy
, pkgs
, python
, pyqt4
}:

disabledIf (isPy3k || isPyPy)
  (buildPythonPackage rec {
    # TODO: Qt5 support
    name = "qscintilla-${version}";
    version = pkgs.qscintilla.version;
    format = "other";

    src = pkgs.qscintilla.src;

    buildInputs = [ pkgs.xorg.lndir pyqt4.qt pyqt4 ];

    preConfigure = ''
      mkdir -p $out
      lndir ${pyqt4} $out
      rm -rf "$out/nix-support"
      cd Python
      ${python.executable} ./configure-old.py \
          --destdir $out/lib/${python.libPrefix}/site-packages/PyQt4 \
          --apidir $out/api/${python.libPrefix} \
          -n ${pkgs.qscintilla}/include \
          -o ${pkgs.qscintilla}/lib \
          --sipdir $out/share/sip
    '';

    meta = with stdenv.lib; {
      description = "A Python binding to QScintilla, Qt based text editing control";
      license = licenses.lgpl21Plus;
      maintainers = with maintainers; [ danbst ];
      platforms = platforms.unix;
    };
  })
>>>>>>> add-traverso
