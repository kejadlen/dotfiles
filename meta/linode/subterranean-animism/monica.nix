{ config, pkgs, ... }:

let
  private = import ./private.nix;
  minioCredentialsFile = "/etc/nixos/minio-credentials";
  bucket = "monica";
  policy = pkgs.writeText "monica-bucket-policy.json" ''
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "Monica",
          "Effect": "Allow",
          "Action": [ "s3:*" ],
          "Resource": [ "arn:aws:s3:::monica", "arn:aws:s3:::monica/*" ]
        }
      ]
    }
  '';
in {
  services.nginx.virtualHosts."${private.minioHost}" = {
    locations."/monica" = {
      proxyPass = "http://localhost:9000";
      extraConfig = ''
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;

        proxy_connect_timeout 300;
        # Default is HTTP/1, keepalive is only enabled in HTTP/1.1
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        chunked_transfer_encoding off;
      '';
    };
  };

  services.mysql = {
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

  # https://gist.github.com/expipiplus1/1bf5eea2ac58458134a6c0f9c15afd78
  systemd.services.monica-minio-config = {
    enable = true;
    path = [ pkgs.minio pkgs.minio-client ];
    requiredBy = [ "multi-user.target" ];
    after = [ "minio.service" ];
    serviceConfig = {
      Type = "simple";
      User = "minio";
      Group = "minio";
      RuntimeDirectory = "minio-config";
      EnvironmentFile = minioCredentialsFile;
    };
    script = ''
      set -e
      CONFIG_DIR=$RUNTIME_DIRECTORY
      mc --config-dir "$CONFIG_DIR" config host add minio http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"
      mc --config-dir "$CONFIG_DIR" admin user add minio "$MONICA_ACCESS_KEY" "$MONICA_SECRET_KEY"
      mc --config-dir "$CONFIG_DIR" admin policy add minio POLICY "${policy}"
      mc --config-dir "$CONFIG_DIR" admin policy set minio POLICY user="$MONICA_ACCESS_KEY"
      mc --config-dir "$CONFIG_DIR" mb --ignore-existing minio/monica
    '';
  };

  systemd.services.monica-mysql-config = {
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
