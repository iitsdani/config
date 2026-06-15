{ pkgs, ... }:

{
  imports = [
    ../../modules/darwin/sops.nix
  ];


  system.stateVersion = 4;

  time.timeZone = "Europe/Rome";

  nix.settings.trusted-users = [ "root" "danilo.cianfrone" "@wheel" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    ripgrep
    # NOTE: git is also set up in Home Manager, but I'm keeping it here
    # so that I can also clone stuff without having a configured user
    # necessarily.
    git
    git-crypt
    gopass
    gopass-jsonapi
    gnumake
    killall
    plantuml
    graphviz
    unzip
    colima
  ];

  homebrew.brews = [
    "bitwarden-cli" # Marked as broken in nixpkgs.
  ];

  # Enable GnuPG Agent.
  # Please note, the actual agent config (e.g. pinentry)
  # is part of modules/gpg-darwin.nix.
  programs.gnupg.agent.enable = true;

  # NOTE: this is not working
  # security.pam.enableSudoTouchIdAuth = true;

  # QoL: Mac key mapping is confusing AF, make it more like Linux.
  # system.keyboard.enableKeyMapping = true;
  # system.keyboard.swapLeftCommandAndLeftAlt = true;

  # Enable fish shell globally, but configuration is in the Home Manager flake.
  environment.shells = [ pkgs.fish ];

  users.users."danilo.cianfrone" = {
    home = "/Users/danilo.cianfrone";
    shell = "${pkgs.fish}/bin/fish";
  };

  # NOTE: overrides various paths that points to non-valid ar3s3ru profile.
  sops.gnupg.home = "/Users/danilo.cianfrone/.gnupg";
  services.aerospace.settings.exec.env-vars.PATH = "/etc/profiles/per-user/danilo.cianfrone/bin:\${PATH}";

  environment.variables = {
    EDITOR = "nvim";
  };

  # TODO enable
  # system.defaults.NSGlobalDomain = {
  #   InitialKeyRepeat = 33; # unit is 15ms, so 500ms
  #   KeyRepeat = 2; # unit is 15ms, so 30ms
  #   NSDocumentSaveNewDocumentsToCloud = false;
  # };

  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
    nerd-fonts.terminess-ttf
  ];
}
