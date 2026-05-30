###-begin-opencode-completions-###
#
# Fish shell completions for opencode
#
# Installation:
#   opencode completion --shell fish | source                                    # Current session
#   opencode completion --shell fish > ~/.config/fish/completions/opencode.fish  # Permanent
#

function __opencode_yargs_completions
    set -l tokens (commandline -opc)
    set -l current (commandline -ct)

    # Ask yargs to generate completions.
    # Setting SHELL=zsh triggers yargs' built-in "name:description" output format.
    # We parse the colon-separated pairs and convert to Fish's tab-separated format.
    set -l completions (SHELL=zsh command opencode --get-yargs-completions $tokens $current 2>/dev/null)

    for completion in $completions
        # Parse yargs "name:description" format into Fish's tab-separated format.
        # Yargs escapes literal colons in names as "\\:" so we split on the first
        # unescaped colon only. Fish's complete builtin expects "name\\tdescription"
        # where \\t is a real tab character -- printf handles this correctly.
        set -l parts (string split -m 1 ':' -- $completion)

        # Filter out yargs internal placeholders (matched after parsing since
        # SHELL=zsh output includes descriptions like "$0:start opencode tui")
        switch $parts[1]
            case '$0' _generate_completions
                continue
        end

        if test (count $parts) -gt 1 -a -n "$parts[2]"
            printf '%s\\t%s\\n' $parts[1] $parts[2]
        else
            echo $completion
        end
    end
end

complete -c opencode -f -a '(__opencode_yargs_completions)'
###-end-opencode-completions-###
