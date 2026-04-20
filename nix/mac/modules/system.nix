{ inputs, pkgs, user, ... }:

{
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    curl
    git
  ];

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = 6;

  system.defaults = {
    dock = {
      autohide = true;
      mineffect = "scale";
      show-recents = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv";
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
  };

  users.users.${user} = {
    home = "/Users/${user}";
    shell = pkgs.zsh;
  };
}
