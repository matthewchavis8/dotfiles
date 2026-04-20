{ user, ... }:

{
  networking.computerName = "replace-me";
  networking.hostName = "replace-me";
  networking.localHostName = "replace-me";

  system.primaryUser = user;

  nixpkgs.hostPlatform = "aarch64-darwin";
}
