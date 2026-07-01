{ pkgs, ... }:

{
  home.packages = with pkgs; [
    python3
    poetry
    pyright
    ruff
    uv
  ];

  programs.poetry = {
    enable = true;
    package = pkgs.poetry;
    settings.virtualenvs.in-project = true;
  };
}
