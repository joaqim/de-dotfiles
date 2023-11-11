_my_bash_prompt_sep_prefix="⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤"
_my_bash_prompt_sep_with_time="\D{%F %T %Z}⏤⏤⏤"

declare -A _my_bash_prompt_sep_widths=(
    [prefix]=12
    [time]=$(( 23 + 3 ))
)

function _my_bash_prompt_setup_widths()
{
    _my_bash_prompt_sep_widths[total]=$(tput cols)
    _my_bash_prompt_sep_widths[stretch]=$((  _my_bash_prompt_sep_widths[total]
                                           - (  _my_bash_prompt_sep_widths[prefix]
                                              + _my_bash_prompt_sep_widths[time]) ))
    _my_bash_prompt_sep_stretch=""
    local stretch=${_my_bash_prompt_sep_widths[stretch]}
    while (( stretch-- >= 1 )); do
        _my_bash_prompt_sep_stretch+="⏤"
    done
}

function _my_bash_prompt_setup()
{
    if _my_terminal_supports_colors; then
        local DO_COLORS=yes
    else
        local DO_COLORS=no
    fi

    # Preserve any preexisting PROMPT_COMMAND and execute it.  NixOS /etc/bashrc
    # sets it for showing info in VTE terminals' window title.  The preexisting
    # command must be executed after, so that _my_bash_prompt_command is
    # executed first, as needed to capture the PREV_EXIT_STATUS=$? of the user's
    # command.
    PROMPT_COMMAND="_my_bash_prompt_command $DO_COLORS ${PROMPT_COMMAND:+;} ${PROMPT_COMMAND:-}"

    _my_bash_prompt_setup_widths
}

function _my_bash_prompt_command()
{
    local PREV_EXIT_STATUS=$?
    local - ; set +o xtrace +o verbose  # When user has these enabled, don't want for prompt.
    local DO_COLORS="$1"

    if [ "$(tput cols)" -ne "${_my_bash_prompt_sep_widths[total]}" ]; then
        _my_bash_prompt_setup_widths
    fi

    # shellcheck disable=SC2034  # Unused variables left for readability.
    if [ "$DO_COLORS" = yes ]; then
        local RED="\[\e[00;31m\]"
        local GREEN="\[\e[00;32m\]"
        local YELLOW="\[\e[00;33m\]"
        local BLUE="\[\e[00;34m\]"
        local WHITE="\[\e[01;37m\]"
        local GREY="\[\e[00;37m\]"
        local MAGENTA="\[\e[00;35m\]"
        local NO_COLOR="\[\e[00m\]"
    else
        local RED=""
        local GREEN=""
        local YELLOW=""
        local BLUE=""
        local WHITE=""
        local GREY=""
        local MAGENTA=""
        local NO_COLOR=""
    fi

    if ((PREV_EXIT_STATUS == 0)); then
        local STATUS_PREFIX="${GREY}${_my_bash_prompt_sep_prefix}"
    else
        local PAD=""
        local WIDTH=${#PREV_EXIT_STATUS}
        while ((WIDTH++ < 3)); do
            PAD+="⏤"
        done
        local STATUS_PREFIX="${RED}!⏤⏤⏤⏤\\\$?=${PREV_EXIT_STATUS}⏤${PAD}"
    fi

    if [ $EUID -eq 0 ]; then
        local USER_HOST_COLOR="${MAGENTA}"
        local CWD_COLOR="${BLUE}"
        local SIGIL_COLOR="${RED}"
        local SIGIL="▪"  # Alts: •▫
    else
        local USER_HOST_COLOR="${GREEN}"
        local CWD_COLOR="${BLUE}"
        local SIGIL_COLOR="${YELLOW}"
        local SIGIL="▸"  # Alts: ▹‣❭❱⟩⟫〉
    fi

    PS1="${STATUS_PREFIX}${_my_bash_prompt_sep_stretch}${_my_bash_prompt_sep_with_time}\n"
    PS1+="${USER_HOST_COLOR}\u@\h ${CWD_COLOR}\w\n"
    PS1+="${SIGIL_COLOR}${SIGIL}${NO_COLOR} "

    # Set the title to: user@host dir
    case "$TERM" in
        xterm*|rxvt*|screen|vt100)
            PS1="\[\e]0;\u@\h: \w\a\]$PS1"
            ;;
        *)
            ;;
    esac

    PS2="${SIGIL_COLOR}⁝${NO_COLOR} "

    PS0="${GREY}${_my_bash_prompt_sep_prefix}${_my_bash_prompt_sep_stretch}"
    PS0+="${_my_bash_prompt_sep_with_time}${NO_COLOR}\n"
}

_my_bash_prompt_setup

# unset -f _my_bash_prompt_setup
