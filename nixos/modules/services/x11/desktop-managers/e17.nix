{ config, lib, pkgs, ... }:

with lib;

let

  xcfg = config.services.xserver;
  cfg = xcfg.desktopManager.e17;

in

{
  options = {

    services.xserver.desktopManager.e17.enable = mkOption {
      default = false;
      example = true;
      description = "Enable support for the E17 desktop environment.";
    };

  };


  config = mkIf (xcfg.enable && cfg.enable) {
    services.xserver.desktopManager.session = singleton {
      name = "e17";
      bgSupport = true;
      start =
        ''
          ${pkgs.e17.enlightenment}/bin/enlightenment_start
        '';
    };

    environment.systemPackages =
      [ pkgs.e17.enlightenment
      ];

    services.dbus.packages = [ pkgs.e17.ethumb ];
  };

}
