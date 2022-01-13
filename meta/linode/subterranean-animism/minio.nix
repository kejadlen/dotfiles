{ config, pkgs, ... }:

let
  private = import ./private.nix;
  minioCredentialsFile = "/etc/nixos/minio-credentials";
in {
  environment.systemPackages = with pkgs; [
    minio-client
  ];

  # https://github.com/NixOS/nixpkgs/blob/nixos-21.11/nixos/modules/services/web-servers/minio.nix
  services.minio = {
    enable = true;
    rootCredentialsFile = minioCredentialsFile;
  };

  services.nginx = {
    virtualHosts."${private.minioHost}" = {
      addSSL = true;
      enableACME = true;

      extraConfig = ''
        # To allow special characters in headers
        ignore_invalid_headers off;
        # Allow any size file to be uploaded.
        # Set to a value such as 1000m; to restrict file size to a specific value
        client_max_body_size 0;
        # To disable buffering
        proxy_buffering off;
      '';

      locations."/" = {
        proxyPass = "http://localhost:9001";
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
  };
}
