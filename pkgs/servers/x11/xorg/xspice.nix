{ stdenv, sasl, libjpeg, spice, xf86videoqxl, xorgserver }:

with stdenv.lib;

overrideDerivation xf86videoqxl (oldAttrs: {
  name = "xf86-video-spiceqxl-" + (builtins.parseDrvName oldAttrs.name).version;
  configureFlags = "--enable-xspice";
  nativeBuildInputs =  oldAttrs.nativeBuildInputs ++ [
    spice libjpeg.dev sasl.dev
  ];
  meta = {
    name = "xf86-video-spiceqxl";
    description = "A standalone server that is both an X server and a Spice server.";
    homepage = http://www.spice-space.org/page/Features/XSpice;
    platforms = platforms.linux;
  };
})
