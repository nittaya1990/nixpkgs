{ lib, stdenv, fetchgit, substituteAll, getConfig,
jdk, maven, unzip } :
with lib;
let
    mode = getConfig ["jenkins" "mode" ] "normal";
    src = if mode == "normal" then
            fetchgit { url = "git://github.com/ooyala/jenkins-ci.git"; }
          else
            ../../../../../../jenkins-ci;
    base_src = builtins.filterSource
                (path: type: type != "directory" || baseNameOf path != ".git")
                (builtins.toPath "${src}");
    # Relies on "mvn initialize" only caring about the poms.
    # Which seems to be true.
    only_poms = builtins.filterSource
                (path: type: type != "file" || baseNameOf path != "pom.xml")
                (builtins.toPath "${src}");
in stdenv.mkDerivation {
  name = "jenkins";

  src = src;
  m2_repo = stdenv.mkDerivation {
    name = "jenkins-m2-repo-initialized";
    builder = ./initialize_m2_repo.sh;
    src = src;
    jenkins_m2_settings = ./m2_settings.xml;
    buildInputs = [maven];
    inherit jdk;
  };

  builder = ./builder.sh;
  jenkins_m2_settings = ./m2_settings.xml;
  buildInputs = [maven unzip];
  inherit jdk;
}
