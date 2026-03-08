# darwin.nix — system-level macOS config
{ pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    curl
    wget
    git
  ];

  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      tilesize = 48;
    };
    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv"; # column view
      ShowPathbar = true;
    };
    trackpad = {
      Clicking = true; # tap to click
      TrackpadThreeFingerDrag = true;
    };
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
    };
  };

  homebrew = {
    enable = true;
    casks = [
      "ghostty"
      "1password"
      "tailscale"
      "font-meslo-lg-nerd-font"
    ];
    brews = [
      "docker"
      "colima"
      "docker-compose"
      "snowsql"
    ];
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
  };

  # Colima autostart via launchd
  launchd.user.agents.colima = {
    command = "/opt/homebrew/bin/colima start --cpu 4 --memory 8 --disk 60";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/tmp/colima.log";
      StandardErrorPath = "/tmp/colima.error.log";
    };
  };

  services.tailscale.enable = true;

  # Nix store maintenance
  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 0; Minute = 0; }; # weekly, sunday midnight
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  # Flake update reminder
  system.activationScripts.postActivation.text = ''
    days_since_update=0
    if [ -f /etc/nix/flake-last-update ]; then
      last=$(cat /etc/nix/flake-last-update)
      now=$(date +%s)
      days_since_update=$(( (now - last) / 86400 ))
    fi

    if [ "$days_since_update" -gt 14 ]; then
      echo "⚠️  It's been $days_since_update days since your last nix flake update. Consider running 'nix flake update'."
    fi
  '';

  users.users.robinseitz = {
    name = "robinseitz";
    home = "/Users/robinseitz";
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = 5;
}
