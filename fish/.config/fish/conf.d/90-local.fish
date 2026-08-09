# Machine-local settings. Untracked; setup.sh creates the file.
set -l local_config $__fish_config_dir/local.fish
test -r $local_config; and source $local_config
