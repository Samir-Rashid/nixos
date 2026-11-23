# Upstream binary. pkgs.bambu-studio in nixpkgs is unfree, so cache.nixos.org
# does not have it, and the source build (wxWidgets plus the slicer) OOMs.
{
  lib,
  appimageTools,
  fetchurl,
}:

appimageTools.wrapType2 rec {
  pname = "bambu-studio";
  version = "02.08.02.61";

  src = fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/BambuStudio_ubuntu24.04-v${version}-20260820225108.AppImage";
    hash = "sha256-1QGxA/rFQkUT7A6Na8FF+zBxneLH2U1zINcjdAyBp/0=";
  };

  extraPkgs = pkgs: [
    pkgs.glib-networking
    pkgs.webkitgtk_4_1
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
    pkgs.gst_all_1.gst-plugins-bad
  ];

  meta = {
    description = "PC software for Bambu Lab 3D printers";
    homepage = "https://github.com/bambulab/BambuStudio";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "bambu-studio";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
