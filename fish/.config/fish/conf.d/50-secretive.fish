if test (uname) = Darwin
    if set -q SSH_CONNECTION; and test -S "$SSH_AUTH_SOCK"
        # In an SSH session with a forwarded agent, keep that agent. A
        # Secretive key asks for Touch ID on this Mac, and nobody can approve
        # it from a remote session. jj signs with the first key of the agent
        # in an SSH session (see nix/home/default.nix).
        set -l keys (ssh-add -L 2>/dev/null)
        and printf '%s\n' $keys[1] >~/.ssh/forwarded-signing.pub
    else
        set -l secretive "$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
        test -S $secretive; and set -gx SSH_AUTH_SOCK $secretive
    end
end
