# Generates a chadrc.lua that makes NvChad's base46 theme track the same
# matugen/wallpaper-derived base16 palette that stylix uses system-wide.
#
# It overrides the built-in "onedark" theme's colours via
# `M.base46.changed_themes` rather than shipping a standalone theme file
# (the format base46 itself uses — see NvChad/base46 themes/onedark.lua):
#   - base_16 maps 1:1 to the matugen base00..base0F
#   - base_30 (named UI colours) is derived from the same palette
{ matugenScheme }:

let
  s = matugenScheme;
  c = name: "#" + s.${name};
in
''
  -- Generated from the matugen wallpaper palette (see home/editor/nvchad/theme.nix).
  -- Do not edit ~/.config/nvim/lua/chadrc.lua directly: hm-activation overwrites it.
  ---@type ChadrcConfig
  local M = {}

  M.base46 = {
    theme = "onedark",
    transparency = true, -- let the terminal/compositor blur show through (text fg unchanged)
    changed_themes = {
      onedark = {
        type = "dark",
        base_16 = {
          base00 = "${c "base00"}",
          base01 = "${c "base01"}",
          base02 = "${c "base02"}",
          base03 = "${c "base03"}",
          base04 = "${c "base04"}",
          base05 = "${c "base05"}",
          base06 = "${c "base06"}",
          base07 = "${c "base07"}",
          base08 = "${c "base08"}",
          base09 = "${c "base09"}",
          base0A = "${c "base0A"}",
          base0B = "${c "base0B"}",
          base0C = "${c "base0C"}",
          base0D = "${c "base0D"}",
          base0E = "${c "base0E"}",
          base0F = "${c "base0F"}",
        },
        base_30 = {
          white = "${c "base05"}",
          darker_black = "${c "base00"}",
          black = "${c "base00"}", -- nvim bg
          black2 = "${c "base01"}",
          one_bg = "${c "base01"}",
          one_bg2 = "${c "base02"}",
          one_bg3 = "${c "base02"}",
          grey = "${c "base03"}",
          grey_fg = "${c "base03"}",
          grey_fg2 = "${c "base04"}",
          light_grey = "${c "base04"}",
          red = "${c "base08"}",
          baby_pink = "${c "base08"}",
          pink = "${c "base08"}",
          line = "${c "base02"}", -- for lines like vertsplit
          green = "${c "base0B"}",
          vibrant_green = "${c "base0B"}",
          nord_blue = "${c "base0D"}",
          blue = "${c "base0D"}",
          yellow = "${c "base0A"}",
          sun = "${c "base0A"}",
          purple = "${c "base0E"}",
          dark_purple = "${c "base0E"}",
          teal = "${c "base0C"}",
          orange = "${c "base09"}",
          cyan = "${c "base0C"}",
          statusline_bg = "${c "base01"}",
          lightbg = "${c "base02"}",
          pmenu_bg = "${c "base0D"}",
          folder_bg = "${c "base0D"}",
        },
      },
    },
  }

  return M
''
