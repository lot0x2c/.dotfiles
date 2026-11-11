{ pkgs, ... }:
{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable = true;
  services.fwupd.enable = true;

  # caps lock: tap for esc, hold for ctrl. keyd remaps at the kernel level, so it works in the tty, sway and every app
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main.capslock = "overload(control, esc)";
    };
  };

  # mesa has no video decode for intel. check: nix shell nixpkgs#libva-utils -c vainfo
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];

  # second ssd
  fileSystems."/mnt/media" = {
    device = "/dev/disk/by-uuid/d2313096-1442-45e7-b3a7-3361e6e05dcd";
    fsType = "ext4";
    options = [ "noatime" "nofail" "x-systemd.automount" ];
  };
}
