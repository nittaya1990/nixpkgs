{ stdenv, fetchurl }:
let
  majorVersion = "2.43";
  release = "1";
  baseURL = "http://selenium-release.storage.googleapis.com";
in stdenv.mkDerivation rec {
  name = "selenium-server-standalone-${version}";
  version = "${majorVersion}.${release}";

  src = fetchurl {
    url = "${baseURL}/${majorVersion}/selenium-server-standalone-${version}.jar";
    sha256 = "1qn70jcpnf2fzazkc5h6w4n77fja7w3a3gngm14f9yg1gy7z19fk";
  };

  unpack = "";

  buildCommand = ''
    mkdir -p $out/share/java
    cp $src $out/share/java/selenium-server-standalone.jar
  '';

  meta = with stdenv.lib; {
    homepage = https://code.google.com/p/selenium;
    description = "Selenium Server for remote WebDriver.";
    maintainers = [ maintainers.coconnor ];
    platforms = platforms.all;
    hydraPlatforms = [];
    license = licenses.asl20;
  };
}
