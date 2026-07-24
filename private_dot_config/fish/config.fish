set -g fish_greeting
set -gx BROWSER chromium

# GPG TTY (runtime value, can't go in static environment.d)
if not set -q GPG_TTY
    set -gx GPG_TTY (tty)
end

# Essential PATH — mise shims + local bin (must come before any mise calls)
set -gx PATH $HOME/.local/share/mise/shims $HOME/.local/bin $PATH

# Import environment from systemd user daemon (~15ms vs ~750ms with fenv).
# systemd already loads ~/.config/environment.d/*.conf at login.
# After editing env.d files: systemctl --user daemon-reload
for line in (systemctl --user show-environment 2>/dev/null)
    set -l pair (string split --max 1 '=' -- $line)
    set -l key $pair[1]
    # Skip read-only or fish-managed variables
    contains -- $key PWD SHLVL _ PATH; and continue
    set -l val $pair[2]
    # systemd wraps special chars in $'...' — strip the wrapper and unescape inner quotes
    set -l _dollar_quote (printf '\x24\x27') # literal $'
    if test (string sub -l 2 -- $val) = "$_dollar_quote"
        set val (string sub -s 3 -- $val | string sub -e -1)
        set val (string replace -a "\\'" "'" -- $val)
    end
    set -gx $key $val
end

# === INTERACTIVE ===

