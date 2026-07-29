{ config, lib, pkgs, ... }:
let
  font = "MesloLGSDZ Nerd Font";
in
{
  imports = [
    ../../modules/darwin/gpg.nix
    ../../users/ar3s3ru.nix
  ];

  home.username = lib.mkForce "danilo.cianfrone";

  programs.alacritty.settings.font.normal.family = font;

  programs.vscode.profiles.default.userSettings = {
    "editor.fontFamily" = lib.mkForce "'${font}'";
    "editor.fontSize" = 14;
  };

  home.activation.configureEcrCredentialHelper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    docker_config="$HOME/.docker/config.json"
    if [ -z "$DRY_RUN_CMD" ]; then
      mkdir -p "$HOME/.docker"
      if [ -f "$docker_config" ]; then
        ${pkgs.jq}/bin/jq '.credsStore = "ecr-login"' "$docker_config" > "$docker_config.tmp"
        mv "$docker_config.tmp" "$docker_config"
      else
        ${pkgs.jq}/bin/jq -n '{ credsStore: "ecr-login" }' > "$docker_config"
      fi
    fi
  '';

  sops.secrets.awsconfig.path = "${config.home.homeDirectory}/.aws/config";

  home.packages = with pkgs; [
    nodejs
    pnpm
    jdk25
  ];
}
