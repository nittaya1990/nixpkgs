{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "jenkins-${version}";
  version = "1.588";

  src = fetchurl {
    url = "http://mirrors.jenkins-ci.org/war/${version}/jenkins.war";
    sha256 = "1aavs7by54b6nvakid1xgsxffcl5bp79g6yhl8pxhsch80494ry3";
  };
  meta = with stdenv.lib; {
    description = "An extendable open source continuous integration server";
    homepage = http://jenkins-ci.org;
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = [ maintainers.coconnor ];
  };

  buildCommand = ''
    mkdir $out
    ln -s $src $out/jenkins.war
  '';
}
