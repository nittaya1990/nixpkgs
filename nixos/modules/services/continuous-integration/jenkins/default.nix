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
          The path to use as JENKINS_HOME
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
        description = "User account under which jenkins runs";
      };
    };
  };

  config = mkIf cfg.enable {
    users.extraUsers = optionalAttrs (cfg.user == "jenkins") (singleton {
      name = "jenkins";
      uid = config.ids.uids.jenkins;
      description = "jenkins user";
    });

    systemd.services.jenkins = {
      description = "jenkins continuous integration server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        JENKINS_HOME = cfg.home;
      };

      preStart = ''
        mkdir -p ${cfg.home}
        chown -R ${cfg.user} ${cfg.home}
        sync
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
        ExecStart = "${pkgs.jdk}/bin/java -jar ${pkgs.jenkins} --httpPort=${toString cfg.port}";
        PermissionsStartOnly = true;
      };
    };
  };
}
