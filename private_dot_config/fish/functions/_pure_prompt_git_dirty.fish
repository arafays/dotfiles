# Override pure's binary dirty marker (*) with per-kind file counts.
# Lives in ~/.config/fish/functions so it shadows /usr/share/fish/vendor_functions.d.
function _pure_prompt_git_dirty
    set --local porcelain (command git status --porcelain --ignore-submodules 2>/dev/null)
    test -z "$porcelain"; and return

    set --local modified 0
    set --local deleted 0
    set --local untracked 0
    for line in $porcelain
        set --local code (string sub -l 2 -- $line)
        if test "$code" = "??"
            set untracked (math $untracked + 1)
        else if string match -q -- '*D*' $code
            set deleted (math $deleted + 1)
        else if string match -qr '[MARCU]' -- $code
            set modified (math $modified + 1)
        end
    end

    set --local parts
    test $modified -gt 0; and set --append parts (_pure_set_color $pure_color_git_dirty)"$pure_symbol_git_dirty$modified"
    test $deleted -gt 0; and set --append parts (_pure_set_color $pure_color_danger)"D$deleted"
    test $untracked -gt 0; and set --append parts (_pure_set_color $pure_color_info)"?$untracked"

    test (count $parts) -eq 0; and return
    echo " "(string join ' ' $parts)
end
