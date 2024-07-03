{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "nvme"
      "sd_mod"
      "sr_mod"
      "thunderbolt"
      "usb_storage"
      "usbhid"
      "xhci_pci"
    ];
    initrd.kernelModules = [ ];

    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-amd" ];
    kernelParams = [
      "amdgpu.gpu_recovery=1"
      #"amdgpu.reset_method=4"
      "nvidia-drm.fbdev=1"
      "nvidia-drm.modeset=1"
      "video=DP-1:6016x3384@60"
    ];
    blacklistedKernelModules = [ ];
    #extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];

    loader = {
      efi.canTouchEfiVariables = true;

      systemd-boot = {
        enable = true;
        consoleMode = "max";
      };
    };

    supportedFilesystems = [ "bcachefs" ];
  };

  fileSystems = {
    "/" = {
      device = "UUID=94973779-aec1-4b5c-9665-28da553fdd30";
      fsType = "bcachefs";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/CCFE-8B5B";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/268c9e6a-810c-4c26-9d3e-4fc2ef6661ec"; } ];

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = false;

      powerManagement = {
        enable = false;
        finegrained = false;
      };

      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
        nvidiaBusId = "PCI:1:0:0";
        amdgpuBusId = "PCI:108:0:0";
      };

      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };

    nvidia-container-toolkit.enable = true;
  };

  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  networking.interfaces.wlp9s0.useDHCP = lib.mkDefault true;

  # Disable power management for Intel I225-V
  #services.udev.extraRules = ''
  #  SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15f3", ATTR{power/control}="on", GOTO="pci_pm_end"
  #  SUBSYSTEM=="pci", ATTR{power/control}="auto"
  #  LABEL="pci_pm_end"
  #  ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
  #'';

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
