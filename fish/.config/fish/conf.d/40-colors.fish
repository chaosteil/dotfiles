# Pierre theme, dark variant. Every value comes from the palette of
# chaosteil/pierre-theme.nvim, and the comment names the palette entry.
# The colors are literal hex, not palette names, thus fish keeps the theme
# even in a terminal with a different color palette.

# Syntax
# fish leaves a valid command unstyled. The func purple marks it.
set -g fish_color_command 9d6afb # syntax.func
set -g fish_color_keyword ff678d # syntax.keyword
set -g fish_color_normal fafafa # fg.base
set -g fish_color_param d4d4d4 # fg.fg1
set -g fish_color_option 60d199 # syntax.attribute
set -g fish_color_quote 5ecc71 # syntax.string
set -g fish_color_escape 61d5c0 # syntax.escape
set -g fish_color_operator 08c0ef # syntax.operator
set -g fish_color_redirection 08c0ef # syntax.operator
set -g fish_color_end 636363 # syntax.punctuation
set -g fish_color_comment 737373 # syntax.comment
set -g fish_color_error ff2e3f # states.danger
set -g fish_color_cancel ff2e3f # states.danger
set -g fish_color_autosuggestion 636363 # fg.fg4
set -g fish_color_selection fafafa --background=19283c # fg.base on accent.subtle
set -g fish_color_search_match --background=19283c # accent.subtle

# Completion pager
set -g fish_pager_color_prefix 009fff --bold # accent.primary
set -g fish_pager_color_completion d4d4d4 # fg.fg1
set -g fish_pager_color_description 737373 # fg.fg3
set -g fish_pager_color_progress 636363 --background=171717 # fg.fg4 on bg.window
set -g fish_pager_color_selected_background --background=19283c # accent.subtle
set -g fish_pager_color_selected_completion fafafa # fg.base
set -g fish_pager_color_selected_description a3a3a3 # fg.fg2
set -g fish_pager_color_secondary_background --background=101010 # bg.elevated
set -g fish_pager_color_secondary_completion d4d4d4 # fg.fg1
set -g fish_pager_color_secondary_description 737373 # fg.fg3
