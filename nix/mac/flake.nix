{
  description = "macOS nix-darwin configuration for mchavis";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ home-manager, nix-darwin, ... }:
    let
      user = "mchavis";
      mkDarwinHost = { hostname, system ? "aarch64-darwin" }:
        let
          hostModulePath = ./hosts + "/${hostname}.nix";
          hostModule =
            if builtins.pathExists hostModulePath then
              hostModulePath
            else
              ({ user, ... }: {
                networking.computerName = hostname;
                networking.hostName = hostname;
                networking.localHostName = hostname;

                system.primaryUser = user;

                nixpkgs.hostPlatform = system;
              });
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs user hostname;
          };
          modules = [
            ../common/modules/base.nix
            ./modules/system.nix
            ./modules/homebrew.nix
            hostModule
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-backup";
              home-manager.extraSpecialArgs = {
                inherit inputs user hostname;
              };
              home-manager.users.${user} = {
                home.homeDirectory = "/Users/${user}";
                home.username = user;
                home.stateVersion = "24.11";
                imports = [
                  ../common/home/mchavis/base.nix
                  ./home.nix
                ];
              };
            }
          ];
        };
    in
    {
      darwinConfigurations.bootstrap = mkDarwinHost {
        hostname = "bootstrap";
      };

      darwinConfigurations.matthewchavis8 = mkDarwinHost {
        hostname = "matthewchavis8";
      };
    };
}
