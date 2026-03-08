# dotfiles

Robin's macOS configuration managed with [nix-darwin](https://github.com/LnL7/nix-darwin) and [Home Manager](https://github.com/nix-community/home-manager).

## What's in here

| File | Purpose |
|------|---------|
| `flake.nix` | Entry point — wires together nixpkgs, nix-darwin, and home-manager |
| `darwin.nix` | System-level macOS config (dock, finder, homebrew, launchd, nix settings) |
| `home.nix` | User environment (packages, shell, git, SSH, editor, tmux, etc.) |

## What gets installed

### Via Nix (home.nix)
- **Shell**: zsh + oh-my-zsh (agnoster theme → starship prompt) + zsh-vi-mode + fzf-tab
- **Editor**: neovim (config symlinked from [rob2244/neovim-config](https://github.com/rob2244/neovim-config))
- **Terminal multiplexer**: tmux
- **Git**: git + gh (GitHub CLI) + lazygit + gitleaks (pre-commit hook)
- **Cloud**: awscli2 (SSO configured), pulumi + pulumi-language-python
- **Dev tools**: direnv + nix-direnv, fzf, ripgrep, bat, eza, zoxide, jq, httpie, jwt-cli, pgcli, bun, act
- **Security**: 1Password CLI (op), gitleaks
- **System libs**: libpq

### Via Homebrew (darwin.nix)
- **Apps**: Ghostty, 1Password, Tailscale
- **Docker**: colima + docker CLI + docker-compose (no Docker Desktop)
- **Fonts**: MesloLGS Nerd Font (required for starship icons)
- **Snowflake**: snowsql

### macOS system settings
- Dark mode, tap to click, three-finger drag
- Dock autohide, no recent apps, size 48
- Finder: show extensions, column view, path bar
- Fast key repeat

## Prerequisites

A fresh Mac needs only two things before bootstrapping:

1. **Xcode Command Line Tools**
```bash
xcode-select --install
```

2. **Nix** (via Determinate Systems installer — more reliable than the official one):
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

## Bootstrap (fresh machine)

```bash
# 1. Clone this repo
git clone https://github.com/rob2244/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Apply the configuration
nix run nix-darwin -- switch --flake .#robins-macbook

# 3. Set up 1Password
#    Open 1Password → Settings → Developer → enable "Use the SSH agent"
#    This is required for SSH auth and git commit signing

# 4. Enable Tailscale SSH
sudo tailscale up --ssh

# 5. If the neovim config clone failed (1Password not set up yet), clone manually
git clone git@github.com:rob2244/neovim-config.git ~/code/neovim-config
```

After the first bootstrap, all future updates use:
```bash
darwin-rebuild switch --flake .#robins-macbook
```

## Applying changes

Edit any of the nix files, then run:
```bash
darwin-rebuild switch --flake .#robins-macbook
```

Changes are atomic — if something fails, the previous generation is still active and you can roll back:
```bash
darwin-rebuild --rollback
```

## Updating dependencies

```bash
# Update all flake inputs (nixpkgs, nix-darwin, home-manager) to latest
nix flake update

# Then apply
darwin-rebuild switch --flake .#robins-macbook
```

The activation script will remind you if it's been more than 14 days since your last update.

## Node / Python version management

Node and Python versions are intentionally **not** installed globally. Instead, each project manages its own version via direnv + nix devShells.

In any project, create a `flake.nix` with a `devShell` and a `.envrc`:
```bash
echo "use flake" > .envrc
direnv allow
```

Then `cd` into the project and the correct environment loads automatically. See the [devShell example](#devshell-example) below.

## Docker

Docker Desktop is not used. Instead:
- **Colima** provides the container runtime (auto-starts at login via launchd, 4 CPU / 8GB RAM)
- **docker CLI** + **docker-compose** are installed via Homebrew

If Colima isn't running:
```bash
colima start
# or check logs:
cat /tmp/colima.log
```

## AWS

SSO is configured for the Kater account. To authenticate:
```bash
aws sso login --profile AdministratorAccess-767847486830
```

The `AWS_PROFILE` env var is set globally in zsh so all AWS CLI commands use this profile by default.

## SSH + 1Password

All SSH keys are stored in 1Password. The SSH agent socket is configured globally in `~/.ssh/config` so every SSH connection (git, remote servers, Tailscale) goes through 1Password for auth.

Git commit signing is also handled by 1Password — commits are signed with your SSH key automatically.

## Tailscale SSH

Tailscale SSH lets you SSH into this machine from anywhere without managing keys:
```bash
ssh robin@robins-macbook.your-tailnet.ts.net
```

SSHing in automatically attaches to (or creates) a tmux session named `main`.

## Useful aliases

| Alias | Command |
|-------|---------|
| `ll` | `eza -la --icons` |
| `cat` | `bat` (syntax highlighted) |
| `cd` | `z` (zoxide — smarter cd) |
| `lg` | `lazygit` |
| `db` | `pgcli $DATABASE_URL` |
| `lkb` | `ghostty +list-keybinds` |

## Tmux keybindings

Prefix is `Ctrl-a`.

| Binding | Action |
|---------|--------|
| `prefix \|` | Split pane vertically |
| `prefix -` | Split pane horizontally |
| `prefix h/j/k/l` | Navigate panes (vim-style) |
| `prefix H/J/K/L` | Resize panes |
| `prefix r` | Reload tmux config |

## devShell example

A typical per-project `flake.nix` for a Python/uv project:

```nix
{
  description = "Kater backend";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
    let pkgs = nixpkgs.legacyPackages.${system}; in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [ python312 uv libpq openssl ];
        shellHook = ''
          export UV_PYTHON_PREFERENCE="only-system"
          export UV_PYTHON="${pkgs.python312}/bin/python"
          export DATABASE_URL="postgres://localhost/kater_dev"
          if [ ! -d .venv ]; then
            uv venv --python ${pkgs.python312}/bin/python
          fi
          source .venv/bin/activate
          uv sync
        '';
      };
    });
}
```

## Structure

```
dotfiles/
├── flake.nix       # flake entry point
├── darwin.nix      # system config
├── home.nix        # user config
└── README.md
```
