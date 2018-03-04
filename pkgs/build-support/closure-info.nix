# This derivation builds two files containing information about the
# closure of 'rootPaths': $out/store-paths contains the paths in the
# closure, and $out/registration contains a file suitable for use with
# "nix-store --load-db" and "nix-store --register-validity
# --hash-given".

{ stdenv, coreutils, jq, perl, pathsFromGraph }:

{ rootPaths }:

# FIXME: this code is old to work with nix-1.11 also,
# whatever combination of evaluator and daemon.  See #36268.

  stdenv.mkDerivation {
    name = "closure-info";

    exportReferencesGraph =
      map (x: [("closure-" + baseNameOf x) x]) rootPaths;

    buildInputs = [ perl ];

    buildCommand =
      ''
        mkdir $out
        printRegistration=1 perl ${pathsFromGraph} closure-* > $out/registration
        perl ${pathsFromGraph} closure-* > $out/store-paths
      '';
  }

