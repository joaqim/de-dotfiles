# (Remember: This might also be source'ed by other things or at other times -
#  e.g. by my `nix-shell --pure` wrapper.)
#
# (This logic has a lot of `|| return` to be robust by aborting early, and `|| true` to be robust
#  by continuing, which is helpful when unusual strange circumstances could break this logic,
#  which is helpful to still allow login to continue with such strangeness, versus exiting the
#  shell which would prevent login.)

if [ ! "${MY_BASH_CONFIG:-}" ]; then
    # All related config files are relative to the current file.
    MYSELF_RELDIR=$(command -p  dirname "${BASH_SOURCE[0]}") || return  # (Must be outside any function.)
    MY_BASH_CONFIG=$(command -p  realpath -m -L -s "$MYSELF_RELDIR"/../..) || return
    unset MYSELF_RELDIR
fi

MY_BASH_HISTDIR=${XDG_STATE_HOME:-~/.local/state}/my/bash/interactive/history

MY_BASH_COMBINED_HISTFILE_LOCK=${XDG_RUNTIME_DIR:-/tmp/user/${USER:-$EUID}}/
MY_BASH_COMBINED_HISTFILE_LOCK+=my/bash/interactive/history/combined.lock
command -p  mkdir -p "$(command -p  dirname "$MY_BASH_COMBINED_HISTFILE_LOCK")" || return

MY_BASH_HISTORY_COMBINER_IGNORES=$MY_BASH_CONFIG/interactive/history/ignores.regexes
export MY_BASH_HISTORY_COMBINER_IGNORES  # For my-bash_history-combiner utility.

# Append to the history file, don't overwrite it
shopt -s histappend
# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
# Don't expand !
set +o histexpand
# Save multi-line commands as one entry.
shopt -s cmdhist
# Save multi-line commands as multi-line (instead of as a single line converted to have ";").
shopt -s lithist

# Separate history file for each Bash session, for keeping an organized archive, and for assisting
# the immediate writing of each command without interleaving such with other instances doing the
# same.  Another good consequence is that things like `nix-shell --pure` that disable `histappend`
# and so wipe-out the $HISTFILE but that don't source ~/.bashrc (e.g. due to using --rcfile)
# cannot wipe-out my main history file because those things will use a different HISTFILE value
# (this is true independently of my extra `nix-shell` shell function).
function _my_unique_histfile {
    local - ; set -o nounset +o errexit
    local ID=$1 FILENAME DIRNAME
    FILENAME=$MY_BASH_HISTDIR/by-time/$(command -p  date +%Y/%m/%d/%T)--${HOSTNAME}${ID:+--}$ID || return
    DIRNAME="$(command -p  dirname "$FILENAME")" || return
    command -p  mkdir -p "$DIRNAME" || return
    if type -t mktemp >& /dev/null; then
        FILENAME=$(command -p  mktemp "$FILENAME"--XXXXXXXXXX) || return
    fi
    echo "$FILENAME"
}

