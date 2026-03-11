set -gx EDITOR nvim
set -gx GPG_TTY (tty)
set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
set -g fish_greeting

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

mise activate fish | source
mise completion fish | source

function load_mise_tool_completions --on-variable PWD
    set active_tools (mise ls --current 2>/dev/null | awk '{print $1}')
    for tool in $active_tools
        switch $tool
            case bun
                if not set -q __mise_bun_loaded
                    if type -q bun
                        bun completions fish | source
                        set -g __mise_bun_loaded 1
                    end
                end
            case pnpm
                if not set -q __mise_pnpm_loaded
                    if type -q pnpm
                        pnpm completion fish | source
                        set -g __mise_pnpm_loaded 1
                    end
                end
        end
    end
end

if test -d ~/.config/environment.d
    for file in ~/.config/environment.d/*.conf
        fenv source $file
    end
end

if status is-interactive
    fish_vi_key_bindings

    set -g fish_cursor_default block
    set -g fish_cursor_insert line
    set -g fish_cursor_replace_one underscore
    set -g fish_cursor_visual block

    type -q starship; and starship init fish | source
    type -q zoxide; and zoxide init fish | source

    type -q zoxide; and zoxide init fish --cmd cd | source

    abbr g git
    abbr lzg lazygit
    abbr lzd lazydocker
    alias mkcd='mkdir -p $argv; and cd $argv'
    alias vim='nvim'
    alias ..='cd ..'
    alias ...='cd ../..'
    abbr -a -- - 'cd -'
    alias n='nvim'
    alias dev='code-insiders .'
    alias code="code-insiders"
end

if type -q eza
    alias ls='eza -lh --icons=auto --group-directories-first'
    alias ll='eza -lha --icons=auto --sort=name --group-directories-first'
    alias l='eza -lh --icons=auto'
    alias la='eza -lha --icons=auto'
    alias ld='eza -lhD --icons=auto'
    alias lt='eza --icons=auto --tree --level=2'
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

if test -n "$aurhelper"
    alias un="$aurhelper -Rns"
    alias up="$aurhelper -Syu --noconfirm"
    alias look="$aurhelper -Qs"
    alias search="$aurhelper -Ss"
    alias pc="$aurhelper -Sc"
    alias po="$aurhelper -Qtdq | $aurhelper -Rns -"
    alias pi="$aurhelper -Si"
    alias orphans="$aurhelper -Qtdq"
    alias ua-drop-caches="sudo paccache -rk3; $aurhelper -Sc --aur --noconfirm"
end

function fcd
    set -l dir (find . -maxdepth 5 \( -name .git -o -name node_modules -o -name .next -o -name dist \) -prune -o -type d -print 2>/dev/null | fzf --height=60% --layout=reverse --preview='eza -la --icons=auto {}' --preview-window=right:60%)
    test -n "$dir"; and cd "$dir"
end

function fe
    set -l file (fzf --preview='bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:60%)
    test -n "$file"; and $EDITOR "$file"
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

function fish_user_key_bindings
    bind \ep parufind-widget
    bind -M insert \ch backward-delete-char
    bind -M insert \cf forward-char
end

# compress without node_modules and dist
function compress-project
    set -l archive $argv[1]
    set -e argv[1]
    tar --exclude='node_modules' --exclude='dist' -czf $archive $argv
end
