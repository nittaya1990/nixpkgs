{ stdenv, lib, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "biscuit-${version}";
  version = "0.1.2";
  rev = "v${version}";

  goPackagePath = "github.com/dcoker/biscuit";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dcoker";
    repo = "biscuit";
    sha256 = "0w9m3pkayldgjf744jlq1bwspgqk720zjnxsrvvasm0mvfs6c6lf";
  };
}
