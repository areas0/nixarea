# Copyright (c) 2026 tsrk. <tsrk@tsrk.me>
# This file is licensed under the MIT license
# See the LICENSE file in the repository root for more info.

# SPDX-License-Identifier: MIT

{
  asar,
  p7zip,
  autoPatchelfHook,
  electron,
  libcxx,
  callPackage,
  writeShellScript,
  bettersqlite3 ? callPackage ./better-sqlite3 { inherit electron; },
  bufferutil ? callPackage ./bufferutil { },
  fetchurl,
  stdenv,
  makeBinaryWrapper,
  lib,
}:

let
  notion = writeShellScript "notion-app-launcher" ''
    XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
    RUNTIME="@out@/lib-exec/notion-app"

    if [ -f "$XDG_CONFIG_HOME/notion-flags.conf" ]; then
      NOTION_USER_FLAGS="$(grep -v ^# $XDG_CONFIG_HOME/notion-flags.conf)"
    else
      NOTION_USER_FLAGS=
    fi

    cd "$RUNTIME"
    exec electron "$RUNTIME/app.asar" $NOTION_USER_FLAGS "$@"
  '';

in
stdenv.mkDerivation (finalAttrs: {
  pname = "notion-bin";
  version = "7.39.0";

  src = fetchurl {
    url = "https://desktop-release.notion-static.com/Notion%20Setup%20${finalAttrs.version}.exe";
    hash = "sha256-l6pIn0vxZn/HpY8UDjsDxv3XhJaqe3Q9xP92bgNSIs0=";
  };

  nativeBuildInputs = [
    asar
    autoPatchelfHook
    p7zip
    makeBinaryWrapper
  ];

  buildInputs = [
    electron
    libcxx
  ];

  unpackPhase = ''
    runHook preUnpack
    ls -la

    7z x "$src" \$PLUGINSDIR/app-64.7z -y
    7z x \$PLUGINSDIR/app-64.7z resources/app.asar{,.unpacked} -y
    asar e resources/app.asar asar_patched

    rm -rfv \$PLUGINSDIR/app-64.7z

    runHook postUnpack
  '';

  sourceRoot = ".";

  passthru = {
    inherit bufferutil bettersqlite3;
  };

  patchPhase = ''
    runHook prePatch

    mkdir -vp asar_patched/node_modules/bufferutil/build/Release

    cp -vf "${bettersqlite3}/lib/better-sqlite3/better_sqlite3.node" asar_patched/node_modules/better-sqlite3/build/Release/
    cp -vf "${bufferutil}/lib/bufferutil/bufferutil.node" asar_patched/node_modules/bufferutil/build/Release/bufferutil.node
    cp -vf ${./notion.png} "asar_patched/.webpack/main/trayIcon.png"

    sed -i 's|this.tray.on("click",()=>{this.onClick()})|this.tray.setContextMenu(this.trayMenu),this.tray.on("click",()=>{this.onClick()})|g' "asar_patched/.webpack/main/index.js"
    sed -i 's|getIcon(){[^}]*}|getIcon(){return require("path").resolve(__dirname, "trayIcon.png");}|g' "asar_patched/.webpack/main/index.js"

    # fake the useragent as windows to fix the spellchecker languages selector and other issues
    sed -i 's|e.setUserAgent(`''${e.getUserAgent()} WantsServiceWorker`),|e.setUserAgent(`''${e.getUserAgent().replace("Linux", "Windows")} WantsServiceWorker`),|g' "asar_patched/.webpack/main/index.js"

    # use the windows version of the tray menu
    sed -i 's|="win32"===process.platform?function(e,t){const{isOpenAtLoginEnabled|="linux"===process.platform?function(e,t){const{isOpenAtLoginEnabled|g' "asar_patched/.webpack/main/index.js"

    # Notion handles auto-update opt-out and single-instance/url opening on linux
    # natively since 7.3x, so those patches are gone. Fail the build if a patch
    # above stops matching the (minified) bundle instead of silently skipping it.
    for needle in \
      'this.tray.setContextMenu(this.trayMenu),this.tray.on("click"' \
      'trayIcon.png");}' \
      'getUserAgent().replace("Linux", "Windows")' \
      '="linux"===process.platform?function(e,t){const{isOpenAtLoginEnabled'; do
      grep -qF -- "$needle" asar_patched/.webpack/main/index.js \
        || { echo "patch no longer applies: $needle" >&2; exit 1; }
    done

    runHook postPatch
  '';

  buildPhase = ''
    runHook preBuild

    asar p asar_patched app.asar --unpack '*.node'

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -vp $out/{bin,share/icons/hicolor/256x256/apps,lib-exec/notion-app}

    cp -v app.asar $out/lib-exec/notion-app
    cp -av app.asar.unpacked $out/lib-exec/notion-app
    cp -v asar_patched/package.json $out/lib-exec/notion-app
    cp -v ${./notion.png} $out/share/icons/hicolor/256x256/apps/notion.png

    substituteAll ${notion} $out/bin/notion-app
    chmod -v +x $out/bin/notion-app
    wrapProgram $out/bin/notion-app \
      --add-flags "\''${NIXOS_OZONE_WL:+''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --prefix PATH : "${lib.makeBinPath finalAttrs.buildInputs}"

    runHook postInstall
  '';
})
