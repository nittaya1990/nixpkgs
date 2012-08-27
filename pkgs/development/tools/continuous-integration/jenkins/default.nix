{ lib, stdenv, fetchgit, substituteAll, jdk, maven } :
with lib;
let
    # TODO(corey): Switch between URLs depending on mode.
    # src = fetchgit { url = "git://github.com/ooyala/jenkins-ci.git"; };
    src = ../../../../../../jenkins-ci;
    base_src = builtins.filterSource
                (path: type: type != "directory" || baseNameOf path != ".git")
                src;
    # Relies on "mvn initialize" only caring about the poms.
    # Which seems to be true.
    only_poms = builtins.filterSource
                (path: type: type != "file" || baseNameOf path != "pom.xml")
                src;
in stdenv.mkDerivation {
  name = "jenkins";

  src = base_src;
  m2_repo = stdenv.mkDerivation {
    name = "jenkins-m2-repo-initialized";
    builder = ./initialize_m2_repo.sh;
    src = only_poms;
    jenkins_m2_settings = ./m2_settings.xml;
    buildInputs = [maven];
    inherit jdk;
  };

  builder = ./builder.sh;
  jenkins_m2_settings = ./m2_settings.xml;
  buildInputs = [maven];
  inherit jdk;
}
