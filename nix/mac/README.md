# Mac Flake

This flake is the macOS entrypoint for this repo.

## Activate

First activation:

```bash
./bootstrap.sh mac
```

This uses the generic `bootstrap` configuration, so a fresh Mac can activate without adding a host file first.

After bootstrap:

```bash
darwin-rebuild switch --flake "$(pwd)/nix/mac#bootstrap"
```

## Where To Declare Things

- Shared CLI packages and user config: `../common/home/mchavis/base.nix`
- Mac-only Home Manager config: `home.nix`
- Mac-only system settings: `modules/system.nix`
- Mac-only apps via Homebrew: `modules/homebrew.nix`
- Per-machine overrides: `hosts/<hostname>.nix`

## Add Another Mac

1. Copy `templates/host.nix` to `hosts/<hostname>.nix`.
2. Set the three networking names and platform.
3. Run `darwin-rebuild switch --flake "$(pwd)/nix/mac#<hostname>"`.

Host files are now optional. If `hosts/<hostname>.nix` does not exist, the flake falls back to a generic module that uses the hostname as the networking name and the selected system as `hostPlatform`.
