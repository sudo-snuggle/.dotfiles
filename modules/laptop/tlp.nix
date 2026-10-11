
{ pkgs, ... }:

{
  # Disable conflicting power management daemons
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;

    settings = {
      # --- CPU ---
      
      CPU_MIN_PERF_ON_BAT = 0; 
      CPU_MAX_PERF_ON_BAT = 100; 
      CPU_BOOST_ON_BAT = 1; 
      CPU_HWP_DYN_BOOST_ON_BAT = 1;

      CPU_DRIVER_OPMODE_ON_AC = "active";
      CPU_DRIVER_OPMODE_ON_BAT = "active";

      # Let intel_pstate/HWP manage frequency normally.
      # Keep powersave on battery for lower energy preference.
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # HWP / EPP
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # No CPU_MAX_PERF_* limits
      # No CPU_BOOST_* limits
      # No CPU_HWP_DYN_BOOST_* limits

      # --- Platform & Bus Power Savings ---
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersave";

      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # Deny only the Thunderbolt driver
      RUNTIME_PM_DRIVER_DENYLIST = "thunderbolt";

      # --- Disk & Storage ---
      DISK_APM_LEVEL_ON_AC = "254 254";
      DISK_APM_LEVEL_ON_BAT = "1 1";

      AHCI_RUNTIME_PM_ON_AC = "on";
      AHCI_RUNTIME_PM_ON_BAT = "auto";

      # --- USB & Connectivity ---
      USB_AUTOSUSPEND = 1;

      SATA_LINKPWR_ON_BAT = "min_power";
      SATA_LINKPWR_ON_AC = "med_power_with_dipm";

      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth";

      # --- Battery Charge Thresholds ---
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;

      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT1 = 80;
    };
  };

  # Thunderbolt device authorization and power management
  services.hardware.bolt.enable = true;

  # Force PCIe ASPM at boot
  boot.kernelParams = [
    "pcie_aspm=force"
  ];
}

