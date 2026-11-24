# NordVPN as a normal WireGuard client. The access token was used once
# to fetch the NordLynx private key; it is not kept. The private key is
# secrets/nordvpn-private-key.age and stays when the server changes.
#
# The peer is one server from Nord's recommendation API. This one was
# chosen with no country filter: us13593.nordvpn.com, Seattle.
# Paste a new publicKey and endpoint below, then just r.
#
#   curl -fsS --get \
#     --data-urlencode "filters[servers_technologies][identifier]=wireguard_udp" \
#     --data-urlencode "limit=1" \
#     https://api.nordvpn.com/v1/servers/recommendations \
#   | jq -er '.[0] | {
#       hostname,
#       city: .locations[0].country.city.name,
#       endpoint: (.station + ":51820"),
#       publicKey: ([.technologies[] | select(.identifier=="wireguard_udp")
#         | .metadata[] | select(.name=="public_key") | .value][0])
#     }'
#
# Country ids: curl -fsS https://api.nordvpn.com/v1/servers/countries | jq -r '.[] | "\(.id) \(.name)"'
# Add --data-urlencode "filters[country_id]=81" for Germany.
#
# Full-tunnel client from the NixOS WireGuard wiki (wg-quick).
# NetworkManager is this machine's network stack, so DNS goes through
# systemd-resolved, which is what the wiki uses to make wg-quick work
# alongside NetworkManager.
{
  config,
  ...
}:

let
  publicKey = "gQbn7eZP9RuxatzY8ZrPZXUyOHl37Lo4vu9l4/p5Vy0=";
in
{
  age.identityPaths = [ "/persist/home/shrimp/.ssh/id_ed25519" ];

  age.secrets.nordvpn-private-key = {
    file = ../../secrets/nordvpn-private-key.age;
    owner = "root";
    mode = "0400";
  };

  networking.firewall.checkReversePath = "loose";

  networking.networkmanager.dns = "systemd-resolved";
  services.resolved.enable = true;

  networking.wg-quick.interfaces.wg0 = {
    address = [ "10.5.0.2/32" ];
    dns = [
      "103.86.96.100"
      "103.86.99.100"
    ];
    privateKeyFile = config.age.secrets.nordvpn-private-key.path;
    # The key is applied after the interface is up. Keepalive has to be
    # set at the same time, or the tunnel never finishes connecting.
    postUp = "wg set wg0 peer ${publicKey} persistent-keepalive 25";
    peers = [
      {
        inherit publicKey;
        endpoint = "187.15.96.100:51820";
        allowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
      }
    ];
  };

  systemd.services.wg-quick-wg0.after = [ "agenix-install-secrets.service" ];
}
