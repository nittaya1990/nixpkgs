{stdenv, fetchurl}:
let 
  base_URL = "http://openjdk-osx-build.googlecode.com/files";
  extract_dmg = {url, sha256}:
    let
      dmg = fetchurl { inherit url sha256; };
    in stdenv.mkDerivation {
      name = "extract_dmg";
      src = dmg;
      builder = ./extract_dmg.sh;
    };
in stdenv.mkDerivation {
  name = "openjdk7-u8-b04-20120823";

  src = extract_dmg {
    url = base_URL + "/OpenJDK-OSX-1.7-universal-u-jdk-u8-b04-20120823.dmg";
    sha256 = "1lmpfkv49ngwjqnkqcpkwxslbh09f5s23sviymv9mabav4rp5kga";
  };

  builder = ./openjdk7_builder.sh;
}
