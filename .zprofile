# Auto-start Hyprland on TTY1 login
if [ "$(tty)" = "/dev/tty1" ]; then
    start-hyprland 2>&1 | tee /tmp/hyprland-crash.log
    echo ""
    echo "Hyprland exited. Check /tmp/hyprland-crash.log"
    echo "Press Enter to return to login, or Ctrl+C for shell"
    read
fi