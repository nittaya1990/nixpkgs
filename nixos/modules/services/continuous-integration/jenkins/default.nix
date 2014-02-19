{ config, pkgs, ... }:
with pkgs.lib;
let
  cfg = config.services.jenkins;
in {
  options = {
    services.jenkins = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the jenkins continuous integration server.
        '';
      };
      
      home = mkOption {
        default = "/var/lib/jenkins";
        type = types.string;
        description = ''
          The path to use as JENKINS_HOME and as the home of the "jenkins" user.
        '';
      };

      port = mkOption {
        default = 8080;
        type = types.uniq types.int;
        description = ''
          Specifies port number on which the jenkins HTTP interface listens. The default is 8080
        '';
      };

      user = mkOption {
        default = "jenkins";
        description = ''
          User account under which jenkins runs. The default value of "jenkins" causes the user to
          be managed automatically. Otherwise another module is expected to manage the user.
        '';
      };

      group = mkOption {
        default = "jenkins";
        description = ''
          Default group of "jenkins" user.
        '';
      };

      extraGroups = mkOption {
        default = [];
        type = with types; listOf string;
        description = ''
          Extra groups of the "jenkins" user.
        '';
      };

      packages = mkOption {
        default = [ pkgs.stdenv pkgs.git pkgs.jdk pkgs.openssh pkgs.nix ];
        type = types.listOf types.package;
        description = "Packages to expose to the jenkins process";
      };

      environment = mkOption {
        default = { NIX_REMOTE = "daemon"; };
        type = with types; attrsOf string;
        description = ''
          Additional environment variables to be passed to the jenkins process.
          The environment will always include JENKINS_HOME.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    users.extraGroups = optional (cfg.user == "jenkins") { name = "jenkins"; };

    users.extraUsers = optionalAttrs (cfg.user == "jenkins") (singleton {
      name = cfg.user;
      description = "jenkins user";
      createHome = true;
      home = cfg.home;
      group = cfg.group;
      extraGroups = cfg.extraGroups;
      useDefaultShell = true;
      uid = config.ids.uids.jenkins;
    });

    systemd.services.jenkins = {
      description = "jenkins continuous integration server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        JENKINS_HOME = cfg.home;
      } // cfg.environment;

      path = cfg.packages;

      script = ''
        ${pkgs.jdk}/bin/java -jar ${pkgs.jenkins} --httpPort=${toString cfg.port}
      '';

      postStart = ''
        until ${pkgs.curl}/bin/curl -L localhost:${toString cfg.port} ; do
          sleep 10
        done
        while true ; do
          index=`${pkgs.curl}/bin/curl -L localhost:${toString cfg.port}`
          if [[ !("$index" =~ 'Please wait while Jenkins is restarting' ||
                  "$index" =~ 'Please wait while Jenkins is getting ready to work') ]]; then
            exit 0
          fi
          sleep 30
        done
      '';

      serviceConfig = {
        User = cfg.user;
      };
    };
  };
}
