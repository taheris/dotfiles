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

      luks.devices = {
        "luks-9473fe30-86ac-49db-8ddd-0e6eedc0b936".device =
          "/dev/disk/by-uuid/9473fe30-86ac-49db-8ddd-0e6eedc0b936";
        "luks-b204925e-8745-42ee-bf7e-001e1430dc14".device =
          "/dev/disk/by-uuid/b204925e-8745-42ee-bf7e-001e1430dc14";
      };
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
      "nvidia.NVreg_TemporaryFilePath=/var/tmp"
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
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/11e69d97-251d-40c6-9b44-6a49d5c1323e";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/5952-C034";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/e9ad89ea-b73f-4d36-8dfd-7a3ec4787b9a"; } ];

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        libvdpau-va-gl
        nvidia-vaapi-driver
      ];
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
