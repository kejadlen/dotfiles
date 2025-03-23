action=$1
file=$2
shift 2

export HOMEBREW_BUNDLE_FILE=$file

case $action in
  status)
    baking_platform_is "Darwin" || return $STATUS_UNSUPPORTED_PLATFORM
    needs_exec "brew" || return $STATUS_FAILED_PRECONDITION
    bake [ -e $file ] || return $STATUS_FAILED_PRECONDITION
    HOMEBREW_NO_AUTO_UPDATE=true bake brew bundle check --no-upgrade > /dev/null || return $STATUS_MISSING
    HOMEBREW_NO_AUTO_UPDATE=true bake brew bundle check > /dev/null || return $STATUS_OUTDATED
    return $STATUS_OK ;;
  install)
    HOMEBREW_NO_AUTO_UPDATE=true bake brew bundle install
    ;;
  upgrade)
    HOMEBREW_NO_AUTO_UPDATE=true bake brew bundle upgrade
    ;;
  remove)
    return $STATUS_CONFLICT_HALT
    ;;
  *) return 1 ;;
esac
