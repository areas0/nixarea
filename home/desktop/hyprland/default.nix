{
  pkgs,
  config,
  lib,
  additionalConfig,
  ...
}:
{
  imports = [
    ./settings.nix
  ];

  # Hyprland 0.55+: if hyprland.lua exists, it is loaded INSTEAD of
  # hyprland.conf, so this file is the whole runtime config; settings.nix only
  # enables the module.
  #
  # `@samsungFullLink@` in the lua file is substituted per host from
  # additionalConfig (true only where the Samsung gets a DP 1.4+DSC link).
  xdg.configFile."hypr/hyprland.lua".text =
    builtins.replaceStrings
      [ "@samsungFullLink@" ]
      [ (lib.boolToString (additionalConfig.samsungFullLink or false)) ]
      (builtins.readFile ./hyprland.lua);

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Run the Hyprland portal with Qt theming disabled, so that the screen-share
  # picker it spawns can actually start.
  #
  # The picker is a Qt6 app from pkgs-unstable (qtbase 6.11.2), while qt6ct and
  # the Kvantum style come from stable via stylix (qtbase 6.11.1). Kvantum's
  # Qt6 style plugin will not load across that gap - it is absent from the
  # picker's module list at crash time, while qt6ct's own plugin loads fine.
  # qt6ct-style is a QProxyStyle: when QStyleFactory::create("kvantum") returns
  # nothing it falls back to the application's current style, which is
  # qt6ct-style itself. QProxyStyle::standardPalette() then recurses into itself
  # until the stack is exhausted and the picker dies with SIGSEGV before it can
  # draw anything - so Slack and Meet get no screen-choice prompt at all, with
  # no visible error.
  #
  # Downgrading the portal to the stable one is not an option: stable ships
  # xdph 1.3.12, which pairs with Hyprland 0.55.4, and these hosts run 0.56.2.
  # Scoping the two Qt variables to this one unit leaves every other Qt app
  # themed, and keeps working whenever the two channels' qtbase diverge again.
  # Drop once the portal and the Qt theming stack come from one nixpkgs.
  xdg.configFile."systemd/user/xdg-desktop-portal-hyprland.service.d/qt-theme-off.conf".text = ''
    [Service]
    Environment=QT_QPA_PLATFORMTHEME=
    Environment=QT_STYLE_OVERRIDE=
  '';

  gtk = {
    enable = true;
    # gtk4.theme is managed by stylix's gtk target (it mirrors gtk.theme), so
    # we no longer pin it here — doing so collides with stylix's definition.
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  qt.enable = true;

  # Hyprland is the primary session. Override stylix's followSystem default,
  # which picks up "kde" from Plasma 6 on the workstation — stylix's
  # home-manager Qt theming only supports "qtct".
  stylix.targets.qt.platform = lib.mkForce "qtct";
}
