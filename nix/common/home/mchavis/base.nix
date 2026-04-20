{ pkgs, user, ... }:

{
  home.username = user;
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${user}" else "/home/${user}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    bat
    eza
    fd
    fzf
    jq
    neovim
    ripgrep
    tmux
  ];

  programs.git.enable = true;
  programs.git.signing.format = null;

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "eza -la";
      vim = "nvim";
    };
    initContent = ''
      export EDITOR=nvim
      export VISUAL=nvim
    '';
  };

  xdg.configFile."nvim".source = ../../../../nvim;

  home.file.".tmux.conf".source = ../../../../tmux/.tmux.conf;
}
