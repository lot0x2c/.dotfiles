# hardware-configuration.nix is machine-generated and stays in /etc/nixos.
# rebuild commands are in ../README.md
{ pkgs, ... }:
{
  imports = [
    /etc/nixos/hardware-configuration.nix
    ./modules/boot.nix
    ./modules/hardware.nix
    ./modules/power.nix
    ./modules/memory.nix
    ./modules/nix.nix
    ./modules/desktop.nix
    ./modules/hardening.nix
    ./modules/dev.nix
    ./modules/packages.nix
  ];

  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_IN";

  users.users.toad = {
    isNormalUser = true;
    shell = pkgs.fish;
    # brightnessctl goes through logind, no video group needed
    extraGroups = [ "wheel" "networkmanager" ];
  };
  security.sudo.execWheelOnly = true;

  # install-time version, never bump it
  system.stateVersion = "26.05";
}
