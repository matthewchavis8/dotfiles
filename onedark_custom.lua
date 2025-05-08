-- Credits to original https://github.com/one-dark
-- This is modified version of it

local M = {}

M.base_30 = {
  white         = "#abb2bf",
  darker_black  = "#1c1f24",
  black         = "#1e2227",   -- main background
  black2        = "#24272b",
  one_bg        = "#282c34",   -- true one-dark bg
  one_bg2       = "#353b45",
  one_bg3       = "#3c4048",
  grey          = "#4b5057",
  grey_fg       = "#5c6370",
  grey_fg2      = "#6c7086",
  light_grey    = "#7f8495",
  red           = "#e06c75",
  baby_pink     = "#de6b72",
  pink          = "#ff79c6",
  line          = "#31353f",
  green         = "#98c379",
  vibrant_green = "#8dc149",
  nord_blue     = "#61afef",
  blue          = "#61afef",
  yellow        = "#D7DAE0",
  sun           = "#e5c07b",
  purple        = "#c678dd",
  dark_purple   = "#a76ac9",
  teal          = "#56b6c2",
  orange        = "#d19a66",
  cyan          = "#56b6c2",
  statusline_bg = "#23252e",
  lightbg       = "#2c2e33",
  pmenu_bg      = "#61afef",
  folder_bg     = "#61afef",
}

M.base_16 = {
  base00 =  "#282C34",
  base01 = "#353b45",
  base02 = "#3e4451",
  base03 = "#545862",
  base04 = "#565c64",
  base05 = "#abb2bf",
  base06 = "#b6bdca",
  base07 = "#c8ccd4",
  base08 = "#e06c75",
  base09 = "#D19A66",
  base0A = "#EBCB8B",
  base0B = "#98c379",
  base0C = "#56b6c2",
  base0D = "#61afef",
  base0E = "#C378D7",
  base0F = "#e06c75",
}

M.type = "dark"

-- merge with the built-in onedark variants
M = require("base46").override_theme(M, "onedark")

return M
