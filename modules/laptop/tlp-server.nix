{ pkgs, ... }:

{
  # Disable conflicting power management daemons
  services.power-profiles-daemon.enable = false;

  # Enable thermald for Intel thermal regulation on Haswell
  services.thermald.enable = true;

  services.tlp = {
    enable = true;

    settings = {
      # --- CPU & Governor (Haswell / 4th Gen) ---
      # Uses acpi-cpufreq or intel_pstate (no HWP required)
      CPU_DRIVER_OPMODE_ON_AC = "active";
      CPU_DRIVER_OPMODE_ON_BAT = "active";
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # --- Battery Charge Thresholds ---
      # Essential for 24/7 plugged-in servers to prevent battery degradation
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;

      # --- Disk & Storage ---
      # Keeps drives responsive and prevents head-parking wear
      DISK_APM_LEVEL_ON_AC = "254 254";
      DISK_APM_LEVEL_ON_BAT = "254 254";

      SATA_LINKPWR_ON_AC = "med_power_with_dipm";
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";

      # --- Power Savings ---
      # "auto" enables PCIe power management on AC so C-states drop cleanly
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";

      USB_AUTOSUSPEND = 1;
    };
  };
}