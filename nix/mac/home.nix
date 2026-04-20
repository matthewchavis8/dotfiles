{ lib, pkgs, ... }:

{
  xdg.configFile."aerospace/aerospace.toml" = lib.mkIf pkgs.stdenv.isDarwin {
    source = ../../aerospace/aerospace.toml;
  };
  xdg.configFile."alacritty/alacritty.toml" = lib.mkIf pkgs.stdenv.isDarwin {
    source = ../../Alacritty/alacritty.toml;
  };
  xdg.configFile."alacritty/one-dark.toml" = lib.mkIf pkgs.stdenv.isDarwin {
    source = ../../Alacritty/one-dark.toml;
  };
  xdg.configFile."sketchybar/sketchybarrc" = lib.mkIf pkgs.stdenv.isDarwin {
    source = ../../sketchybar/sketchybarrc;
  };
  xdg.configFile."sketchybar/plugins" = lib.mkIf pkgs.stdenv.isDarwin {
    recursive = true;
    source = ../../sketchybar/plugins;
  };
}
