if test (uname) = Darwin
    set -l secretive "$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
    test -S $secretive; and set -gx SSH_AUTH_SOCK $secretive
end
