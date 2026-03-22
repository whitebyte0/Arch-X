# Auto-start Hyprland on TTY1 login
[ "$(tty)" = "/dev/tty1" ] && exec start-hyprland