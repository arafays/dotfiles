source /usr/share/cachyos-fish-config/cachyos-config.fish
set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"

# Fzf: transparent background with noctalia-inspired colors
set -gx FZF_DEFAULT_OPTS '--color=bg:-1,bg+:-1,fg:#dde1e6,fg+:#ffffff,border:#ffc799,hl:#99ffe4,hl+:#ffc799,info:#45475A,prompt:#ffc799,pointer:#ffc799,marker:#99ffe4,spinner:#ffc799,header:#99ffe4 --border=rounded --layout=reverse'

function fish_greeting
end

set -gx EDITOR nvim
set -gx GPG_TTY (tty)
set -gx SUDO_EDITOR nvim
set -gx BROWSER zen-browser
# AGENT_BROWSER_EXECUTABLE_PATH={CHROMIUM_PATH} use the chromium path set via environment.d for OpenCode MCP DevTools, fallback to BROWSER env var or xdg-open if not set
set -gx AGENT_BROWSER_EXECUTABLE_PATH (test -n "$CHROMIUM_PATH"; and echo $CHROMIUM_PATH; or echo $BROWSER; or which xdg-open)
set -Ux PORTLESS_NGROK 1

# Chromium path set via environment.d for OpenCode MCP DevTools
# set -gx CHROMIUM_PATH (which chromium 2>/dev/null || which google-chrome 2>/dev/null || echo "xdg-open")

