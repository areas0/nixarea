self: super:
let
  version = "0.10.3";

  bundleSrc = super.fetchzip {
    url = "https://github.com/DonutWare/Fladder/releases/download/v${version}/Fladder-Linux-${version}.zip";
    stripRoot = false;
    sha256 = "sha256-1qb239AiO66GOkK+VvvEaxlT9tJElsTOkoNc++qwqoU=";
  };

  iconSvg = super.fetchurl {
    url = "https://raw.githubusercontent.com/DonutWare/Fladder/v${version}/assets/Icon.svg";
    sha256 = "sha256-ag6H70nN64V3FmSRDzeFWdMdD1hpuHiDuVpT+21JHQU=";
  };

  desktopEntry = super.makeDesktopItem {
    name = "fladder";
    desktopName = "Fladder";
    comment = "A simple cross-platform Jellyfin client";
    exec = "fladder %U";
    icon = "fladder";
    terminal = false;
    type = "Application";
    categories = [
      "AudioVideo"
      "Video"
      "Player"
      "Network"
    ];
    startupWMClass = "fladder";
    mimeTypes = [ "x-scheme-handler/jellyfin" ];
  };
in
{
  fladder = super.stdenv.mkDerivation rec {
    pname = "fladder";
    inherit version;

    src = bundleSrc;

    nativeBuildInputs = with super; [
      patchelf
      file
      autoPatchelfHook
      copyDesktopItems
    ];

    buildInputs = with super; [
      gtk3
      mpv
      libGL
      glib
      glib-networking
      libxkbcommon
      wayland
      libx11
      libxcursor
      libxext
      libxfixes
      libxrandr
      libxrender
      libxi
      libxcb
      libepoxy
      lz4
    ];

    desktopItems = [ desktopEntry ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      # Copy the entire bundle structure
      mkdir -p $out
      cp -r ./* $out/

      # Ensure the main binary is executable
      if [ -f "$out/Fladder" ]; then
        chmod +x "$out/Fladder"
      fi

      # Get library paths from NixOS
      LIBRARY_PATH=${super.lib.makeLibraryPath buildInputs}

      # Fix RPATH for all shared libraries in lib/ directory
      if [ -d "$out/lib" ]; then
        find "$out/lib" -type f \( -name "*.so" -o -name "*.so.*" \) | while read lib; do
          if file "$lib" | grep -q "ELF"; then
            patchelf --set-rpath "\$ORIGIN:$LIBRARY_PATH" "$lib" 2>/dev/null || true
          fi
        done
      fi

      # Fix RPATH for the main binary
      if [ -f "$out/Fladder" ]; then
        patchelf --set-rpath "\$ORIGIN/lib:$LIBRARY_PATH" "$out/Fladder" 2>/dev/null || true
      fi

      # Create a wrapper script in bin/
      mkdir -p $out/bin
      cat > $out/bin/fladder <<EOF
      #!${super.stdenv.shell}
      cd "$out"
      exec "$out/Fladder" "\$@"
      EOF
      chmod +x $out/bin/fladder

      # Install the icon
      mkdir -p $out/share/icons/hicolor/scalable/apps
      cp ${iconSvg} $out/share/icons/hicolor/scalable/apps/fladder.svg

      runHook postInstall
    '';

    meta = with super.lib; {
      description = "A simple cross-platform Jellyfin client";
      homepage = "https://github.com/DonutWare/Fladder";
      license = licenses.gpl3;
      maintainers = [ ];
      platforms = platforms.linux;
    };
  };
}
