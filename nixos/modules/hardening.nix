# nixos and this kernel already cover dmesg, kernel pointers, ptrace,
# unprivileged bpf and zeroing on alloc. this is the rest
{ lib, pkgs, ... }:
{
  # proton vpn keeps its login in the keyring, pam unlocks it at tty login
  services.gnome.gnome-keyring.enable = true;
  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

  # strict, so a network blocking 853 can't push it back to plain dns. for a
  # network whose own names you need:
  #   nmcli connection modify <name> connection.dns-over-tls opportunistic
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = [
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
        "2620:fe::fe#dns.quad9.net"
        "1.1.1.1#cloudflare-dns.com"
        "2606:4700:4700::1111#cloudflare-dns.com"
      ];
      Domains = [ "~." ];
      DNSOverTLS = true;
      # name poisoning on shared networks (responder)
      LLMNR = false;
      MulticastDNS = false;
    };
  };
  # captive portals: sudo captive-dns on, log in, sudo captive-dns off
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "captive-dns" ''
      set -eu
      drop=/run/systemd/resolved.conf.d/captive.conf
      case "''${1:-}" in
        on)
          mkdir -p /run/systemd/resolved.conf.d
          printf '[Resolve]\nDNS=\nDomains=\nDNSOverTLS=no\n' > "$drop"
          ;;
        off) rm -f "$drop" ;;
        *) echo "usage: sudo captive-dns on|off" >&2; exit 2 ;;
      esac
      systemctl restart systemd-resolved
    '')
  ];

  # socks on 127.0.0.1:9050, off at boot: sudo systemctl start tor
  services.tor = {
    enable = true;
    client.enable = true;
    torsocks.enable = true;
  };
  systemd.services.tor.wantedBy = lib.mkForce [ ];

  # random mac per network, stable on each
  networking.networkmanager.wifi.macAddress = "stable";

  security.protectKernelImage = true;
  boot.kernelParams = [ "slab_nomerge" "page_alloc.shuffle=1" ];

  boot.kernel.sysctl = {
    "kernel.sysrq" = 244; # reisub only
    "kernel.kexec_load_disabled" = 1;
    "fs.suid_dumpable" = 0;
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    "dev.tty.ldisc_autoload" = 0;
    # * covers interfaces plugged in later
    "net.ipv4.conf.*.accept_redirects" = 0;
    "net.ipv6.conf.*.accept_redirects" = 0;
  };

  # loaded on demand otherwise; sudo modprobe still works
  boot.blacklistedKernelModules = [
    "sctp" "rds" "tipc" "n_hdlc" "ax25" "netrom" "x25" "rose"
    "appletalk" "psnap" "atm" "can" "ieee802154"
    "cramfs" "freevxfs" "jffs2" "hfs" "hfsplus"
  ];

  nix.settings.allowed-users = [ "@wheel" ];

  programs.firefox.policies = {
    DisableTelemetry = true;
    DisableFirefoxStudies = true;
    Preferences = {
      # unload idle tabs under memory pressure instead of earlyoom killing them
      "browser.tabs.unloadOnLowMemory" = {
        Value = true;
        Status = "default";
      };
    };
  };
}
