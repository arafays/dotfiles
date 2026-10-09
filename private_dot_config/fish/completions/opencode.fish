if not set -q __mise_opencode_completions_loaded
    __mise_load_completion opencode2 --completions fish
    and set -g __mise_opencode_completions_loaded 1
end
