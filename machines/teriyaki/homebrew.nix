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
      "docker"
      "docker-compose"
    ];

    casks = [
      "dbeaver-community"
      "whatsapp"
      "stats"
      "wireshark-app"
    ];
  };
}
