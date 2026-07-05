#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Power Menu
#

# host or hostname - comes from inetutils - install it with pacman
# when missing

# locking can be done with a variety of i3lock apps and more"
# install and change to what you like

# Current Theme
dir="$HOME/.config/powermenu/"
theme='style-default'

# CMDs
uptime="`uptime -p | sed -e 's/up //g'`"
host=`cat /etc/hostname`

# Options
shutdown='Shutdown'
reboot='Reboot'
lock='Lock'
suspend='Suspend'
logout='Logout'
yes='Yes'
no='No'

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "$host" \
		-mesg "Uptime: $uptime" \
		-theme ${dir}/${theme}.rasi
}

# Confirmation CMD
confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 250px;}' \
		-theme-str 'mainbox {children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 2; lines: 1;}' \
		-theme-str 'element-text {horizontal-align: 0.5;}' \
		-theme-str 'textbox {horizontal-align: 0.5;}' \
		-dmenu \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme ${dir}/${theme}.rasi
}

# Ask for confirmation
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$logout\n$reboot\n$lock\n$suspend\n$shutdown" | rofi_cmd
}

# ── Logout / lock resolution ──────────────────────────────────────────────
# Ported from archlinux-logout's Functions.py — that file is the SOURCE OF TRUTH.
# Keep detect_desktop / get_logout_cmd / resolve_lock_cmd in step with its
# _detect_desktop() / _get_logout() / resolve_lock_cmd() when it changes.

# Mirror Functions.py::_detect_desktop().
detect_desktop() {
	local desktop="${DESKTOP_SESSION:-${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-unknown}}}"
	desktop="${desktop%%:*}"
	desktop="${desktop##*/}"
	desktop=$(echo "$desktop" | tr '[:upper:]' '[:lower:]' | xargs)

	# in case display manager ly is active
	if systemctl is-active --quiet ly; then
		local xdg
		xdg=$(env | grep XDG_CURRENT_DESKTOP || true)
		if [ -n "$xdg" ]; then
			desktop=$(echo "${xdg#*=}" | cut -d: -f1 | tr '[:upper:]' '[:lower:]')
		fi
	fi

	if [ "$desktop" = "unknown" ]; then
		if pgrep -x ohmychadwm >/dev/null 2>&1; then
			desktop="ohmychadwm"
		elif pgrep -x chadwm >/dev/null 2>&1; then
			desktop="chadwm"
		fi
	fi
	echo "$desktop"
}

# Companion daemons Wayland compositors spawn as separate top-level processes
# (not children of the compositor); kill them before the compositor so they
# don't orphan and pile up across restarts/TWM switches on the same box.
_waybar_stack="pkill waybar; pkill mako; pkill hypridle; pkill nm-applet; "

