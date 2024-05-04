<?php

require_once __DIR__ . '/vendor/autoload.php';
use PhpAmqpLib\Connection\AMQPSSLConnection;
use PhpAmqpLib\Message\AMQPMessage;

function rabbitmq_conn($timeout = 3) {
    $password = file_get_contents('@password_file@');
    $host = '@domain@';
    $connection = new AMQPSSLConnection(
        $host, 5671,
        '@username@', $password, '@vhost@',
        array(
            'verify_peer' => true,
            'verify_peer_name' => true,
            'peer_name' => $host,
            'verify_depth' => 10,
            'ca_file' => '/etc/ssl/certs/ca-certificates.crt',
        ), array(
            'connection_timeout' => $timeout,
        )
    );

    return $connection;
}

function gh_secret() {
    return file_get_contents('@github_shared_secret_file@');
}
