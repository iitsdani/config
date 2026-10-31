{
  programs.fish.enable = true;

  programs.fish.interactiveShellInit = ''
    devenv hook fish -- --no-tui --no-reload | source
  '';

  programs.fish.shellAbbrs = {
    gp = "git push";
    gpf = "git push --force-with-lease";
    kgp = "kubectl get pods";
  };

  programs.fish.functions = {
    gbpurge = {
      description = "Removes branches that are either stale or deleted from upstream.";
      body = "git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -D";
    };

    gca = {
      description = "Use gca for adding new changes and amending them in the last Git commit without editing";
      body = "git add . && git commit --amend --no-edit";
    };
  };
}
