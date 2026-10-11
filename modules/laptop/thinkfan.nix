{ ... }:

{
  services.thinkfan = {
    enable = true;
    levels = [
      [0 0  45]
      [1 45 48]
      [2 48 55]
      [3 55 58]
      [4 58 60]
      [5 60 63]
      [6 63 65]
      [7 65 32767]
    ];
    sensors = [
      {
        type = "tpacpi";
        query = "/proc/acpi/ibm/thermal";
        indices = [ 0 1 2 3 4 5 6 7 ];
      }
    ];
    fans = [
      {
        type = "tpacpi";
        query = "/proc/acpi/ibm/fan";
      }
    ];
  };

  boot.extraModprobeConfig = "options thinkpad_acpi fan_control=1";
}