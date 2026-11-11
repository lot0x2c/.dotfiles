{ ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    connect-timeout = 5;
    experimental-features = [ "nix-command" "flakes" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
  # rebuilds yield the cpu to the desktop
  nix.daemonCPUSchedPolicy = "batch";

  # prebuilt binaries (pip wheels, npm downloads) need /lib64/ld-linux-x86-64.so.2
  programs.nix-ld.enable = true;
}
