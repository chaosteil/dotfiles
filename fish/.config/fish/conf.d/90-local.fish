# Machine-local settings. The file is not tracked. Make it when you need it.
set -l local_config $__fish_config_dir/local.fish
test -r $local_config; and source $local_config
