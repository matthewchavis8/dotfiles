{ lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    feh
    i3
    i3status
    rofi
    xclip
  ];

  xdg.configFile."i3/config".source = ../../i3/i3/config;
  xdg.configFile."i3status/config".source = ../../i3-status/i3status/config;

  home.file.".config/neofetch/config.conf" = lib.mkIf (builtins.pathExists ../../neofetch/config.conf) {
    source = ../../neofetch/config.conf;
  };
}
