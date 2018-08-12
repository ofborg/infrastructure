{ pkgs, config, lib, ... }:
let
  cfg = config.services.ofborg.rabbitmq;
in {
  options = {
    services.ofborg.rabbitmq = {
      enable = lib.mkEnableOption {
      };

      cookie = lib.mkOption {
        type = lib.types.string;
      };

      domain = lib.mkOption {
        type = lib.types.string;
      };

      monitoring_username = lib.mkOption {
        type = lib.types.string;
      };

      monitoring_password = lib.mkOption {
        type = lib.types.string;
      };

      cluster_ips = lib.mkOption {
        type = lib.types.listOf lib.types.string;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.ofborg.acme-dns01.domains."${cfg.domain}" = {
      group = "rabbitmq";
      bundle = false;
      block = [ "rabbitmq.service" "nginx.service" ];
      postRenew = ''
        systemctl restart rabbitmq.service
        echo hi
      '';
    };

    services.phpfpm.enable_main = true;
    services.nginx = {
      enable = true;
      virtualHosts."${cfg.domain}" = (pkgs.nginxVhostPHP
        (pkgs.mutate ./queue-monitor {
          user = cfg.monitoring_username;
          password = cfg.monitoring_password;
        })) // {
          sslCertificate = "${config.services.ofborg.acme-dns01.directory}/certificates/${cfg.domain}.crt";
          sslCertificateKey = "${config.services.ofborg.acme-dns01.directory}/certificates/${cfg.domain}.key";
        };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 5671 15671 ];
    networking.firewall.extraCommands = let
      acceptPortFromPeer = peer: port:
        ''
          iptables -A nixos-fw -p tcp --source ${peer} --dport ${toString port} \
            -j nixos-fw-accept
        '';
      acceptPortFromPeers = port:
        lib.concatMapStrings
          (peer: acceptPortFromPeer peer port)
          cfg.cluster_ips;
    in lib.concatStrings [
      # Ports from https://www.rabbitmq.com/clustering.html
      (lib.concatMapStrings acceptPortFromPeers ([
          4369  # epmd
          25672 # Erlang distribution server port
          15672 # rabbitmqadmin
        ] ++ (lib.range 35672 35682) # Erlang distribution client ports
      ))
    ];


    # Use FQDNs for resolving peers
    systemd.services.rabbitmq.environment.RABBITMQ_USE_LONGNAME = "true";

    services.rabbitmq = {
      enable = true;
      cookie = lib.escapeShellArg cfg.cookie;
      plugins = [ "rabbitmq_management" "rabbitmq_web_stomp" ];
      config = let
          cert_dir = "${config.services.ofborg.acme-dns01.directory}/certificates/${cfg.domain}";
        in ''
           [
             {rabbit, [
                {tcp_listen_options, [
                        {keepalive, true}]},
                {heartbeat, 10},

                {ssl_listeners, [{"0.0.0.0", 5671}  ]},
                {ssl_options, [
                               {cacertfile,"${cert_dir}.crt"},
                               {certfile,"${cert_dir}.crt"},
                               {keyfile,"${cert_dir}.key"},
                               {verify,verify_none},
                               {fail_if_no_peer_cert,false}]},
                {log_levels, [{connection, debug},
{default, debug},
{upgrade, debug}
]}
              ]},
              {rabbitmq_management, [{listener, [{port, 15672}]}]},
              {rabbitmq_web_stomp,
                       [{ssl_config, [{port,       15671},
                        {backlog,    1024},
                        {cacertfile,"${cert_dir}.crt"},
                        {certfile,"${cert_dir}.crt"},
                        {keyfile,"${cert_dir}.key"}
                   ]}]}
           ].
         '';
     };
  };
}
