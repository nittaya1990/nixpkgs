{ stdenv, fetchgit, substituteAll, jdk, maven } :

stdenv.mkDerivation {
  name = "jenkins";

  src = fetchgit {
    # url = "git://github.com/coreyoconnor/nixpkgs.git";
    # TODO(corey): Switch between URLs depending on mode.
    url = "/Users/corey/Development/jenkins-project/jenkins-ci";
    rev = "aa7ec8b52e8c468095dd1216c292ea6213854e06";
  };

  builder = ./builder.sh;
  jenkins_m2_settings = ./m2_settings.xml;
  buildInputs = [maven];
  inherit jdk;
}
