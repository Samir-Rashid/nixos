# Framework 16 extras: hibernate, AMD decode, TRIM, latest kernel, 80% charge.
{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Disko swap has resumeDevice = true → this mapper. Same LUKS passphrase
  # as cryptroot so initrd can reuse it (boot.initrd.luks.reusePassphrases).
  # 32G swap: hibernate needs used RAM to fit; more RAM than that won't
  # fully snapshot.
  boot.resumeDevice = "/dev/mapper/cryptswap";
  # protectKernelImage sets kexec_load_disabled, which blocks hibernation.
  security.protectKernelImage = false;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libva
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  services.fstrim.enable = true;

  systemd.services.battery-charge-threshold = {
    description = "Cap battery charge at 80%";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for f in /sys/class/power_supply/BAT*/charge_control_end_threshold; do
        if [ -w "$f" ]; then
          echo 80 > "$f"
        fi
      done
    '';
  };
}
