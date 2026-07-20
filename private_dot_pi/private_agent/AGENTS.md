env: Linux/Arch/Wayland/cachyos (niri)
shell: fish
secrets: gnome-keyring
pkg: [paru, jdx/mise]
rules:

- edit source files in chezmoi repo, not live configs
- Use mise for tool management & global npm pkgs, like "mise use node@24" for project level or "mise use -g npm:vercel@latest" for global
- never run sudo — ask user for password commands
