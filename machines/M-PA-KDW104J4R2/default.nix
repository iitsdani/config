{ darwin, home-manager, nix-colors, sops-nix, nixvim, llm-agents, ... }@inputs:
let
  nixpkgs = import inputs.nixpkgs {
    config.allowUnfree = true;
    config.allowUnsupportedSystem = true;
    config.allowBroken = true;
  };
in
darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  inputs = { inherit darwin nixpkgs; };
  modules = [
    sops-nix.darwinModules.sops
    home-manager.darwinModules.home-manager
    nix-colors.homeManagerModule
    ../../modules/system/nix-latest.nix
    ../../modules/system/fish.nix
    ../../modules/darwin/machine-default.nix
    ../../modules/darwin/aerospace.nix
    ./homebrew.nix
    {
      system.primaryUser = "ar3s3ru";
      sops.defaultSopsFile = ./secrets.yaml;

      home-manager.sharedModules = [
        sops-nix.homeManagerModules.sops
        nixvim.homeModules.nixvim
      ];

      home-manager.useGlobalPkgs = false;
      home-manager.useUserPackages = true;
      home-manager.users.ar3s3ru = {
        imports = [
          ../../modules/home/opencode
          ./user-ar3s3ru.nix
        ];

        # NOTE: if the creation of secrets doesn't work, check
        # the <Program> in `less ~/Library/LaunchAgents/org.nix-community.home.sops-nix.plist`
        # and run the command manually.
        sops.defaultSopsFile = ./secrets.yaml;
      };

      home-manager.extraSpecialArgs.inputs = inputs;
      home-manager.extraSpecialArgs.colorscheme = nix-colors.colorSchemes.monokai;
      home-manager.extraSpecialArgs.ssh.public-key = ./id_ed25519.pub;
    }
  ];
}
