{ stdenv, fetchurl, dpkg, curl, libarchive, openssl, ruby, buildRubyGem, libiconv
, libxml2, libxslt, makeWrapper, libvirt }:

buildRubyGem {
  inherit ruby;
  buildInputs = [ libvirt ];
  gemName = "vagrant-libvirt";
  version = "0.0.33";
  sha256 = "08vkywjhw3xxwchpys43lqnyl1fvahdsqp2763y38xfjjsbk0wi3";
}
