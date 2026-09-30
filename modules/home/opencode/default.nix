{ config, pkgs, ... }:

{
  # NOTE: access tokens for models should be managed manually
  # with the machine that is using it.
  #
  # For MCP servers for now it's ok to share tokens.

  home.packages = [ pkgs.llm-agents.opencode ];

  sops.secrets.github-token = {
    mode = "0400";
    sopsFile = ./credentials.enc.json;
    path = "${config.home.homeDirectory}/.local/share/opencode/github-token";
  };

  sops.secrets.databricks-it = {
    mode = "0400";
    sopsFile = ./credentials.enc.json;
    path = "${config.home.homeDirectory}/.local/share/opencode/databricks-it";
  };

  sops.secrets.databricks-uk = {
    mode = "0400";
    sopsFile = ./credentials.enc.json;
    path = "${config.home.homeDirectory}/.local/share/opencode/databricks-uk";
  };

  sops.secrets.youtrack = {
    mode = "0400";
    sopsFile = ./credentials.enc.json;
    path = "${config.home.homeDirectory}/.local/share/opencode/youtrack";
  };

  home.file."opencode-json" = {
    executable = false;
    target = ".config/opencode/opencode.json";
    source = ./opencode.json;
  };

  home.file."opencode-agents-md" = {
    executable = false;
    target = ".config/opencode/AGENTS.md";
    source = ./AGENTS.md;
  };
}
