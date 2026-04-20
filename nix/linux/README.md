# Linux Flake

This flake is the Linux entrypoint for this repo.

## Activate

```bash
./bootstrap.sh linux
```

## Where To Declare Things

- Shared CLI packages and user config: `../common/home/mchavis/base.nix`
- Linux-only packages and desktop config: `home.nix`

This flake currently wires the existing `i3`, `i3status`, and `neofetch` files from the repo.
