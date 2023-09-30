# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

if [ "$(uname)" = Linux ] ; then
    PLATFORM="$(lsb_release -s -i)-$(lsb_release -s -r)-$(uname -m)"
else
    # Use only POSIX-conformant uname options.
    PLATFORM="$(uname -s)-$(uname -r)-$(uname -m)"
fi

# set PATH so it includes user's private bin dirs if they exist

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/local/bin" ] ; then
    PATH="$HOME/local/bin:$PATH"
fi

if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"

    for X in "$HOME/bin/"* ; do
        if [ -d "$X" ] ; then
            PATH="$X:$PATH"
        fi
    done
fi

# Platform-specific prepended after, so they take precedence.

if [ -d "$HOME/$PLATFORM/local" ] ; then
    PATH="$HOME/$PLATFORM/local/bin:$PATH"
    export LD_LIBRARY_PATH="$HOME/$PLATFORM/local/lib:$LD_LIBRARY_PATH"
fi

if [ -d "$HOME/$PLATFORM/bin" ] ; then
    PATH="$HOME/$PLATFORM/bin:$PATH"

    for X in "$HOME/$PLATFORM/bin/"* ; do
        if [ -d "$X" ] ; then
            PATH="$X:$PATH"
        fi
    done
fi

export PATH