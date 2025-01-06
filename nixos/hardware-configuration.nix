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
    initrd = {
      availableKernelModules = [
        "ahci"
        "nvme"
        "sd_mod"
        "sr_mod"
        "thunderbolt"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];
      kernelModules = [ ];
    };

    kernel.sysctl = {
      "kernel.sysrq" = 0;
      "net.core.default_qdisc" = "cake";
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_rfc1337" = 1;
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
    };

    kernelModules = [
      "kvm-amd"
      "tcp_bbr"
    ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "amdgpu.gpu_recovery=1"
      "nvidia-drm.fbdev=1"
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      # disable power management for Intel I225-V
      "pcie_port_pm=off"
      "pcie_aspm.policy=performance"
      "video=DP-1:6016x3384@60"
    ];
    blacklistedKernelModules = [ ];

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

      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    nvidia-container-toolkit.enable = true;
  };

  networking.interfaces = {
    eno1.useDHCP = true;
    wlp9s0.useDHCP = true;
  };
}
