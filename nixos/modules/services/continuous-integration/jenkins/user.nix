{ config, pkgs, ... }:
with pkgs.lib;
let
  cfg = config.users.jenkins;
in {
  options = {
    users.jenkins = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the jenkins user.
        '';
      };

      extraGroups = mkOption {
        default = [];
        type = with types; listOf string;
        description = ''
          Extra groups of the "jenkins" user.
        '';
      };

      group = mkOption {
        default = "jenkins";
        description = ''
          Default group of "jenkins" user.
        '';
      };

      home = mkOption {
        default = "/var/lib/jenkins";
        type = types.string;
        description = ''
          Home of the "jenkins" user and JENKINS_HOME.
        '';
      };

      name = mkOption {
        default = "jenkins";
        description = ''
          Name of account which jenkins runs. The default value of "jenkins" causes the user to be
          managed automatically. Otherwise another module is expected to manage the user.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    users.extraGroups = optional (cfg.name == "jenkins") { name = "jenkins"; };

    users.extraUsers = optionalAttrs (cfg.name == "jenkins") (singleton {
      name = cfg.name;
      description = "jenkins user";
      createHome = true;
      home = cfg.home;
      group = cfg.group;
      extraGroups = cfg.extraGroups;
      useDefaultShell = true;
      uid = config.ids.uids.jenkins;
    });
  };
}
