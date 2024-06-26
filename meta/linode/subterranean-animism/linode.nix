{ config, lib, pkgs, modulesPath, ... }:

{
  # Use /dev/sdX identifiers for disks instead of UUIDs
  fileSystems."/".device = lib.mkForce "/dev/sda";
  swapDevices = lib.mkForce [ { device = "/dev/sdb"; } ];

  # Enable LISH
  boot.kernelParams = [ "console=ttyS0,19200n8" ];
  boot.loader.grub.extraConfig = ''
    serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1;
    terminal_input serial;
    terminal_output serial
  '';
  boot.loader.grub.forceInstall = true;
  boot.loader.grub.device = "nodev";
  boot.loader.timeout = 10;

  networking.usePredictableInterfaceNames = false;
}
