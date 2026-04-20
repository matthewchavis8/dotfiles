{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };

    taps = [
      "nikitabobko/tap"
    ];

    brews = [
      "sketchybar"
    ];

    casks = [
      "alacritty"
      "aerospace"
      "font-0xproto-nerd-font"
    ];
  };
}
