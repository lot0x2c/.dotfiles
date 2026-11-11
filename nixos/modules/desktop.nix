{ pkgs, ... }:
{
  # fish starts it on tty1
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      (rofi.override { plugins = [ rofi-calc rofi-emoji ]; })
      dunst
      copyq
      libnotify
      grim
      slurp
      wl-clipboard
      brightnessctl
      playerctl
      pavucontrol
      autotiling-rs
      chicago95
      # the cursor, and icons chicago95 lacks
      adwaita-icon-theme
      # gtk apps open terminal programs like nvim through it
      xdg-terminal-exec
    ];
  };
  xdg.mime.defaultApplications = {
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "text/html" = "firefox.desktop";
    "application/xhtml+xml" = "firefox.desktop";
    "application/pdf" = "firefox.desktop";
    "text/plain" = "nvim.desktop";
    "inode/directory" = "thunar.desktop";
  };
  # gtk apps read dconf, rofi reads settings.ini
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface" = {
        gtk-theme = "Chicago95";
        icon-theme = "Chicago95";
      };
    }
  ];
  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=Chicago95
    gtk-icon-theme-name=Chicago95
  '';
  security.rtkit.enable = true;
  services.pipewire.wireplumber.extraScripts."device/jack-profile.lua" =
    builtins.readFile ./jack-profile.lua;
  services.pipewire.wireplumber.extraConfig."50-audio-fixes" = {
    "wireplumber.components" = [
      {
        name = "device/jack-profile.lua";
        type = "script/lua";
        provides = "custom.jack-profile";
      }
    ];
    "wireplumber.profiles".main."custom.jack-profile" = "required";
    # output only: with the headset roles on, a2dp ended up busy and the bose silent
    "monitor.bluez.properties"."bluez5.roles" = [ "a2dp_source" "bap_source" "hfp_ag" "hsp_ag" ];
    # never hdmi. it shares both profiles with the speaker and headphones, so
    # jack-profile can't drop it, only the outputs themselves can go
    "monitor.alsa.rules" = [
      {
        matches = [ { "node.name" = "~alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.*HDMI.*"; } ];
        actions.update-props."node.disabled" = true;
      }
    ];
  };
  # installs the package and opens tcp/udp 1714-1764 in the firewall
  programs.kdeconnect.enable = true;
  services.speechd.enable = false;
  programs.waybar.enable = true;
  systemd.user.services.waybar = {
    # its scripts need nmcli, jq, swaymsg, wpctl, pkill
    path = [ "/run/current-system/sw" ];
    # the stock reload is a bare kill, which systemd can't find on nixos
    serviceConfig.ExecReload = [
      ""
      "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID"
    ];
  };
  # drops off the bus on plug in, hence the restart
  systemd.user.services.poweralertd = {
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig.ExecStart = "${pkgs.poweralertd}/bin/poweralertd -s -S";
    serviceConfig.Restart = "always";
    serviceConfig.RestartSec = 5;
  };
  systemd.user.services.polkit-gnome = {
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig.ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
  };
  fonts.packages = [ pkgs.monaspace ];
  environment.sessionVariables = {
    # electron on wayland
    NIXOS_OZONE_WL = "1";
    # java guis (burp) are blank grey on sway without it
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };
}
