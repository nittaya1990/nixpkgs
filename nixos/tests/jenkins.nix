{ pkgs, ... }:
{
  nodes = {
    master = { pkgs, config, ... }: {
        services.jenkins.enable = true;

        # try extending the extra groups. Verified below in testScript.
        users.extraUsers.jenkins.extraGroups = [ "users" ];
      };
  };

  testScript = ''
    startAll;

    $master->waitForUnit("jenkins");
    print $master->execute("sudo -u jenkins groups");
    $master->mustSucceed("sudo -u jenkins groups | grep jenkins | grep users");
  '';
}
