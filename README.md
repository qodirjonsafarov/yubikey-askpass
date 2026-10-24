# yubikey-askpass

A small, good-looking PIN and touch prompt for SSH keys stored on a YubiKey (or any FIDO2 security key) on Linux desktops.

When you use an `ed25519-sk` / `ecdsa-sk` key, OpenSSH needs your key's PIN and a touch. Out of the box it can only ask for them in a terminal, so `git push` from an editor, a GUI client or a background tool simply fails. `yubikey-askpass` plugs into OpenSSH's `SSH_ASKPASS` and shows one native window that walks you through it:

1. **Enter your security key PIN**
2. **Touch your security key** (while the key blinks)
3. **Key confirmed** ✓ (the window closes by itself)

It is a single Python file built with GTK 4 and libadwaita, so it looks at home on GNOME and works on any Wayland or X11 desktop.

## Features

- One window for the whole flow, no stack of popups.
- Warns you if the keyboard layout isn't English before sending the PIN, so a wrong layout doesn't waste one of the key's limited PIN attempts.
- Closes on its own when SSH finishes, on Cancel / Esc, or after 60 seconds of inactivity.
- Also handles plain key passphrases and SSH confirmation prompts.
- No daemon to manage, no network access, no dependencies beyond GTK.

## Requirements

- OpenSSH 8.2 or newer with FIDO2 support (`libfido2`)
- Python 3 with PyGObject, GTK 4 and libadwaita

| Distro | Command |
| --- | --- |
| Arch / Manjaro | `sudo pacman -S python-gobject gtk4 libadwaita libfido2` |
| Debian / Ubuntu | `sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-adw-1 libfido2-1` |
| Fedora | `sudo dnf install python3-gobject gtk4 libadwaita libfido2` |

## Install

```bash
git clone https://github.com/qodirjonsafarov/yubikey-askpass.git
cd yubikey-askpass
./install.sh
```

The script installs everything into your home directory:

- `~/.local/bin/yubikey-askpass`
- `~/.local/share/icons/hicolor/scalable/apps/yubikey-security-key.svg`
- `~/.config/environment.d/50-yubikey-askpass.conf`, which sets `SSH_ASKPASS` and `SSH_ASKPASS_REQUIRE=prefer` for your session

Log out and back in afterwards. To try it in the current terminal right away:

```bash
export SSH_ASKPASS=~/.local/bin/yubikey-askpass SSH_ASKPASS_REQUIRE=prefer
```

## Set up a YubiKey SSH key for GitHub

If you don't have a key on your YubiKey yet:

1. Make sure the key has a FIDO2 PIN (set one with `ykman fido access change-pin` or in Yubico Authenticator).

2. Create a resident SSH key that needs the PIN and a touch every time:

   ```bash
   ssh-keygen -t ed25519-sk -O resident -O verify-required -O application=ssh:github \
     -C "yubikey-github" -f ~/.ssh/id_ed25519_sk_github
   ```

3. Add the public key (`~/.ssh/id_ed25519_sk_github.pub`) on GitHub under **Settings → SSH and GPG keys → New SSH key**, as an *Authentication key*. Add it once more as a *Signing key* if you want signed commits.

4. Tell SSH to use it for GitHub. Add this to `~/.ssh/config`:

   ```
   Host github.com
       User git
       IdentityFile ~/.ssh/id_ed25519_sk_github
       IdentitiesOnly yes
       IdentityAgent none
   ```

   `IdentityAgent none` matters on GNOME: its built-in SSH agent picks up security keys but can't ask for the PIN, which shows up as `agent refused operation`.

5. Test it:

   ```bash
   ssh -T git@github.com
   ```

   You should see the PIN window, then the touch step, then `Hi <username>! You've successfully authenticated`.

## Troubleshooting

**`sign_and_send_pubkey: ... agent refused operation`**
An SSH agent (often GNOME's) is holding the key and can't prompt for the PIN. Add `IdentityAgent none` to the host entry in `~/.ssh/config`.

**The PIN is rejected, but it works in the terminal**
Check the keyboard layout. A PIN typed with a non-English layout reaches the key as different characters. The window refuses to send non-English characters and asks you to switch layouts.

**The window never shows up**
Make sure `SSH_ASKPASS` is set (`echo $SSH_ASKPASS`) and that you logged out and back in after installing. SSH only uses an askpass program when `DISPLAY` or `WAYLAND_DISPLAY` is set.

**Be careful with PIN attempts**
A FIDO2 key allows 8 wrong PINs in a row. After that the PIN is blocked, and the key has to be reset, which erases the credentials stored on it. You can check the remaining attempts with `fido2-token -I /dev/hidrawN` (find the device with `fido2-token -L`).

## How it works

OpenSSH runs the askpass program once per step: for the PIN, and again (with `SSH_ASKPASS_PROMPT=none`) to show a "touch your key" notice that it kills once you've touched the key. Each run is a separate process, which normally means a new window every time.

To keep a single window, the first call starts a small window process for that SSH session, and every later call talks to it over a private Unix socket in `$XDG_RUNTIME_DIR`. The window switches pages as requests come in and exits when the SSH process it belongs to is gone.

## Uninstall

```bash
./uninstall.sh
```

## License

[MIT](LICENSE)
