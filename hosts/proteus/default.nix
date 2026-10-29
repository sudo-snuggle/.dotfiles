# /etc/nixos/configuration.nix — proteus (main device)

{ config, lib, pkgs, inputs, ... }:

{
    imports = [
    ./hardware-configuration.nix
    ../../modules/core/nix-settings.nix
    ../../modules/core/locale.nix
    ../../modules/desktop/wm.nix
    ../../modules/desktop/graphics.nix
    ../../modules/laptop/tlp.nix
    ../../modules/laptop/thinkfan.nix
    ../../modules/laptop/undervolt.nix
    ../../modules/boot/grub-opencore.nix
    ../../modules/desktop/steam.nix
    #../../modules/server/ai.nix
    ../../modules/desktop/appimage.nix
    #../../modules/desktop/virt.nix
    #../../modules/desktop/polkit.nix
    #../../modules/laptop/syncthing.nix
    ../../modules/laptop/fonts.nix

  ];

  # ---------- boot ----------
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ---------- networking ----------
  networking.hostName = "proteus";
  networking.networkmanager.enable = true;

services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;   # Key: provide PulseAudio compatibility layer, create /run/user/1000/pulse/native
};
security.rtkit.enable = true;  # PipeWire and PulseAudio require it for real-time scheduling


  # ---------- users (host-specific packages) ----------
  users.users.yasiru = {
    isNormalUser = true;
    description = "yasiru";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "input" ];
    packages = with pkgs; [
      #tree
      vscodium
      btop
      intel-gpu-tools
      stress-ng
      brave-origin
      pavucontrol
      #librewolf
      sunshine
    ];
  };

virtualisation.waydroid.enable = true;
virtualisation.waydroid.package = pkgs.waydroid-nftables;



services.sunshine = {
  enable = false;
  autoStart = false;
  capSysAdmin = true; # Needed for input/display capture permissions on Linux
};


  # ---------- shell ----------
  programs.bash = {
    enable = true;
    shellAliases = {
      fih = "fish";
    };
  };


  security.polkit.enable = true;

systemd.user.services.polkit-gnome-authentication-agent-1 = {
  description = "polkit-gnome-authentication-agent-1";
  wantedBy = [ "graphical-session.target" ];
  wants = [ "graphical-session.target" ];
  after = [ "graphical-session.target" ];
  serviceConfig = {
    Type = "simple";
    ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    Restart = "on-failure";
    RestartSec = 1;
    TimeoutStopSec = 10;
  };
};


  # ---------- VM writeback ----------
  boot.kernel.sysctl = {
    "vm.dirty_writeback_centisecs" = 1500;
    "vm.dirty_expire_centisecs" = 3000;
  };

  # ---------- packages ----------
  environment.systemPackages = with pkgs; [
    linuxPackages.cpupower
    linuxPackages.turbostat
    git
  #  tailscale
    powertop
   # qbittorrent
   # bottles
    #lutris
    pcmanfm-qt
    gh
    qutebrowser

      wlr-randr
      nwg-displays
  kanshi
  wlr-randr
  ];

  # Enable the Virtual KMS display driver
boot.kernelModules = [ "vkms" ];

boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "systemd.show_status=auto"
    "rd.udev.log_level=3"
    "i915.fastboot=1"
  ];

  # 3. Fast stage-1 initrd 
  boot.initrd = {
    systemd.enable = true;
    includeDefaultModules = false;
    availableKernelModules = [ 
      "ahci"         # SATA AHCI controller
      "libahci"      # AHCI library
      "libata"       # ATA bus support
      "sd_mod"       # SCSI/SATA disk driver (/dev/sdX)
      "xhci_pci"     # USB 3.0 controller
      "i915"         # Intel UHD 620 GPU (early KMS)
      "ext4"         # Root filesystem
      "atkbd"        # Built-in ThinkPad keyboard
      "hid_generic"  # Universal HID support
      "usbhid"       # External USB keyboards
    ];
  };

  # 4. Asynchronous network bring-up (don't block boot on Wi-Fi)
  systemd.services.NetworkManager-wait-online.enable = false;


  # ---------- gamemode (proteus only in original) ----------
  programs.gamemode.enable = true;

networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 7070 47984 47989 47990 48010 ];
    allowedUDPPortRanges = [
      { from = 47998; to = 48000; }
      { from = 48002; to = 48010; }
    ];
  };
  # ---------- tailscale ----------
  #services.tailscale.enable = true;

  system.stateVersion = "26.05";
}