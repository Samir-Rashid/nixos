{
  lib,
  stdenv,
  autoPatchelfHook,
  libusb1,
  udev,
  binutils,
  glib,
  gdk-pixbuf,
  librsvg,
  bzip2,
  libjpeg_turbo,
  libidn2,
  libtasn1,
  libxcursor,
  zlib,
  src,
}:

stdenv.mkDerivation rec {
  pname = "linkserver";
  version = "26.9.130";

  # /home/shrimp/Documents/code/firmware/LinkServer_26.9.130.x86_64.deb.bin
  inherit src;

  nativeBuildInputs = [
    autoPatchelfHook
    binutils
  ];

  buildInputs = [
    libusb1
    udev
    glib
    gdk-pixbuf
    librsvg
    bzip2
    libjpeg_turbo
    libidn2
    libtasn1
    libxcursor
    zlib
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libjpeg.so.8"
  ];

  unpackPhase = ''
    sh "$src" --noexec --target extracted_installer
    cd extracted_installer
    ar -x "LinkServer_${version}.x86_64.deb"
    tar -xf data.tar.gz
  '';

  installPhase = ''
    mkdir -p "$out/bin"
    cp -r usr/local/* "$out/"
    ln -s "$out/LinkServer_${version}/LinkServer" "$out/bin/LinkServer"
    ln -s "$out/LinkServer_${version}/LinkServer" "$out/bin/linkserver"
  '';

  # dist/LinkServer is a non-PIE PyInstaller bootloader with an archive
  # appended after the last load segment. patchelf grows it so the Nix
  # interpreter fits, and the process then SIGSEGVs at 0x4000a0.
  # Anything left under $out is still patched, so park it outside $out.
  preFixup = ''
    bootloader=$NIX_BUILD_TOP/LinkServer.bootloader
    mv "$out/LinkServer_${version}/dist/LinkServer" "$bootloader"

    restoreLinkServerBootloader() {
      local dir="$out/LinkServer_${version}"
      local ld="${lib.getLib stdenv.cc.libc}/lib/ld-linux-x86-64.so.2"
      local libs="${lib.getLib zlib}/lib:${lib.getLib libusb1}/lib"
      mv "$bootloader" "$dir/dist/LinkServer"

      # The stock launcher execs dist/LinkServer. That file's interpreter
      # is /lib64/ld-linux-x86-64.so.2, the NixOS stub that refuses it.
      # The bootloader re-execs and keeps only LD_LIBRARY_PATH, which is
      # how the second load finds libz.
      cat > "$dir/LinkServer" << EOF
#!/bin/sh
export LD_LIBRARY_PATH="$libs\''${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
export PATH="${binutils}/bin:\$PATH"
exec "$ld" "$dir/dist/LinkServer" "\$@"
EOF
      chmod 755 "$dir/LinkServer"

      # LinkFlash discards its arguments and opens the flash GUI.
      cat > "$dir/LinkFlash" << EOF
#!/bin/sh
exec "$dir/LinkServer" gui flash
EOF
      chmod 755 "$dir/LinkFlash"
    }
    postFixupHooks+=(restoreLinkServerBootloader)
  '';

  meta = {
    description = "NXP LinkServer utility for launching and managing GDB servers";
    homepage = "https://nxp.com";
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
  };
}
