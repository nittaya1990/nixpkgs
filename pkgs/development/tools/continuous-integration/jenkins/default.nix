{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "jenkins";
  version = "1.577";

  src = fetchurl {
    url = "http://mirrors.jenkins-ci.org/war/${version}/jenkins.war";
    sha256 = "0q7r1y331cl2xgrc2grjq4jqgf5w1s9b0sf1br3xyzfznmc74v5f";
  };
  meta = {
    description = "An extendable open source continuous integration server.";
    homepage = http://jenkins-ci.org;
    license = stdenv.lib.licenses.mit;
    platforms = stdenv.lib.platforms.all;
    maintainers = [ stdenv.lib.maintainers.coconnor ];
  };

  buildCommand = ''
    mkdir $out
    ln -s $src $out/jenkins.war
  '';
}
