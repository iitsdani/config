{ lib, pkgs, ... }:
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

  home.packages = with pkgs; [
    nodejs
    pnpm
    jdk25
  ];
}
