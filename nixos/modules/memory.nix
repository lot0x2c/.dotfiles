{ lib, ... }:
{
  # zram first: with the disk swap, earlyoom thrashed the ssd before killing
  zramSwap.enable = true;
  # Disk swap previously caused long stalls. Hibernation is disabled in power.nix.
  swapDevices = lib.mkForce [ ];
  boot.kernel.sysctl = {
    # zram is cheap, swap idle pages before dropping file cache
    "vm.swappiness" = 180;
    # zram has no seek cost
    "vm.page-cluster" = 0;
  };

  services.earlyoom = {
    enable = true;
    enableNotifications = true;
    extraArgs = [
      # matched against comm: 15 chars, wrapper prefix kept (".swaylock-wrapp")
      "--avoid" "(sway|waybar|Xwayland)"
      # a firefox tab dies, not the browser
      "--prefer" "^(Web Content|Isolated Web Co)$"
    ];
  };
}