# Build PATH: systemd shims + local bin + Android SDK
set -gx PATH $HOME/.local/share/mise/shims $HOME/.local/bin $PATH
if status is-interactive

    function __mise_deferred --on-event fish_prompt
        mise activate fish | source
        mise completion fish | source
        type -q zoxide; and zoxide init fish --cmd cd | source
        type -q herdr; and herdr completion fish | source # disabled: outputs JSON instead of fish completions
        functions -e __mise_deferred
    end

    function _mise_load_tool_completions --on-variable PWD
        if not set -q __mise_completions_loaded
            set -g __mise_completions_loaded 1

            # mise may not be in PATH yet (activate deferred to fish_prompt)
            if type -q mise
                set active_tools (mise ls --current 2>/dev/null | awk '{print $1}')
            end

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
                        if type -q pip; and not set -q __pip_completions_loaded
                            pip completion --fish | source 2>/dev/null
                            set -g __pip_completions_loaded 1
                        end
                end
            end
        end
    end

    _mise_load_tool_completions

    # vi key bindings
    fish_vi_key_bindings

    # abbreviations
    abbr g git
    abbr lzg lazygit
    abbr lzd lazydocker
    abbr oc opencode

    alias vim='nvim'
    abbr -a -- - 'cd -'
    alias n='nvim'
    alias code="code-insiders"
    alias dev='code .'
    alias czd='chezmoi cd'

    function mkcd
        mkdir -p $argv; and cd $argv
    end

    # ls replacements
    if type -q eza
        alias ls='eza -lh --icons=auto --group-directories-first'
        alias ll='eza -lha --icons=auto --sort=name --group-directories-first'
        alias l='eza -lh --icons=auto'
        alias la='eza -lha --icons=auto'
        alias ld='eza -lhD --icons=auto'
        alias lt='eza --icons=auto --tree --level=2'
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

    # === AUR HELPER ===
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

    # pacman aliases
    if test -n "$aurhelper"
        alias un="$aurhelper -Rns"
        alias up="$aurhelper -Syu --noconfirm"
        alias look="$aurhelper -Qs"
        alias search="$aurhelper -Ss"
        alias pc="$aurhelper -Sc"
        alias po="$aurhelper -Qtdq | $aurhelper -Rns -"
        alias psi="$aurhelper -Si"
        alias orphans="$aurhelper -Qtdq"
        alias ua-drop-caches="sudo paccache -rk3; $aurhelper -Sc --aur --noconfirm"
    end

    # tmux sessions
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
            set -l pane_id (herdr pane current --current 2>/dev/null | jq -r '.result.pane.pane_id // empty')
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
        set -l ses (herdr session list --json 2>/dev/null | jq -r '.sessions[].name' | fzf --layout=reverse)
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
        herdr workspace list 2>/dev/null | jq -r '.result.workspaces[] | (if .focused then "▸ " else "  " end) + .label + " (" + (.pane_count|tostring) + " panes)"'
    end

    # hws: switch workspace via fzf
    function hws
        if not type -q herdr
            echo "herdr not installed" >&2
            return 1
        end
        set -l ws_id (herdr workspace list 2>/dev/null | jq -r '.result.workspaces[] | .label + " " + .workspace_id' | fzf --layout=reverse | awk '{print $NF}')
        if test -n "$ws_id"
            herdr workspace focus "$ws_id" 2>/dev/null
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
        herdr pane split --current --direction "$direction" 2>/dev/null
        if test (count $argv) -gt 0
            set -l new_pane (herdr pane current --current 2>/dev/null | jq -r '.result.pane.pane_id // empty')
            if test -n "$new_pane"
                herdr pane run "$new_pane" "$argv" 2>/dev/null
            end
        end
    end

    # archive helpers
    function compress
        set -l split_size ""
        set -l archive ""
        set -l files ()

        for arg in $argv
            if string match -q -- '--split=*' $arg
                set split_size (string replace -- '--split=' '' $arg)
            else if test -z "$archive"
                set archive $arg
            else
                set -a files $arg
            end
        end

        if test (count $files) -eq 0
            if not string match -q -- '*.tar.gz' $archive; and not string match -q -- '*.zip' $archive; and not string match -q -- '*.7z' $archive
                set files $archive
                set archive "$archive.tar.gz"
            end
        end

        if test -n "$split_size"
            if not string match -q -- '*.7z' $archive
                set archive (string replace -r -- '\.tar\.gz$|\.zip$' '.7z' $archive)
            end
            7z a -v$split_size $archive $files
            return
        end

        switch $archive
            case '*.tar.gz'
                tar -czf $archive $files
            case '*.zip'
                zip -r $archive $files
            case '*.7z'
                7z a $archive $files
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

    # AUR search with fzf
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

    # ── pi suggest ──
    # Type a comment → pg → get a command
    # Type a command → pg → get an explanation
    function pg
        set -l cmd (commandline)

        # If called with arguments, use those directly
        if test (count $argv) -gt 0
            set -l prompt (string join ' ' $argv)
            pi -p --no-session --tools read,grep,find,ls "$prompt"
            return
        end

        # If called from keybinding (empty args), use commandline buffer
        test -z "$cmd"; and return

        if string match -q '#*' "$cmd"
            set -l prompt (string replace -r '^#\s*' '' -- $cmd)
            set -l result (pi -p --no-session --tools read,grep,find,ls "Convert to a shell command. Output ONLY the command, no explanation: $prompt" 2>/dev/null)
            test -n "$result"; and commandline -r "$result"
        else
            pi -p --no-session --tools read,grep,find,ls "Explain concisely: $cmd" 2>/dev/null
        end
    end

    function fish_user_key_bindings
        bind \ep parufind-widget
        bind -M insert \ch backward-delete-char
        bind -M insert \cf forward-char
    end

    # system update functions
    function ua-update-all
        set -l TMPFILE (mktemp)
        if rate-mirrors --save=$TMPFILE arch --max-delay=21600
            sudo mv $TMPFILE /etc/pacman.d/mirrorlist
            sudo paccache -rk3
            test -n "$aurhelper"; and $aurhelper -Sc --aur --noconfirm
            $aurhelper -Syyu --noconfirm
        end
    end

    function ua-update-chaotic
        set -l TMPFILE (mktemp)
        if rate-mirrors --save=$TMPFILE chaotic-aur
            sudo mv $TMPFILE /etc/pacman.d/chaotic-mirrorlist
            sudo paccache -rk3
            test -n "$aurhelper"; and $aurhelper -Sc --aur --noconfirm
            $aurhelper -Syyu --noconfirm
        end
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

    type -q starship; and starship init fish | source
end

# === PATH ===
# These are already in systemd env via environment.d (mise shims, etc.).
# fish_add_path only writes universal vars on first run; subsequent calls are no-ops.
fish_add_path --append $HOME/Android/Sdk/emulator \
    $HOME/Android/Sdk/cmdline-tools/latest/bin \
    $HOME/Android/Sdk/build-tools/36.1.0 \
    $HOME/Android/Sdk/platform-tools
