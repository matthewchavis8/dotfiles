{ user, ... }:

{
  networking.computerName = "matthewchavis8";
  networking.hostName = "matthewchavis8";
  networking.localHostName = "matthewchavis8";

  system.primaryUser = user;

  nixpkgs.hostPlatform = "aarch64-darwin";
}
