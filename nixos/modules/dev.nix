# the lsps serve nvim and doom
{ pkgs, ... }:
let
  # root needs the channel or rebuilds fail:
  #   sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
  unstable = import <nixos-unstable> { };
in
{
  environment.systemPackages = with pkgs; [
    gcc
    gnumake
    # npm i -g can't write to the store: npm config set prefix ~/.npm-global
    nodejs
    python3 # waybar/timer.py
    # nix shell nixpkgs#texliveFull for the rest
    texliveMedium
    proverif
    # hls is built against this ghc, keep them from the same set
    ghc
    cabal-install

    unstable.codex
    gh
    # doom's copilot.el finds it on PATH. unfree, allowed in nix.nix
    (pkgs.callPackage ../packages/copilot-isolated.nix { })

    clang-tools # clangd
    lua-language-server
    typescript-language-server
    typescript # tsserver, which the language server needs in doom
    vscode-langservers-extracted # html, css, json
    texlab
    bash-language-server # runs shellcheck as you type
    shellcheck
    nixd
    haskell-language-server

    # formatters for doom's format module
    fourmolu
    nixfmt
    ruff
    shfmt
    prettier
  ];
  # so gh auth login can leave ~/.gitconfig alone
  programs.git.config.credential."https://github.com".helper =
    "!${pkgs.gh}/bin/gh auth git-credential";

  # 127.0.0.1:11434. ollama ps shows if it landed on the gpu
  services.ollama = {
    enable = true;
    # the plain package is cpu only, vulkan drives the igpu
    package = pkgs.ollama-vulkan;
    # pulled in the background after a switch. qwen2.5-coder:7b is doom's minuet model
    loadModels = [ "qwen3:4b" "qwen2.5-coder:7b" ];
    environmentVariables = {
      OLLAMA_VULKAN = "1";
      # ollama drops integrated gpus unless told otherwise
      OLLAMA_IGPU_ENABLE = "1";
      # the igpu shares system ram
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_NUM_PARALLEL = "1";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_KEEP_ALIVE = "10m";
    };
  };
}