if ! [[ "${HISTFILE:-}" = */by-time/* ]]
then
    MY_BASH_SESSION_HISTFILE=$(_my_unique_histfile $$) || return
    # Assign these HIST* once ready - might cause side-effects.
    HISTFILE=$MY_BASH_SESSION_HISTFILE
else
    # HISTFILE was already setup according to my custom scheme, so keep using that.
    MY_BASH_SESSION_HISTFILE=$HISTFILE
fi
# Practically unlimited, but limited against madness.
HISTFILESIZE=10000000
# Limit a mad session's history to be small enough to not clobber much of the `combined` file.
HISTSIZE=$((HISTFILESIZE / 100))
# Don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth
# Don't put commands matching these in the history.
HISTIGNORE=\\:  # The `:` command by itself.
# Cause timestamps to be written to the history file, which is also needed for
# `lithist` to preserve single-entry of a multi-line entry.  Also used when the
# `history` builtin command displays the history.
HISTTIMEFORMAT='%F %T %Z:  '

# Mutex the `combined` file, because multiple sessions access it.
function _my_lock_combined_histfile {
    local - ; set -o nounset +o errexit
    local LOCK_FD LOCK_FILE=$MY_BASH_COMBINED_HISTFILE_LOCK
    exec {LOCK_FD}>> "$LOCK_FILE"  # Open a new file descriptor of it.
    if command -p  flock "${1:-}" --timeout 10 $LOCK_FD ; then
        echo $LOCK_FD
    else
        echo "Failed to lock $LOCK_FILE" >&2
        exec {LOCK_FD}>&-  # Close the FD to clean-up.
        return 1
    fi
}

function _my_load_combined_histfile {
    local - ; set -o nounset +o errexit
    local LOCK_FD
    if LOCK_FD=$(_my_lock_combined_histfile --shared); then
        history -n "$MY_BASH_HISTDIR"/combined  # (-n seems slightly more appropriate than -r)
        exec {LOCK_FD}>&-  # Close the FD to release the lock.
    fi
}

# Start with the past history of combined old sessions.
_my_load_combined_histfile || return

# Immediately write each command to the history file, in case this Bash session has some problem
# and fails to do so when it exits.
PROMPT_COMMAND="${PROMPT_COMMAND:-} ${PROMPT_COMMAND:+;} history -a || true"

# Helper command for when you want a session to not save any of its history.
# Note that `history -a` etc will do nothing, as desired, without a HISTFILE.
function no-histfile {
    local - ; set -o nounset +o errexit
    [ "${MY_BASH_SESSION_HISTFILE:-}" ] && command -p  rm "${1:--i}" "$MY_BASH_SESSION_HISTFILE"
    unset HISTFILE MY_BASH_SESSION_HISTFILE
}

# Combine the previous `combined` history with this session's and write that as the new `combined`
# history with further ignoring and deduplication, so that the `combined` history file is like a
# database of more-interesting past commands without preserving them all nor their session's
# sequence, whereas a per-session history file is a complete record of all the session's commands
# and preserves their sequence.
function _my_histfile_combining {
    local - ; set -o nounset +o errexit

    history -a || true  # Ensure this session's history file is completed.

    [ "${MY_BASH_SESSION_HISTFILE:-}" ] && [ "${MY_BASH_HISTDIR:-}" ] || return

    if [ -s "$MY_BASH_SESSION_HISTFILE" ]; then
        command -p  chmod a-w "$MY_BASH_SESSION_HISTFILE"  # Protect it as an archive.

        if _my_lock_combined_histfile --exclusive > /dev/null
        then
            [ -e "$MY_BASH_HISTDIR"/combined ] || command -p  touch "$MY_BASH_HISTDIR"/combined || return
            local PREV_COMBINED
            PREV_COMBINED=$(command -p  mktemp "$MY_BASH_HISTDIR"/combined-prev-XXXXXXXXXX) || return
            command -p  cp "$MY_BASH_HISTDIR"/combined "$PREV_COMBINED" || return

            if type my-bash_history-combiner >& /dev/null; then
                local MY_BASH_HISTORY_COMBINER=my-bash_history-combiner
            else
                # When it's not in the PATH (e.g. when inside `nix-shell --pure`), assume it's
                # here:
                local MY_BASH_HISTORY_COMBINER=~/.nix-profile/bin/my-bash_history-combiner
            fi

            if ! $MY_BASH_HISTORY_COMBINER "$PREV_COMBINED" "$MY_BASH_SESSION_HISTFILE" \
                   > "$MY_BASH_HISTDIR"/combined  # Write to original, to preserve inode.
            then
                command -p  cp -f "$PREV_COMBINED" "$MY_BASH_HISTDIR"/combined  # Restore if error.
            fi
            command -p  rm -f "$PREV_COMBINED"

            # When the bash process terminates, it will close the lock FD which will release the
            # lock.
        fi
    else
        no-histfile -f  # If this session had no commands entered, delete its empty history file.
    fi
}

function _my_histfile_combining_ignore_failure {
    _my_histfile_combining || true
}

if [ -v IN_NIX_SHELL ]; then
    # Run it via the exitHandler EXIT trap of $stdenv/setup of nix-shell.
    exitHooks+=(_my_histfile_combining_ignore_failure)
elif [ -z "$(trap -p EXIT)" ]; then  # Don't replace any preexisting trap.
    trap _my_histfile_combining_ignore_failure EXIT
else
    echo "Note: Unable to setup _my_histfile_combining for exit." 1>&2
fi
