{ stdenv, sasl, libjpeg, makeWrapper, python27, spice, xf86videoqxl, xorgserver }:

with stdenv.lib;

overrideDerivation xf86videoqxl (oldAttrs: {
  name = "xf86-video-spiceqxl-" + (builtins.parseDrvName oldAttrs.name).version;
  configureFlags = "--enable-xspice";
  nativeBuildInputs =  oldAttrs.nativeBuildInputs ++ [
    spice libjpeg.dev sasl.dev
  ];

  buildInputs = oldAttrs.buildInputs ++ [ makeWrapper ];

  fixupPhase = ''
    substituteInPlace $out/bin/Xspice \
                      --replace /usr/bin/python ${python27.interpreter}
    wrapProgram $out/bin/Xspice \
                --prefix PATH : ${makeBinPath [ xorgserver ]}
  '';
})
