# Lid Stay Awake

An [Omarchy](https://omarchy.org/) shell plugin that adds a bar toggle for
keeping your laptop running while the lid is closed — useful for things like
long-running builds, downloads, or a headless SSH session you don't want to
interrupt just because you closed the lid to carry the laptop somewhere.

- **Lit up** when enabled: closing the lid will *not* suspend the machine.
- **Dimmed** when disabled: normal behavior — closing the lid suspends it.

The screen still turns off and locks when you close the lid (that's Omarchy's
normal lid-close handling, unrelated to this toggle) — the machine just keeps
running underneath, so anything you had going (downloads, builds, a remote
session) keeps making progress.

## Install

```
omarchy plugin add https://github.com/jsprada/nolid.git --enable
```

Or clone manually and enable it yourself:

```
git clone https://github.com/jsprada/nolid.git ~/.config/omarchy/plugins/lid-stay-awake
omarchy plugin enable lid-stay-awake
```

## How it works

Enabling the toggle spawns a detached

```
systemd-inhibit --what=handle-lid-switch:sleep --mode=block sleep infinity
```

process and tracks its PID in `~/.local/state/omarchy/toggles/lid-stay-awake.pid`.
That's a real logind inhibitor lock: it blocks suspend outright (`sleep`) and
also tells logind not to run its own automatic lid-close handling
(`handle-lid-switch`), so it holds regardless of which path would otherwise
trigger a suspend. Because it's a detached process (via `setsid`), it survives
Quickshell/omarchy-shell restarts. Disabling the toggle kills that process
group, which releases the lock.

The bar widget itself (`LidStayAwake.qml`) just polls `lid-stay-awake.sh --status`
and calls `lid-stay-awake.sh --toggle` on click — all state lives in that one
script, so nothing needs a background service.

## Uninstall

```
omarchy plugin remove lid-stay-awake
```
