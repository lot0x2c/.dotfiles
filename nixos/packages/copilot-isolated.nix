{ writeShellApplication, closureInfo, copilot-language-server, bubblewrap, cacert, coreutils }:
let
  runtime = closureInfo { rootPaths = [ copilot-language-server cacert ]; };
in
writeShellApplication {
  name = "copilot-isolated";
  runtimeInputs = [ bubblewrap coreutils ];
  text = ''
    # Only the server runtime and its own login state enter this filesystem.
    # No home, project, /run, host /tmp, or editor socket is exposed.
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/copilot-isolated"
    install -d -m 700 "$state"
    mounts=()
    while IFS= read -r path; do
      mounts+=(--ro-bind "$path" "$path")
    done < ${runtime}/store-paths
    exec bwrap --die-with-parent --new-session --unshare-all --share-net \
      --clearenv --proc /proc --dev /dev --tmpfs /tmp \
      "''${mounts[@]}" \
      --ro-bind /etc/resolv.conf /etc/resolv.conf \
      --ro-bind /etc/hosts /etc/hosts \
      --bind "$state" /home/copilot \
      --setenv HOME /home/copilot \
      --setenv XDG_CONFIG_HOME /home/copilot/.config \
      --setenv XDG_CACHE_HOME /home/copilot/.cache \
      --setenv SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt \
      --setenv NODE_EXTRA_CA_CERTS ${cacert}/etc/ssl/certs/ca-bundle.crt \
      --setenv PATH ${copilot-language-server}/bin \
      --chdir /home/copilot \
      ${copilot-language-server}/bin/copilot-language-server "$@"
  '';
}
