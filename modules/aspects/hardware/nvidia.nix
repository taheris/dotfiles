{ ... }:
{
  my.nvidia.nixos = {
    environment.sessionVariables = {
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
    };

    services.xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };

    systemd.services.nvidia-suspend.wantedBy = [ "systemd-suspend-then-hibernate.service" ];
  };
}
