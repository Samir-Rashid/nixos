# Forgejo and Beszel stay on localhost. Caddy is the only public HTTP
# server and the Let's Encrypt client (HTTP-01 on port 80).
let
  domain = "infodump.org";
  forgejoHost = "git.${domain}";
  beszelHost = "status.${domain}";
in
{
  services.caddy = {
    enable = true;
    email = "Samir-Rashid@godsped.com";
    # Production Let's Encrypt. null would allow Caddy's issuer fallback.
    acmeCA = "https://acme-v02.api.letsencrypt.org/directory";
    openFirewall = true;
    virtualHosts.${forgejoHost}.extraConfig = ''
      reverse_proxy 127.0.0.1:3000
    '';
    virtualHosts.${beszelHost}.extraConfig = ''
      request_body {
        max_size 10MB
      }
      reverse_proxy 127.0.0.1:8090 {
        transport http {
          read_timeout 360s
        }
      }
    '';
  };

  services.forgejo = {
    enable = true;
    lfs.enable = true;
    settings = {
      server = {
        DOMAIN = forgejoHost;
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3000;
        ROOT_URL = "https://${forgejoHost}/";
        SSH_PORT = 22;
      };
      service.DISABLE_REGISTRATION = true;
      session.COOKIE_SECURE = true;
    };
  };

  services.beszel.hub = {
    enable = true;
    host = "127.0.0.1";
    environment.APP_URL = "https://${beszelHost}";
  };

  # The hub shows a public key and a universal token the first time you
  # add this machine. Until both files exist, the agent does not start.
  services.beszel.agent = {
    enable = true;
    smartmon.enable = true;
    environment = {
      HUB_URL = "http://127.0.0.1:8090";
      KEY_FILE = "/var/lib/beszel-agent/key";
      TOKEN_FILE = "/var/lib/beszel-agent/token";
    };
  };
  systemd.services.beszel-agent.unitConfig.ConditionPathExists = [
    "/var/lib/beszel-agent/key"
    "/var/lib/beszel-agent/token"
  ];

  networking.firewall.allowedUDPPorts = [ 51820 ];
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.1/24" ];
    listenPort = 51820;
    privateKeyFile = "/var/lib/wireguard/wg0";
    generatePrivateKeyFile = true;
    # Public key: `sudo wg show wg0 public-key` after the first boot.
    # peers = [{
    #   publicKey = "<framework16 public key>";
    #   allowedIPs = [ "10.100.0.2/32" ];
    # }];
    peers = [ ];
  };
}
