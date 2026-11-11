#!/bin/sh
# 1 while a networkmanager vpn is up, which ones in the tooltip

if ! connections=$(nmcli --escape no -t -f NAME,TYPE connection show --active); then
    jq -nc '{text: "?", tooltip: "VPN connection state unavailable", class: "warning"}'
    exit 0
fi
vpns=$(printf '%s\n' "$connections" |
    sed -nE 's/:(vpn|wireguard|tun)$/ (\1)/p' |
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
if [ -n "$vpns" ]; then
    text=1 tooltip="<b>VPN connection active</b>
$vpns"
else
    text=0 tooltip="<b>No active VPN connection</b>"
fi
tooltip="$tooltip

<span alpha='60%'>Connection state only; traffic is not verified.\nclick: Proton VPN</span>"
jq -nc --arg text "$text" --arg tooltip "$tooltip" \
    '{text: $text, tooltip: $tooltip}'