# Mirror Functions.py::_get_logout(). Prints the logout command for the session.
get_logout_cmd() {
	local desktop
	desktop=$(detect_desktop)
	echo "You are on $desktop" >&2

	case $desktop in
		herbstluftwm) echo "herbstclient quit" ;;
		bspwm) echo "pkill bspwm" ;;
		jwm) echo "pkill jwm" ;;
		openbox) echo "pkill openbox" ;;
		awesome) echo "pkill awesome" ;;
		qtile) echo "pkill qtile" ;;
		xmonad) echo "pkill xmonad" ;;
		worm) echo "pkill worm" ;;
		berry) echo "pkill berry" ;;
		dwm) echo "pkill dwm" ;;
		chadwm) echo "pkill chadwm" ;;
		ohmychadwm)
			local sd="$HOME/.config/ohmychadwm/scripts/shutdown_ohmychadwm.sh"
			if [ -f "$sd" ]; then echo "$sd"; else echo "pkill ohmychadwm"; fi
			;;
		flexi) echo "pkill flexi" ;;
		sunset) echo "pkill sunset" ;;
		i3) echo "pkill i3" ;;
		i3-with-shmlog) echo "pkill i3-with-shmlog" ;;
		lxqt) echo "pkill lxqt" ;;
		spectrwm) echo "pkill spectrwm" ;;
		xfce) echo "xfce4-session-logout -f -l" ;;
		icewm) echo "pkill icewm" ;;
		icewm-session) echo "pkill icewm-session" ;;
		cwm) echo "pkill cwm" ;;
		fvwm3) echo "pkill fvwm3" ;;
		stumpwm) echo "pkill stumpwm" ;;
		leftwm) echo "pkill leftwm" ;;
		hyprland|hypr|hyprland-uwsm|kiro-hyprland-noctalia)
			# kiro-hyprland-noctalia ships its own session but is plain Hyprland underneath
			# (noctalia-shell is a Hyprland child, taken down by the clean compositor exit).
			# uwsm -> graceful ordered shutdown; Hyprland 0.55+ runs a Lua config where
			# `hyprctl dispatch exit` is parsed as hl.dispatch(exit) and rejected, so use
			# the hl.dsp.exit() dispatcher; legacy exit otherwise. Never pkill (breaks uwsm).
			local ver
			ver=$(hyprctl version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
			if systemctl --user is-active --quiet wayland-wm@Hyprland.service; then
				echo "uwsm stop"
			elif [ -n "$ver" ] && awk -v v="$ver" 'BEGIN{split(v,a,"."); exit !(a[1]>0 || (a[1]==0 && a[2]>=55))}'; then
				echo "hyprctl dispatch 'hl.dsp.exit()'"
			else
				echo "hyprctl dispatch exit"
			fi
			;;
		dk) echo "dkcmd exit" ;;
		dusk) echo "pkill dusk" ;;
		wmderland) echo "pkill wmderland" ;;
		gnome|gnome-xorg|gnome-classic) echo "gnome-session-quit --logout --no-prompt" ;;
		nimdow) echo "pkill nimdow" ;;
		oxwm) echo "pkill oxwm" ;;
		sway) echo "${_waybar_stack}pkill sway" ;;
		river) echo "${_waybar_stack}pkill river" ;;
		wayfire) echo "${_waybar_stack}pkill wayfire" ;;
		newm) echo "pkill newm" ;;
		kiro-niri-noctalia|kiro-niri)
			# niri runs as a systemd user service (Type=notify): its own clean quit stops
			# graphical-session.target and takes the shell it spawned down with it. `pkill
			# niri` hard-kills the compositor out from under systemd, leaving a half-dead
			# session that looked like "logout needs two presses". noctalia-shell is a niri
			# child, so the clean quit takes it down too.
			echo "niri msg action quit -s"
			;;
		kiro-ohmyniri)
			# Kill the loose waybar/mako/swayidle/variety daemons first, then clean-quit.
			echo "${_waybar_stack}pkill swayidle; pkill variety; niri msg action quit -s"
			;;
		kiro-niri-dms)
			# DankMaterialShell edition: dms (the shell backend), its qs quickshell child
			# and variety are loose siblings under systemd --user, not niri children, so
			# quitting the compositor alone orphans them. `dms kill` tears the shell (and its
			# qs) down cleanly; kill variety too, then clean-quit niri.
			echo "dms kill 2>/dev/null; pkill -x dms; pkill -x variety; niri msg action quit -s"
			;;
		niri)
			# Plain upstream niri (no Kiro session entry): probe which shell is running to
			# tell the editions apart, but always clean-quit — never pkill (see above).
			if pgrep -f "qs -c noctalia-shell" >/dev/null 2>&1; then
				echo "niri msg action quit -s"
			else
				echo "${_waybar_stack}pkill swayidle; pkill variety; niri msg action quit -s"
			fi
			;;
		labwc) echo "${_waybar_stack}pkill labwc" ;;
		mango|kiro-mango)
			# kiro-mango.desktop's file id is "kiro-mango" (DesktopNames=mango;wlroots
			# sits alongside upstream mangowm's own mango.desktop), but DESKTOP_SESSION
			# is derived from the filename and takes priority in detect_desktop() above
			# -> without this alias the case falls through and nothing gets killed.
			echo "${_waybar_stack}pkill mango"
			;;
		dwl) echo "pkill dwl" ;;
		plasma|plasmawayland|plasmax11|kde|kde-plasma)
			# Plasma 6 native logout (X11 + Wayland). Stops graphical-session.target
			# cleanly so kwin_wayland releases DRM-master; a bare "pkill plasma" leaves
			# the compositor holding the GPU -> next login is a black screen.
			echo "qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout"
			;;
		unknown|"") ;;
		*) echo "pkill $desktop" ;;
	esac
}

# Mirror Functions.py::resolve_lock_cmd(). i3lock-family lockers can't grab a
# Wayland session and Plasma should use KScreenLocker, so swap accordingly.
# NOTE: this menu's default locker is i3lock-fancy-dualmonitor, which archlinux-logout's
# exact-match X11 set ("betterlockscreen","i3lock") would MISS — match the i3lock* /
# betterlockscreen* prefix here so the Wayland/Plasma swap actually fires.
resolve_lock_cmd() {
	local cmd="$1"
	local first="${cmd%% *}"
	case "$first" in
		betterlockscreen*|i3lock*) ;;
		*) echo "$cmd"; return ;;
	esac

	# Plasma (X11 or Wayland): hand off to KScreenLocker via logind.
	local cur
	cur=$(echo "${XDG_CURRENT_DESKTOP:-}" | tr '[:upper:]' '[:lower:]')
	case "$cur" in
		*kde*|*plasma*) echo "loginctl lock-session"; return ;;
	esac

	if [ "${XDG_SESSION_TYPE:-}" != "wayland" ]; then
		echo "$cmd"; return
	fi
	# Other Wayland compositors: fall back to the first available native locker.
	local locker
	for locker in hyprlock gtklock; do
		if command -v "$locker" >/dev/null 2>&1; then
			echo "$locker"; return
		fi
	done
	echo "$cmd"
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
	if [[ "$selected" == "$yes" ]]; then
		if [[ $1 == '--shutdown' ]]; then
			systemctl poweroff
		elif [[ $1 == '--reboot' ]]; then
			systemctl reboot
		elif [[ $1 == '--suspend' ]]; then
			mpc -q pause
			amixer set Master mute
			systemctl suspend
		elif [[ $1 == '--logout' ]]; then
			cmd="$(get_logout_cmd)"
			if [ -n "$cmd" ]; then
				eval "$cmd"
			fi
		fi
	else
		exit 0
	fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $shutdown)
		run_cmd --shutdown
        ;;
    $reboot)
		run_cmd --reboot
        ;;
    $lock)
		# sudo pacman -S i3lock-fancy-dualmonitors-git
		# i3lock can't grab a Wayland session; resolve_lock_cmd swaps it for the
		# right locker (hyprlock/gtklock) or KScreenLocker on Plasma.
		eval "$(resolve_lock_cmd i3lock-fancy-dualmonitor)"
        ;;
    $suspend)
		run_cmd --suspend
        ;;
    $logout)
		run_cmd --logout
        ;;
esac
