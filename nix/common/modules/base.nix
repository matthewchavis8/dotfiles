{ user, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.trusted-users = [
    "@admin"
    user
  ];

  nixpkgs.config.allowUnfree = true;
}
