{ stdenv, fetchurl, ... } @ args:

import ./generic.nix (args // rec {
  version = "3.14";

  src = fetchurl {
    url = "https://www.kernel.org/pub/linux/kernel/v3.x/testing/linux-3.14-rc3.tar.xz";
    sha256 = "05p1lakrv7bzyk5q4j2dxvfpr27ivw4yx69fm5y8f2qbb505l3dp";
  };

  features.iwlwifi = true;
  features.efiBootStub = true;
  features.needsCifsUtils = true;
  features.canDisableNetfilterConntrackHelpers = true;
  features.netfilterRPFilter = true;
})
