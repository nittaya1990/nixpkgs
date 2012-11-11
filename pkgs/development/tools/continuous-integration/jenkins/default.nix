{ lib, stdenv, fetchgit, substituteAll, getConfig,
jdk, maven3, unzip, fontconfig, fontsConf } :
with lib;
let
    mode = getConfig ["jenkins" "mode" ] "normal";
    # TODO(corey): This is a bit ugly.
    # Either we are doing dev on jenkins so we source the code directory.
    # Or we are Ooyala internal and want the QA Tools approved code.
    # Or we are none of those and we just want the standard jenkins distribution.
    # The target rev is 1.484 since that has proven more stable than >= 1.485.
    src = if mode == "normal" then
            fetchgit { 
              url = "git://github.com/ooyala/jenkins-ci.git"; 
              rev = "jenkins-1.484";
            }
          else if mode == "ooyala-internal" then
            fetchgit {
              url = "ssh://git@git.corp.ooyala.com/qa/tools/jenkins-ci.git";
              rev = "0c5a9a472ea99cba003a015497d4461640144e31";
            }
          else builtins.filterSource
                (path: type: type != "directory" || baseNameOf path != ".git")
                ../../../../../../jenkins-ci;
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
    buildInputs = [maven3];
    inherit jdk;
  };

  builder = ./builder.sh;
  jenkins_m2_settings = ./m2_settings.xml;
  buildInputs = [maven3 unzip fontconfig];
  inherit jdk fontsConf;
}
