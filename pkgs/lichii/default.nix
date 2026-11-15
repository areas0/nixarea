# Lichii (experimental Nintendo Switch / Switch 2 emulator), wrapped from the
# upstream AppImage. The bundle is self-contained (RPATH=$ORIGIN/../lib, Qt6 +
# ffmpeg shipped inside) but expects an FHS system for GL/Vulkan/X11/audio, so
# it runs inside appimageTools' FHS env rather than being patchelf'd.
#
# Fetched from the callme-sy/Lichii-Superbuild GitHub releases (unofficial PGO
# builds with curated fixes on top of zortos293/Lichii). When bumping
# `version`, update `hash` too; GitHub shows each asset's sha256 digest
# (`gh release view v<N> -R callme-sy/Lichii-Superbuild --json assets`).
{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "lichii";
  version = "56";

  src = fetchurl {
    url = "https://github.com/callme-sy/Lichii-Superbuild/releases/download/v${version}/Lichii-v${version}-linux-x64-pgo.AppImage";
    hash = "sha256-uR0FFlQIhq+dzOxJU0IcL8pQW1KuUdx6DfQs7R7hcCg=";
  };

  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs =
    pkgs: with pkgs; [
      libGL
      libglvnd
      vulkan-loader
      libxkbcommon
      wayland
      libx11
      libxcb
      libxcursor
      libxext
      libxfixes
      libxi
      libxrandr
      libxscrnsaver
      libxtst
      libxcb-cursor
      libxcb-image
      libxcb-keysyms
      libxcb-render-util
      libxcb-wm
      alsa-lib
      libpulseaudio
      pipewire
      libusb1
      fontconfig
      freetype
      dbus
      libdrm
      zlib
      openssl
    ];

  extraInstallCommands = ''
    install -Dm444 ${contents}/io.github.zortos293.lichii.desktop \
      $out/share/applications/lichii.desktop
    substituteInPlace $out/share/applications/lichii.desktop \
      --replace-fail 'TryExec=lichii' "" \
      --replace-fail 'Exec=lichii' 'Exec=${pname}'
    install -Dm444 ${contents}/usr/share/icons/hicolor/256x256/apps/io.github.zortos293.lichii.png \
      $out/share/icons/hicolor/256x256/apps/io.github.zortos293.lichii.png
  '';

  meta = {
    description = "Experimental Nintendo Switch and Switch 2 emulator";
    homepage = "https://github.com/callme-sy/Lichii-Superbuild";
    license = lib.licenses.unfree;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
