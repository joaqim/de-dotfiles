# shellcheck disable=SC2034  # These variables are used by what `source`s this file.


# Avoid source'ing this file more than once.
#
[ "${_MY_SH_SOURCED_ALREADY__PLATFORM_OS_HELPERS+is-set}" ] && return
# Set immediately, to avoid the possibility of recursive source'ing.
_MY_SH_SOURCED_ALREADY__PLATFORM_OS_HELPERS=true


# Platform-specific identification

MY_PLATFORM_VERSION=$(std uname -r)
readonly MY_PLATFORM_VERSION


# Functions

# For bootstrapping my setup independently of my other more-involved package-installing modules.
#
_my_install_bash()                      { sudo pkgin -y install bash ;}
_my_install_git()                       { sudo pkgin -y install git ;}

gnu() {
    [ $# -ge 1 ] || return 1

    # shellcheck disable=SC2145  # I know how `some"$@"` behaves and it's correct.

    if [ -x /usr/pkg/gnu/bin/"$1" ]; then
        /usr/pkg/gnu/bin/"$@"
    elif [ -x /usr/pkg/bin/g"$1" ]; then
        /usr/pkg/bin/g"$@"
    else
        error "No GNU utility found for $(quote "$1")!"
        return 2
    fi
}

_my_terminal_supports_colors() {
    case "${TERM:-}" in
        (*color*) return 0 ;;
        (*)       return 1 ;;
    esac
}

_my_terminal_width() {
    std tput cols
}

_my_flock() {
    std flock "$@"  # NetBSD's own `flock` is similar enough to that of util-linux.
}
