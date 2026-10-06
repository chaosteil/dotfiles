-- https://www.superlogical.com/rex/docs/customize/config
-- Appearance and remote hosts live in the Rex app, not here.

-- Split keys from the Ghostty config.
rex.bind("cmd+shift+\\", "pane.split.right")
rex.bind("cmd+shift+-", "pane.split.down")

rex.bind("cmd+shift+h", "pane.focus.left")
rex.bind("cmd+shift+j", "pane.focus.down")
rex.bind("cmd+shift+k", "pane.focus.up")
rex.bind("cmd+shift+l", "pane.focus.right")

rex.bind("cmd+shift+ctrl+h", "pane.resize", { direction = "left" })
rex.bind("cmd+shift+ctrl+j", "pane.resize", { direction = "down" })
rex.bind("cmd+shift+ctrl+k", "pane.resize", { direction = "up" })
rex.bind("cmd+shift+ctrl+l", "pane.resize", { direction = "right" })

rex.bind("cmd+shift+ctrl+=", "pane.balance")
