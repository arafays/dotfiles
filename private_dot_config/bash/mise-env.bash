# Shared, lightweight environment for non-interactive Bash and Zsh.
# No prompt hooks or subprocesses: AI tools may source this for every command.

case ":${PATH-}:" in
  *:"$HOME/.local/bin":*) ;;
  *) PATH="$HOME/.local/bin${PATH:+:$PATH}" ;;
esac

_mise_env_shims="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims"
case ":${PATH-}:" in
  *:"$_mise_env_shims":*) ;;
  *) PATH="$_mise_env_shims${PATH:+:$PATH}" ;;
esac
unset _mise_env_shims

export PATH
export BASH_ENV="${XDG_CONFIG_HOME:-$HOME/.config}/bash/mise-env.bash"
