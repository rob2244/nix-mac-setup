# flake.nix
{
  description = "Robin's Mac configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvim-config = {
      url = "github:rob2244/neovim-config";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nvim-config }: {
    darwinConfigurations."robins-macbook" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin"; # change to x86_64-darwin for Intel
      modules = [
        ./darwin.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.robin = import ./home.nix;
        }
      ];
    };
  };
}
