# home.nix — user environment
{ pkgs, lib, config, ... }: {

  home.stateVersion = "24.11";
  home.homeDirectory = "/Users/robinseitz";
  home.username = "robinseitz";

  home.packages = with pkgs; [
    # dev tools
    gh                                    # github cli
    awscli2
    direnv
    tmux
    jq
    ripgrep
    fzf
    eza
    zoxide
    bat
    bun
    lazygit
    pgcli
    httpie
    jwt-cli
    act                                   # run github actions locally

    # infra / cloud
    pulumi
    pulumiPackages.pulumi-python

    # security
    gitleaks
    _1password-cli                        # op CLI

    # system libs
    libpq
  ];

  # Git
  programs.git = {
    enable = true;
    settings = {
      user.name = "Robin";
      user.email = "robin@kater.ai";
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
      gpg.format = "ssh";
      gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      commit.gpgsign = true;
      user.signingkey = "~/.ssh/id_ed25519.pub";
      hooks.pre-commit = "${pkgs.gitleaks}/bin/gitleaks protect --staged -v";
    };
  };

  # SSH — delegate auth to 1Password agent
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

      Host robins-macbook
        HostName robins-macbook.your-tailnet.ts.net
        User robin
    '';
  };

  # AWS config
  home.file.".aws/config".text = ''
    [default]
    region = us-east-1
    output = json

    [profile AdministratorAccess-767847486830]
    sso_start_url = https://d-9067f11d43.awsapps.com/start
    sso_region = us-east-1
    sso_account_id = 767847486830
    sso_role_name = AdministratorAccess
    region = us-east-1
    output = json
  '';

  # Neovim — config managed via separate repo
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };

  home.activation.cloneNvimConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "$HOME/code/neovim-config" ]; then
      echo "Cloning neovim config..."
      $DRY_RUN_CMD git clone git@github.com:rob2244/neovim-config.git "$HOME/code/neovim-config" || \
        echo "Warning: could not clone neovim config. Run: git clone git@github.com:rob2244/neovim-config.git ~/code/neovim-config"
    fi
  '';

  xdg.configFile."nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "/Users/robinseitz/code/neovim-config";
    recursive = true;
  };

  # Ghostty — auto-attach to tmux on open
  xdg.configFile."ghostty/config".text = ''
    command = tmux new-session -A -s main
    font-family = MesloLGS Nerd Font
    font-size = 13
  '';

  # Tmux
  programs.tmux = {
    enable = true;
    shortcut = "a";
    baseIndex = 1;
    mouse = true;
    terminal = "screen-256color";
    extraConfig = ''
      set -g status-style bg=black,fg=white
      setw -g pane-base-index 1

      # reload config
      bind r source-file ~/.tmux.conf \; display "Config reloaded!"

      # splits
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # vim-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # pane resizing
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5
    '';
  };

  # direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
      aws = {
        disabled = false;
        symbol = "☁️  ";
      };
      direnv = {
        disabled = false;
        symbol = "📦 ";
      };
      git_branch.symbol = " ";
      nodejs.symbol = " ";
      python.symbol = " ";
      golang.symbol = " ";
      rust.symbol = " ";
    };
  };

  # Zsh
  programs.zsh = {
    enable = true;
    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      share = true;
    };
    oh-my-zsh = {
      enable = true;
      # no theme — starship handles the prompt
      plugins = [
        "aliases"
        "docker"
        "docker-compose"
        "git"
        "fzf"
      ];
    };
    plugins = [
      { name = "zsh-vi-mode"; src = pkgs.zsh-vi-mode; }
      { name = "zsh-fzf-tab"; src = pkgs.zsh-fzf-tab; }
    ];
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls  = "eza --icons";
      ll  = "eza -la --icons";
      cat = "bat";
      cd  = "z";
      lkb = "ghostty +list-keybinds";
      lg  = "lazygit";
      db  = "pgcli $DATABASE_URL";
    };

    envExtra = ''
      export ZVM_VI_ESCAPE_BINDKEY="jk"
      export EDITOR="nvim"
      export OP_ACCOUNT="katerai.1password.com"

      # bun
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"

      # kater
      export TIKTOKEN_CACHE_DIR="/tmp/tiktoken"
      export HATCHET_CLIENT_NAMESPACE="dev-robin"
      export DEEPEVAL_RESULTS_FOLDER="$HOME/code/kater/server/internal/llm/prompt/tests/deepeval_results"
      export POSTGRES_VOLUME_DIR="/tmp/postgres-data"

      # libpq
      export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"

      # aws
      export AWS_PROFILE=AdministratorAccess-767847486830
    '';

    initContent = ''
      # auto-attach to tmux on SSH
      if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]]; then
        tmux new-session -A -s main
      fi

      # fzf
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
      zvm_after_init_commands+=('[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh')

      # direnv
      eval "$(direnv hook zsh)"

      # zoxide
      eval "$(zoxide init zsh)"

      # colima / docker
      export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
      export DOCKER_CONFIG="$HOME/.docker"
      mkdir -p ~/.docker/cli-plugins
      ln -sf $(brew --prefix)/opt/docker-compose/bin/docker-compose ~/.docker/cli-plugins/docker-compose 2>/dev/null

      # 1password
      export OP_BIOMETRIC_UNLOCK_ENABLED=true
    '';
  };

  # Claude Code — installed via npm
  home.activation.installClaudeCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if ! command -v claude &>/dev/null; then
      echo "Installing Claude Code..."
      $DRY_RUN_CMD ${pkgs.nodePackages.npm}/bin/npm install -g @anthropic-ai/claude-code || \
        echo "Warning: could not install Claude Code. Run: npm install -g @anthropic-ai/claude-code"
    fi
  '';
}
