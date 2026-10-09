# Bun would install bunx if absent; only request completions when both exist.
if type -q bun; and type -q bunx
    __mise_load_completion env SHELL=/usr/bin/fish bun completions
end
