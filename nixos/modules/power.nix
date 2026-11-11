# a hardware fault: it never wakes from suspend. so nothing sleeps or blanks,
# lid shut or not. drop all but the profiles, upower and the charge limit
# once resume works
{ ... }:
{
  services.power-profiles-daemon.enable = true;

  services.logind.settings.Login = {
    # the press that woke it reached logind after resume and powered it off
    HandlePowerKey = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    IdleAction = "ignore";
  };
  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    # Keep the known-working policy until hibernation passes hardware tests.
    AllowHibernation = false;
    AllowHybridSleep = false;
    AllowSuspendThenHibernate = false;
  };

  boot.kernelParams = [ "consoleblank=0" ];
  environment.etc."sway/config.d/temp.conf".text = ''
    output * power on
    bindswitch --reload --locked lid:on output * power on
    bindswitch --reload --locked lid:off output * power on
  '';

  services.upower = {
    enable = true;
    # A failed resume must not be the emergency battery recovery path.
    criticalPowerAction = "PowerOff";
    percentageLow = 20;
    percentageCritical = 8;
    percentageAction = 5;
  };
  # nothing starts it at the login prompt otherwise
  systemd.services.upower.wantedBy = [ "multi-user.target" ];
  # waybar's charge-limit module toggles it
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="BAT0", ATTR{charge_control_start_threshold}="75", ATTR{charge_control_end_threshold}="80"
  '';
}
