{ pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 3306 ];

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ "monica" ];
    ensureUsers = [
      {
        name = "monica";
        ensurePermissions = {
          "monica.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  systemd.services.mysql-config = {
    enable = true;
    path = [ pkgs.mysql ];
    requiredBy = [ "multi-user.target" ];
    after = [ "mysql.service" ];
    serviceConfig = {
      Type = "simple";
      User = "mysql";
      Group = "mysql";
      RuntimeDirectory = "mysql-config";
    };
    script = ''
      set -e
      mysql < /etc/nixos/mysql-config
    '';
  };
}
