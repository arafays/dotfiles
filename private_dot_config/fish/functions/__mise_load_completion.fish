function __mise_load_completion
    type -q $argv[1]; or return 1

    # A regular file avoids truncated pipe output from some CLI generators.
    set -l completion_file (mktemp -t mise-completions.XXXXXX.fish 2>/dev/null)
    or return 1
    set -l completion_status 1
    if $argv >"$completion_file" 2>/dev/null
        if fish --no-config -n "$completion_file" 2>/dev/null
            source "$completion_file" 2>/dev/null
            and set completion_status 0
        end
    end
    command rm -f -- "$completion_file"
    return $completion_status
end
