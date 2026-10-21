# Framework 16 extras: hibernate, AMD decode, TRIM, latest kernel, 80% charge.
{ pkgs, ... }:

{
  # nixos-hardware adds framework-laptop-kmod. This nixpkgs requires each
  # out-of-tree module to ship a .ko.cer, and that package only installs
  # the .ko, so the modules build dies on the missing certificate.
  boot.kernelPackages = pkgs.linuxPackages_latest.extend (
    kfinal: kprev: {
      framework-laptop-kmod = kprev.framework-laptop-kmod.overrideAttrs (_old: {
        # The aggregate build concatenates each out-of-tree .ko.cer.
        # Leave the .ko unsigned. This kernel does not enroll out-of-tree
        # certificates, and a signature it cannot check is rejected.
        postInstall = ''
          touch "$out/lib/modules/${kfinal.kernel.modDirVersion}/extra/framework_laptop.ko.cer"
        '';
      });
    }
  );

  # Disko swap has resumeDevice = true → this mapper. Same LUKS passphrase
  # as cryptroot so initrd can reuse it (boot.initrd.luks.reusePassphrases).
  # 32G swap: hibernate needs used RAM to fit; more RAM than that won't
  # fully snapshot.
  boot.resumeDevice = "/dev/mapper/cryptswap";
  # protectKernelImage sets kexec_load_disabled, which blocks hibernation.
  security.protectKernelImage = false;

  # Mesa (including VA-API) comes with hardware.graphics.enable.
  # The VDPAU translation drivers fight AMD's own decoder.
  hardware.graphics.enable = true;

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
