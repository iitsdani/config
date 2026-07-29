{
  # Make Homebrew binaries runnable.
  environment.systemPath = [
    "/opt/homebrew/bin"
  ];

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap"; # "zap" removes manually installed brews and casks
    };

    brews = [
      "awscli"
      "docker"
      "docker-compose"
      "docker-credential-helper-ecr"
    ];

    casks = [
      "dbeaver-community"
      "stats"
    ];
  };
}
