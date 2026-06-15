{ lib, pkgs, inputs, config, ... }:

{
  home.username = lib.mkDefault "ar3s3ru";
  home.stateVersion = lib.mkDefault "22.05";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
  nixpkgs.config.allowBroken = true;

  # Source: https://github.com/numtide/llm-agents.nix#binary-cache
  nix.settings = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  # Use llm-agents for opencode.
  nixpkgs.overlays = [
    inputs.llm-agents.overlays.default
    # FIXME(ar3s3ru): helm is broken on June 15th, fix was merged on June 12th but didn't
    # land on nixos-unstable yet.
    (final: prev: {
      kubernetes-helm = prev.kubernetes-helm.overrideAttrs (_: {
        doCheck = false;
      });
    })
  ];

  # FIXME: fish-completions is pulling in Python 2.7 but it breaks the build.
  nixpkgs.config.permittedInsecurePackages = [
    "python-2.7.18.7"
  ];

  # Make sure that the secrets decryption happens through
  # my private GPG key.
  sops.gnupg.home = "${config.home.homeDirectory}/.gnupg";
  sops.gnupg.sshKeyPaths = [ ];
  sops.age.sshKeyPaths = [ ];

  imports = [
    inputs.nix-colors.homeManagerModule
    ../modules/home/neovim
    ../modules/home/homelab
    ../modules/home/alacritty.nix
    ../modules/home/direnv.nix
    ../modules/home/fish.nix
    ../modules/home/git.nix
    ../modules/home/ssh.nix
    ../modules/home/vscode.nix
  ];

  programs = {
    home-manager.enable = true;
    gpg.enable = true;
  };

  home.packages = with pkgs; [
    dig
    jq
    yq-go
    mpv
    fastfetch
    hugo # For my website.
    grpcurl
    # LaTeX and TexLive
    texlive.combined.scheme-basic
    yt-dlp
  ];
}
