{ pkgs, pkgs-unstable }:

let
  matugenJson = wallpaper:
    pkgs.runCommand "matugen-colors.json" {
      nativeBuildInputs = [ pkgs-unstable.matugen pkgs.jq ];
    } ''
      matugen image ${wallpaper} \
        --mode dark \
        --type scheme-tonal-spot \
        --contrast 0.0 \
        --source-color-index 0 \
        --lightness-dark -0.5 \
        -j strip | jq '.colors' > $out
    '';
in

wallpaper:
let
  c = builtins.fromJSON (builtins.readFile (matugenJson wallpaper));
  hex = name: builtins.substring 1 6 c.${name}.default.color;
in
{
  slug = "material-you-amoled";
  scheme = "Material You AMOLED";
  author = "matugen";
  base00 = "000000";
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
