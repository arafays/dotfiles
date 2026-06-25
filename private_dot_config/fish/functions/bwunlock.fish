function bwunlock --description "Unlock Bitwarden vault and export BW_SESSION"
    set -l session (bw unlock --raw)
    if test $status -eq 0
        set -gx BW_SESSION $session
        echo "Bitwarden unlocked. BW_SESSION set."
    else
        echo "Failed to unlock Bitwarden." >&2
        return 1
    end
end