if test -d ~/.config/environment.d
    for file in ~/.config/environment.d/*.conf
        fenv source $file
    end
end

mise activate fish | source

if status is-interactive
    fish_vi_key_bindings

    set -g fish_cursor_default block
    set -g fish_cursor_insert line
    set -g fish_cursor_replace_one underscore
    set -g fish_cursor_visual block

    type -q starship; and starship init fish | source
    type -q zoxide; and zoxide init fish --cmd cd | source

    alias vim='nvim'
    alias n='nvim'
    alias code="code-insiders"
    alias dev='code .'
    alias czd='chezmoi cd'

    abbr g git
    abbr lzg lazygit
    abbr lzd lazydocker
    abbr oc opencode
    abbr -a -- - 'cd -'

    function mkcd
        mkdir -p $argv; and cd $argv
    end

    if type -q eza
        alias ld='eza -lhD --icons=auto'
        set -gx EZA_COLORS "da=36:di=34:ex=32:fi=0:ln=35:pi=33:so=31"
    end

    if type -q bat
        alias cat='bat --style=plain --color=always --paging=never'
        alias less='bat --style=plain --color=always --paging=always'
    end

    if type -q fd
        alias find='fd'
    end
    if type -q rg
        alias grep='rg --color=auto --line-number --smart-case --hidden --glob "!.git"'
    end

    function fcd
        set -l dir (find . -maxdepth 5 \( -name .git -o -name node_modules -o -name .next -o -name dist \) -prune -o -type d -print 2>/dev/null | fzf --height=60% --layout=reverse --preview='eza -la --icons=auto {}' --preview-window=right:60%)
        test -n "$dir"; and cd "$dir"
    end

    set -gx aurhelper ""
    for helper in yay paru
        if type -q $helper
            set -gx aurhelper $helper
            break
        end
    end

    function in
        if test -n "$aurhelper"
            $aurhelper -S $argv
        else
            sudo pacman -S $argv
        end
    end

    function tn
        set -l session_name (basename $PWD | string replace -a '.' '_')
        tmux new-session -A -s "$session_name" -c "$PWD"
    end

    function ts
        set -l ses (tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --layout=reverse)
        if test -n "$ses"
            if test -n "$TMUX"
                tmux switch-client -t "$ses"
            else
                tmux attach-session -t "$ses"
            end
        end
    end

    # ── herdr session management ──
    # hn: create/attach to herdr workspace named after CWD (like tmux tn)
    function hn
        if not type -q herdr
            echo "herdr not installed" >&2
            return 1
        end
        set -l ws_name (basename $PWD | string replace -a '.' '_')
        # If already inside herdr, move current pane to new workspace
        if set -q HERDR_SOCKET_PATH
            set -l pane_id $HERDR_ACTIVE_PANE_ID
            if test -z "$pane_id"
                # Fallback: get current pane
                set pane_id (herdr pane current --pane --current 2>/dev/null | jq -r '.id // empty')
            end
            if test -n "$pane_id"
                herdr pane move "$pane_id" --new-workspace --label "$ws_name" --focus 2>/dev/null
            else
                echo "Could not detect current pane" >&2
            end
        else
            # Outside herdr: launch herdr
            echo "Launching herdr..."
            herdr
        end
    end

    # hs: fuzzy-find and switch herdr sessions (like tmux ts)
    function hs
        if not type -q herdr
            echo "herdr not installed" >&2
            return 1
        end
        set -l ses (herdr session list --json 2>/dev/null | jq -r '.[].name' | fzf --layout=reverse)
        if test -n "$ses"
            herdr session attach "$ses"
        end
    end

    # hd: detach from herdr (client keeps running in background)
    function hd
        if set -q HERDR_SOCKET_PATH
            # Inside herdr - send prefix+q via herdr CLI
            echo "Use prefix+q (ctrl+b q) to detach from inside herdr"
        else
            echo "Not inside a herdr session"
        end
    end

    # hw: list herdr workspaces in current session
    function hw
        if not type -q herdr
            echo "herdr not installed" >&2
            return 1
        end
        herdr workspace list 2>/dev/null
    end

    # hws: switch workspace via fzf
    function hws
        if not type -q herdr
            echo "herdr not installed" >&2
            return 1
        end
        set -l ws (herdr workspace list --json 2>/dev/null | jq -r '.[].label // .[].name' | fzf --layout=reverse)
        if test -n "$ws"
            herdr workspace focus "$ws" 2>/dev/null
        end
    end

    # hpane: split and run a command in new pane
    function hpane
        if not type -q herdr
            echo "herdr not installed" >&2
            return 1
        end
        set -l direction right
        if test (count $argv) -gt 0
            switch $argv[1]
                case -v --vertical
                    set direction right
                    set -e argv[1]
                case -h --horizontal
                    set direction down
                    set -e argv[1]
                case '*'
                    set direction right
            end
        end
        herdr pane split 1-1 --direction "$direction" 2>/dev/null
        if test (count $argv) -gt 0
            herdr pane run 1-2 "$argv" 2>/dev/null
        end
    end

    function compress
        set -l archive $argv[1]
        set -e argv[1]
        switch $archive
            case '*.tar.gz'
                tar -czf $archive $argv
            case '*.zip'
                zip -r $archive $argv
            case '*.7z'
                7z a $archive $argv
            case '*'
                echo "Unsupported format"
        end
    end

    function extract
        set -l archive $argv[1]
        switch $archive
            case '*.tar.gz' '*.tgz'
                tar -xzf $archive
            case '*.zip'
                unzip $archive
            case '*.7z'
                7z x $archive
            case '*'
                echo "Unsupported format"
        end
    end

    ### Paru/Yay Fuzzy Search (Alt + P)
    function parufind
        set -l pkg (paru -Ss "$argv" 2>/dev/null | awk '/^[a-z]/ {if (p != "") print p " | " d; p = $1; d = ""} /^    / {sub(/^    /, ""); d = $0} END {if (p != "") print p " | " d}' | fzf --ansi --height=80% --layout=reverse --border=rounded --preview='echo {} | cut -d "|" -f1 | tr -d " " | xargs -I{} paru -Si {}' | cut -d '|' -f1 | tr -d ' ')
        if test -n "$pkg"
            paru -S (echo $pkg | string trim)
        end
    end

    function parufind-widget
        read -P "Search AUR: " search
        test -n "$search"; and parufind "$search"
        commandline -f repaint
    end

    function ua-update-all
        type -q rate-mirrors; or return
        set -l TMPFILE (mktemp)
        if rate-mirrors --save=$TMPFILE arch --max-delay=21600
            sudo mv $TMPFILE /etc/pacman.d/mirrorlist
            sudo paccache -rk3
            test -n "$aurhelper"; and $aurhelper -Sc --aur --noconfirm
            $aurhelper -Syyu --noconfirm
        end
    end

    function fish_user_key_bindings
        bind \ep parufind-widget
        bind -M insert \ch backward-delete-char
        bind -M insert \cf forward-char
    end

    function zipclean
        set -l archive $argv[1]
        set -e argv[1]
        zip -r $archive $argv -x "*/node_modules/*" -x "*/dist/*"
    end

    ## create tar without node mnodules and dist folders
    function tarclean
        set -l archive $argv[1]
        set -e argv[1]
        tar --exclude='*/node_modules/*' --exclude='*/dist/*' -czf $archive $argv
    end

    # compress without node_modules and dist
    function compress-project
        set -l archive $argv[1]
        set -e argv[1]
        tar --exclude='node_modules' --exclude='dist' -czf $archive $argv
    end

    # compress all projects in current dir excluding build artifacts, keeping .git
    function compress-projects
        set -l dry_run 0
        set -l archive ""
        set -l args ()
        set -l excludes \
            node_modules .next .astro .svelte-kit .nuxt .output .turbo .vercel .expo \
            dist build out target __pycache__ .venv venv .ruff_cache .mypy_cache \
            .pytest_cache .cache .yarn .pnpm-store .direnv '*.pyc' .DS_Store \
            .terraform ios/build android/build .gradle .swiftpm Pods DerivedData \
            .nx .serverless coverage .nyc_output .eslintcache .parcel-cache \
            .angular .storybook/out .netlify

        for arg in $argv
            switch $arg
                case --dry-run -n
                    set dry_run 1
                case '*'
                    if test -z "$archive"
                        set archive $arg
                    else
                        set -a args $arg
                    end
            end
        end

        if test -z "$archive"
            set archive ../(basename $PWD)-(date +%Y%m%d).tar.gz
        end

        if test (count $args) -eq 0
            set args .
        end

        # Build exclude flags from list (noglob prevents *.pyc expansion)
        set -l exclude_flags
        for dir in $excludes
            set -a exclude_flags --exclude=$dir
        end

        if test $dry_run -eq 1
            noglob tar $exclude_flags -czvf /dev/null $args
        else
            noglob tar $exclude_flags -czf $archive $args
        end
    end
end

if status is-interactive
    mise completion fish | source
    type -q herdr; and herdr completion fish | source

    function _mise_load_tool_completions --on-variable PWD
        if not set -q __mise_completions_loaded
            set -g __mise_completions_loaded 1

            set active_tools (mise ls --current 2>/dev/null | awk '{print $1}')

            for tool in $active_tools
                switch $tool
                    case bun
                        if type -q bun; and not set -q __bun_completions_loaded
                            bun completions fish | source 2>/dev/null
                            set -g __bun_completions_loaded 1
                        end
                    case pnpm
                        if type -q pnpm; and not set -q __pnpm_completions_loaded
                            pnpm completion fish | source 2>/dev/null
                            set -g __pnpm_completions_loaded 1
                        end
                    case uv
                        if type -q uv; and not set -q __uv_completions_loaded
                            uv generate-shell-completion fish | source 2>/dev/null
                            set -g __uv_completions_loaded 1
                        end
                    case rust
                        if type -q rustup; and not set -q __rustup_completions_loaded
                            rustup completions fish | source 2>/dev/null
                            set -g __rustup_completions_loaded 1
                        end
                    case python
                        if type -q uv; and not set -q __uv_completions_loaded
                            uv generate-shell-completion fish | source 2>/dev/null
                            set -g __uv_completions_loaded 1
                        end
                    case aube
                        if type -q aube; and not set -q __aube_completions_loaded
                            aube activate fish | source 2>/dev/null
                            aube completion fish | source 2>/dev/null
                            set -g __aube_completions_loaded 1
                        end
                end
            end
        end
    end

    _mise_load_tool_completions
end

fish_add_path $HOME/.local/bin $HOME/.opencode/bin
