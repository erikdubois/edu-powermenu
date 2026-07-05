# Changelog

## 2026.07.05

### What Changed
- **Re-synced `powermenu.sh`'s niri and Hyprland logout with archlinux-logout** (`Functions.py`), which had
  since moved niri off `pkill niri`. Hard-killing the compositor tore it out from under its `systemd --user`
  service (`niri.service`, `Type=notify`), leaving a half-dead session — the classic "logout needs two
  presses" on Wayland niri editions. All niri paths now clean-quit via `niri msg action quit -s`, which stops
  `graphical-session.target` and takes the shell it spawned down with it.
- Added the Kiro niri session editions so each logs out cleanly from any TWM on Wayland: `kiro-niri-noctalia`/
  `kiro-niri` (noctalia), `kiro-ohmyniri` (waybar/mako/swayidle/variety stack), and `kiro-niri-dms`
  (DankMaterialShell — `dms kill` + kill its loose qs/variety siblings). Plain upstream `niri` keeps the
  runtime shell probe but clean-quits in both branches.
- Added the `kiro-hyprland-noctalia` alias to the Hyprland case (its own session, plain Hyprland underneath).

### Technical Details
- `Functions.py` remains the source of truth; these are 1:1 ports of its current `_get_logout()` niri/Hyprland
  branches, keeping the mirror comment's promise. The `_waybar_stack` companion-daemon kill order is unchanged.
- Verified with `bash -n`.

### Files Modified
- `etc/skel/.config/powermenu/powermenu.sh`

## 2026.07.02

### What Changed
- **Aligned `powermenu.sh`'s full logout and lock logic with archlinux-logout** (`Functions.py`),
  continuing the 2026.06.23 Hyprland-only sync. The old logout handled just dk/hyprland/herbstluftwm/
  chadwm/ohmychadwm and fell back to a bare `pkill $desktop` — which is actively harmful for the desktops
  archlinux-logout special-cases: `pkill plasma` black-screens the next login (kwin keeps DRM-master) and
  pkill-ing a Wayland compositor orphans waybar/mako/hypridle. The lock action ran `i3lock-fancy-dualmonitor`
  unconditionally, which can't grab a Wayland session.
- Logout now mirrors `_get_logout()` in full: Plasma via `qdbus6 ... logout`, GNOME via `gnome-session-quit`,
  xfce via `xfce4-session-logout`, Wayland compositors (sway/river/wayfire/labwc/mango/niri) kill their
  companion daemons before the compositor, niri distinguishes kiro-niri (noctalia) from kiro-ohmyniri
  (waybar stack), ohmychadwm uses its `shutdown_ohmychadwm.sh` when present, plus the full WM table.
- Lock now mirrors `resolve_lock_cmd()`: KScreenLocker (`loginctl lock-session`) on Plasma, first available
  native Wayland locker (hyprlock/gtklock) on other Wayland sessions, i3lock unchanged on X11.

### Technical Details
- Added three bash helpers modelled 1:1 on `Functions.py`, with a source-of-truth comment marking that file
  as canonical so future re-syncs (like the Hyprland one) stay in step: `detect_desktop()` (mirrors
  `_detect_desktop()` — DESKTOP_SESSION → XDG fallbacks, `:`/path stripping, lowercase, `ly` handling,
  pgrep fallback for chadwm/ohmychadwm), `get_logout_cmd()` (mirrors `_get_logout()`), and
  `resolve_lock_cmd()` (mirrors the Python of the same name).
- **Lock-swap gotcha fixed:** `Functions.py` matches its X11-locker set (`betterlockscreen`, `i3lock`) by
  exact first word, which would MISS `i3lock-fancy-dualmonitor` and leave the Wayland swap a no-op. The port
  matches the `i3lock*`/`betterlockscreen*` prefix instead, so the swap actually fires.
- The `run_cmd --logout` branch is now a two-line `cmd="$(get_logout_cmd)"; eval "$cmd"`; the Lock action is
  `eval "$(resolve_lock_cmd i3lock-fancy-dualmonitor)"`. rofi scaffolding, confirmation flow, and the
  systemctl shutdown/reboot and suspend (`mpc -q pause; amixer set Master mute`) branches are untouched.
- `bash -n` clean; echo-traced the produced command string for hyprland/ohmychadwm/plasma/niri/sway/xfce/
  gnome/dwm/unknown and for plasma-X11 / wayland / x11 lock resolution — all produce the expected string.

### Files Modified
- etc/skel/.config/powermenu/powermenu.sh

## 2026.06.23

### What Changed
- **Fixed the Hyprland logout in `powermenu.sh`** so it matches archlinux-logout's behavior. The
  `hyprland)` case did a bare `hyprctl dispatch exit`, which Hyprland 0.55+ (Lua config) rejects —
  `hyprctl dispatch <X>` is parsed as Lua `hl.dispatch(X)`, so `exit` errors out and logout does nothing.

### Technical Details
- The `hyprland)` case now mirrors archlinux-logout's `_get_logout()`: `uwsm stop` when the session is
  uwsm-managed (checked with a `systemctl --user is-active` query on the uwsm-created Hyprland wayland-wm
  unit), else `hyprctl dispatch 'hl.dsp.exit()'` on Hyprland **0.55+**, else legacy `hyprctl dispatch exit`.
- Version gate parses the first `X.Y.Z` from `hyprctl version` and compares `(major,minor) >= (0,55)`
  in awk; an unparseable/empty version falls back to the legacy command (same default as archlinux-logout).
- `bash -n` clean; version logic verified against 0.55.0 / 0.54.9 / 0.60.1 / 1.0.0 / 0.41.2 / empty.

### Files Modified
- etc/skel/.config/powermenu/powermenu.sh

## 2026.05.21

### What Changed
- Initial markdown scaffold added per the ecosystem MD-scaffold rule ([HQ/CLAUDE.md](/home/erik/Insync/Kiro/Kiro-HQ/CLAUDE.md#required-markdown-scaffold-every-repo)).
- Stubs created for `CHANGELOG.md`, `CLAUDE.md`, `IDEAS.md`, `TODO.md` (whichever were missing).
- README rewritten with real install/usage content (replaced earlier one-line stub) where applicable.

### Files Modified
- CHANGELOG.md (created)
- CLAUDE.md (created where missing)
- IDEAS.md (created where missing)
- TODO.md (created where missing)
- README.md (rewritten where it was a stub)
