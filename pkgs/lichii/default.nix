# Lichii (experimental Nintendo Switch / Switch 2 emulator), wrapped from the
# upstream AppImage. The bundle is self-contained (RPATH=$ORIGIN/../lib, Qt6 +
# ffmpeg shipped inside) but expects an FHS system for GL/Vulkan/X11/audio, so
# it runs inside appimageTools' FHS env rather than being patchelf'd.
#
# Fetched from the RedSyl/lichii-superbuild releases on gitgud.io (unofficial
# PGO builds with curated fixes on top of zortos293/Lichii). The previous
# source, callme-sy/Lichii-Superbuild on GitHub, was deleted; its last build
# (v56) is archived in ~/archive/lichii/. Bump with `scripts/update-lichii`.
{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "lichii";
  version = "69";

  # `url` and `hash` are rewritten together with `version` by
  # scripts/update-lichii. Release assets live on catbox.moe (random ids), so
  # the url cannot be derived from the version.
  src = fetchurl {
    name = "Lichii-v${version}-linux-x64-pgo.AppImage";
    url = "https://gitgud.io/api/v4/projects/53102/packages/generic/lichii-superbuild/v69/lichii-linux-x86_64-pgo.AppImage";
    hash = "sha256-uc5gjKAVll0sp5blKzjhi2SjAGOAb2A9iK29WY/LDno=";
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
