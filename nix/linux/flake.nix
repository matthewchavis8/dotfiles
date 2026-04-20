{
  description = "Linux Home Manager configuration for mchavis";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { home-manager, nixpkgs, ... }:
    let
      user = "mchavis";
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit user;
          hostname = "linux";
        };
        modules = [
          ../common/home/mchavis/base.nix
          ./home.nix
        ];
      };
    };
}
