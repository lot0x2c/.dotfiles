# one-offs: nix shell nixpkgs#foo
{ pkgs, ... }:
{
  programs.fish.enable = true;
  # env translated at build time, not by bash on every start
  programs.fish.useBabelfish = true;
  # fish turns it on, and it rebuilds the man index on every switch
  documentation.man.cache.enable = false;
  programs.git.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  programs.firefox.enable = true;
  # also turns on 32-bit graphics. proton: add the exe as a non-steam game
  programs.steam.enable = true;
  programs.yazi.enable = true;
  programs.thunar = {
    enable = true;
    # volman mounts usb drives once ticked on in thunar-volman-settings
    plugins = with pkgs; [ thunar-archive-plugin thunar-volman ];
  };
  # thunar's own one needs exo
  environment.etc."xdg/Thunar/uca.xml".text = ''
    <actions><action>
      <name>Open Terminal Here</name>
      <icon>utilities-terminal</icon>
      <command>kitty --directory &quot;%f&quot;</command>
      <patterns>*</patterns>
      <directories/>
    </action></actions>
  '';
  # trash, drives in the side pane, mounting without sudo
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.locate.enable = true;

  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };
  users.users.toad.extraGroups = [ "wireshark" ];

  environment.systemPackages = with pkgs; [
    kitty
    # grammars are installed with emacs, not downloaded on first file open
    (emacs-pgtk.pkgs.emacsWithPackages (epkgs: [
      epkgs.pdf-tools
      (epkgs.treesit-grammars.with-grammars (grammars: with grammars; [
        tree-sitter-c
        tree-sitter-cpp
        tree-sitter-python
        tree-sitter-javascript
        tree-sitter-jsdoc
        tree-sitter-typescript
        tree-sitter-tsx
        tree-sitter-lua
      ]))
    ]))
    ripgrep
    fd
    unzip
    xarchiver
    pciutils
    usbutils
    file
    jq
    btop
    nvd
    smartmontools # smartctl -a /dev/nvme0n1
    imv
    tree
    (zathura.override { plugins = [ pkgs.zathuraPkgs.zathura_pdf_mupdf ]; }) # pdf/epub viewer, vim keys
    zip
    p7zip
    unrar
    rsync
    wget
    curl
    ncdu
    fzf
    bat
    ffmpeg
    yt-dlp
    poppler-utils # pdftotext, pdfunite
    libreoffice-fresh

    vlc
    mpv
    spotify
    qbittorrent

    signal-desktop
    whatsapp-electron
    simplex-chat-desktop
    session-desktop
    bitwarden-desktop

    proton-vpn # protonvpn-app
    tor-browser
    onionshare-gui
    mat2 # strips metadata
    age
    veracrypt
    feather

    # the rest on demand: nix shell nixpkgs#seclists
    nmap
    tcpdump
    burpsuite
    sqlmap
    ffuf
    gobuster
    hashcat
    john
    metasploit
  ];
}
