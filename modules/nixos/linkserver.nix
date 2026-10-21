# NXP LinkServer and the USB probes it talks to (LPC-Link2 / MCU-Link).
{ pkgs, inputs, ... }:

{
  environment.systemPackages = [
    (pkgs.callPackage ../../pkgs/linkserver.nix {
      src = inputs.linkserver-deb;
    })
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="1fc9", ATTR{idProduct}=="0143", MODE="0666", GROUP="users"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1fc9", ATTR{idProduct}=="0095", MODE="0666", GROUP="users"
  '';
}
