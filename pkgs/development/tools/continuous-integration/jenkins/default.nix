{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "jenkins";
  version = "1.574";

  src = fetchurl {
    url = "http://mirrors.jenkins-ci.org/war/${version}/jenkins.war";
    sha256 = "1ia0g3nzxxdwmlj5sxx115dlylvqijnv4h7kfb8lb6h0p0dqycma";
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
