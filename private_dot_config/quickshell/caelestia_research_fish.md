# fish Integration with Caelestia

## Configuration Overview
Fish shell is extensively configured in Caelestia with starship prompt, direnv/zoxide integration, custom aliases, and color schemes.

## Key Features
- **Starship Prompt**: Custom prompt initialization
- **Directory Tools**: direnv and zoxide integration for directory jumping
- **Enhanced ls**: eza with icons and directory-first sorting
- **Git Abbreviations**: Comprehensive git shortcuts (lg, gd, ga, gc, etc.)
- **File Operations**: Custom ls aliases (l, ll, la, lla)

## Interactive Features
- **Custom Greeting**: ASCII art logo with fastfetch system info
- **Color Sequences**: Loads custom color sequences from `~/.local/state/caelestia/sequences.txt`
- **Prompt Marking**: Special escape sequences for foot terminal prompt jumping

## Abbreviations
- **Git**: lg (lazygit), gd (diff), ga (add all), gc (commit), gl (log), gs (status), gp (push), gpl (pull), gsw (switch), gsm (switch main), gb (branch), gbd (delete branch), gco (checkout), gsh (show), gst (stash), gsp (stash pop)
- **File**: l (ls), ll (ls -l), la (ls -a), lla (ls -la)

## Integration Notes
Fish serves as the primary shell in Caelestia, with configurations that enhance productivity and integrate with other tools. The setup assumes starship, direnv, zoxide, and eza are installed.