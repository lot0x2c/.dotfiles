# personal checklist

## rebuilding

/etc/nixos is main, the system runs on it. this repo's nixos/ is experimental.

```sh
# main
sudo nixos-rebuild switch

# try the repo now, gone after a reboot
sudo nixos-rebuild test -I nixos-config=/home/toad/.config/.dotfiles/nixos/configuration.nix

# boot-time changes like hibernate need a boot entry. the last build becomes
# the default entry, so make main the default again after testing
sudo nixos-rebuild boot -p experimental -I nixos-config=/home/toad/.config/.dotfiles/nixos/configuration.nix
sudo nixos-rebuild boot

# promote the repo to main. the /. copies the contents, not the folder
sudo cp -r ~/.config/.dotfiles/nixos/. /etc/nixos/ && sudo nixos-rebuild switch
```

## git
- [x] first import, oct 21
- [x] fish abbreviations
- [x] commit everything since, one commit per area
- [x] add a github remote
- [x] push reviewed commits
- [x] keep mpv out of the repo
- [x] take readme.md, notes.md and nixos/readme.org out of the index
- [ ] change the author email on the first two commits

## nixos
- [x] zram first, the old disk swap dropped
- [x] no sleep or blanking (hardware fault)
- [x] dns over tls, tor, kernel hardening
- [x] gpu video decode, blueman, fwupd
- [x] thunar with archives, usb mounting and trash
- [x] yazi
- [x] gh for github logins
- [x] /etc/nixos is main, the repo is experimental (commands above)
- [x] shellcheck, bash-language-server, nixd
- [x] doom's packages in main: copilot server, grammars, minuet model
- [ ] codex from stable, then drop the unstable channel
- [ ] hibernate at 5% on the old 16G swap (nvme1n1p3): in the repo, needs a boot -p experimental test
- [ ] undo the no-sleep bits in power.nix once resume works

## sway
- [x] screens stay on with the lid shut
- [x] lock after 10 idle minutes, nothing else
- [x] vlc fullscreen holds off the lock
- [x] rofi on mod+d, mod+t and mod+shift+d
- [x] shift+print for the whole screen
- [x] only firefox goes to web
- [x] two org terminals beside emacs on 2:org
- [ ] check vlc really doesn't lock mid-movie
- [x] log out and back in so swayidle starts
- [ ] any fullscreen app holding off the lock, like the first commit had?

## waybar
- [x] timer with pause, scroll and a rofi menu
- [x] timer skips python when nothing runs
- [x] tooltips with details and click hints
- [x] charge limit toggle, 80 or 100
- [x] media title with artist and album
- [x] idle toggle tooltips match the lock
- [x] each waybar group shares one pair of brackets
- [x] brightness module, scroll to change
- [ ] vpn tooltip only means a connection is up, not that the tunnel works

## rofi
- [x] calc and emoji plugins
- [x] power, kill and timer scripts
- [x] mod+d apps, mod+t timer, mod+shift+d tools
- [x] theme folded into config.rasi
- [x] keywords script gone
- [x] use the calc, emoji and kill tabs directly

## nvim
- [x] make it minimal
  - [x] switch to oil
  - [x] remove telescope and harpoon
  - [x] remove cmp, use native lsp
- [x] start page
- [x] space l f formats, =ap left alone
- [x] bash and nix lsps
- [ ] python lsp if there's more python than timer.py

## doom
- [x] loads from ~/.config/doom
- [x] sh and nix lsps
- [x] doom sync
- [x] trim the comments in lisp/
- [x] pyret mode for .arr files
- [x] org insert-link, links take the surrounding colour

## audio
- [x] jack-profile picks the speaker when nothing's plugged in
- [x] bose plays over a2dp, never as a headset
- [x] limit jack-profile to this laptop's built-in sound card

## fish
- [x] vi keys, block cursor
- [x] bubblegum prompt with git and vi mode
- [x] y for yazi
- [x] document the explicit rebuild command
- [ ] add aliases
- [ ] bring back the g++ and latexmk abbrs from the first commit

## kitty, dunst, copyq, mpv
- [x] bubblegum everywhere
- [x] mpv decodes on the gpu (config is local only, gitignored)
