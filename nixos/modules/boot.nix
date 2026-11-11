{ ... }:
let
  # after a reinstall: lsblk -o NAME,SIZE,FSTYPE,UUID | grep crypto_LUKS
  # the 16G one (nvme1n1p3) is the hibernate swap, in memory.nix
  root = "2124e935-f357-4f3b-9fa1-05653629e9a2";
in
{
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
    editor = false;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 5;
  boot.tmp.cleanOnBoot = true;

  # trim through luks
  boot.initrd.luks.devices."luks-${root}".allowDiscards = true;
}
