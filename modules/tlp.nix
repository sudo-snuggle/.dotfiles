{ pkgs, ... }:

{
  # Disable conflicting power management daemons
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      # --- CPU & Performance ---
      CPU_DRIVER_OPMODE_ON_AC = "active";
      CPU_DRIVER_OPMODE_ON_BAT = "active";

      # intel_pstate active mode only accepts 'powersave' or 'performance'
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Primary tuning via Intel HWP / EPP
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Cap max CPU P-state on battery 
       CPU_MAX_PERF_ON_AC = 70;
      CPU_MAX_PERF_ON_BAT = 20;

      # Turbo Boost: on when plugged in, off on battery
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      # --- Platform & Bus Power Savings (includes Thunderbolt) ---
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersave";

      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # Deny only the Thunderbolt driver instead of wiping the default denylist
      RUNTIME_PM_DRIVER_DENYLIST = "thunderbolt";

      # --- Disk & Storage ---
      DISK_APM_LEVEL_ON_AC = "254 254";
      DISK_APM_LEVEL_ON_BAT = "1 1";

      AHCI_RUNTIME_PM_ON_AC = "on";
      AHCI_RUNTIME_PM_ON_BAT = "auto";

      # --- USB & Connectivity ---
      USB_AUTOSUSPEND = 1;
      # USB_EXCLUDE_AUDIO = 1;

      SATA_LINKPWR_ON_BAT = "min_power";
      SATA_LINKPWR_ON_AC = "med_power_with_dipm";

      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth";

      # --- Battery Charge Thresholds (T480 has two batteries) ---
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT1 = 80;
    };
  };

  # Thunderbolt daemon for device authorization and power negotiation
  services.hardware.bolt.enable = true;

  # Force PCIe ASPM at boot
  boot.kernelParams = [
    "pcie_aspm=force"
  ];
}