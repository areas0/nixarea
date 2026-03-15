{ pkgs, pkgs-unstable }:

{
  schemeType ? "scheme-tonal-spot",
  contrast ? 0.0,
  lightnessDark ? -0.5,
  amoled ? true,
}:

let
  matugenJson =
    wallpaper:
    pkgs.runCommand "matugen-colors.json"
      {
        nativeBuildInputs = [
          pkgs-unstable.matugen
          pkgs.jq
        ];
      }
      ''
        matugen image ${wallpaper} \
          --mode dark \
          --type ${schemeType} \
          --contrast ${toString contrast} \
          --source-color-index 0 \
          --lightness-dark ${toString lightnessDark} \
          -j strip | jq '.colors' > $out
      '';
in

wallpaper:
let
  c = builtins.fromJSON (builtins.readFile (matugenJson wallpaper));
  hex = name: builtins.substring 1 6 c.${name}.default.color;
in
{
  slug = "material-you" + (if amoled then "-amoled" else "");
  scheme = "Material You" + (if amoled then " AMOLED" else "");
  author = "matugen";
  base00 = if amoled then "000000" else hex "surface";
  base01 = hex "surface_container";
  base02 = hex "surface_container_high";
  base03 = hex "outline";
  base04 = hex "on_surface_variant";
  base05 = hex "on_surface";
  base06 = hex "on_secondary_container";
  base07 = hex "on_primary_container";
  base08 = hex "error";
  base09 = hex "tertiary";
  base0A = hex "secondary";
  base0B = hex "primary";
  base0C = hex "inverse_primary";
  base0D = hex "primary";
  base0E = hex "tertiary";
  base0F = hex "outline_variant";
}
