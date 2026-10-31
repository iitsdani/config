{ lib, pkgs, colorscheme, ... }:

{
  programs.ghostty = {
    enable = true;
    package =
      if pkgs.stdenv.hostPlatform.isDarwin
      then pkgs.ghostty-bin
      else pkgs.ghostty;

    settings = {
      font-size = lib.mkDefault 12;
      font-family = lib.mkDefault "Terminus";

      background = "#${colorscheme.palette.base00}";
      foreground = "#${colorscheme.palette.base05}";
      cursor-color = "#${colorscheme.palette.base05}";
      cursor-text = "#${colorscheme.palette.base00}";

      palette = with colorscheme.palette; [
        "0=#${base00}"
        "1=#${base08}"
        "2=#${base0B}"
        "3=#${base0A}"
        "4=#${base0D}"
        "5=#${base0E}"
        "6=#${base0C}"
        "7=#${base05}"
        "8=#${base03}"
        "9=#${base08}"
        "10=#${base0B}"
        "11=#${base0A}"
        "12=#${base0D}"
        "13=#${base0E}"
        "14=#${base0C}"
        "15=#${base07}"
      ];
    };
  };
}
