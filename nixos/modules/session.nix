{ pkgs, ... }:
let
  session = {
    wantedBy = [ "sway-session.target" ];
    partOf = [ "sway-session.target" ];
    after = [ "sway-session.target" ];
    path = [ pkgs.coreutils pkgs.libnotify ];
  };
in
{
  # Sway's NixOS integration imports the display environment before this target.
  systemd.user.services = {
    idle-lock = session // {
      serviceConfig = {
        ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout 600 %h/.config/sway/lock.sh before-sleep %h/.config/sway/lock.sh lock %h/.config/sway/lock.sh";
        Restart = "on-failure";
        RestartSec = 2;
      };
      path = session.path ++ [ pkgs.swaylock pkgs.bash ];
    };
    clipboard = session // {
      serviceConfig = {
        ExecStart = "${pkgs.copyq}/bin/copyq";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
    autotiling = session // {
      serviceConfig = {
        ExecStart = "${pkgs.autotiling-rs}/bin/autotiling-rs";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
    battery-reminders = session // {
      serviceConfig = {
        ExecStart = "${pkgs.runtimeShell} %h/.config/dunst/battery.sh";
        Restart = "on-failure";
        RestartSec = 30;
      };
    };
    clock-reminder = {
      partOf = [ "sway-session.target" ];
      requisite = [ "sway-session.target" ];
      path = [ pkgs.coreutils pkgs.libnotify ];
      serviceConfig.Type = "oneshot";
      script = ''
        notify-send -c reminder -t 8000 -h string:x-dunst-stack-tag:tick "$(date +%H:%M)" "10 minutes gone"
      '';
    };
  };
  systemd.user.timers.clock-reminder = {
    wantedBy = [ "sway-session.target" ];
    partOf = [ "sway-session.target" ];
    timerConfig = {
      OnCalendar = "*:0/10";
      AccuracySec = "1s";
    };
  };
}
