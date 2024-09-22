<?php

$password = file_get_contents('@password_file@');
$queues = json_decode(file_get_contents('https://@user@:' . $password . '@@domain@/api/queues/ofborg'), true);
$connections = json_decode(file_get_contents('https://@user@:' . $password . '@@domain@/api/connections'), true);

$stats = array_map(
    function($queue) {
        $total_msgs = $queue['messages'];
        $todo = $queue['messages_ready'];

        return [
            'name' => $queue['name'],
            'consumers' => $queue['consumers'],
            'messages' => [
                'waiting' => $todo,
                'in_progress' => $total_msgs - $todo,
            ],
        ];
    },
    $queues
);

$filtered_stats = array_filter($stats,
                       function($queue) {
                           return (strpos($queue['name'], 'build-inputs-') === 0)
                               || ($queue['name'] === 'mass-rebuild-check-jobs');
                       }
);


$stats = array_reduce(
    $filtered_stats,
    function($collector, $arch) {
        $name = $arch['name'];
        unset($arch['name']);

        if ($name === 'mass-rebuild-check-jobs') {
            $collector['evaluator'] = $arch;
        } elseif (strpos($name, 'build-inputs-') === 0) {
            if (!isset($collector['build-queues'])) {
                $collector['build-queues'] = [];
            }

            $collector['build-queues'][$name] = $arch;
        }

        return $collector;
    },
    []
);

echo "ofborg_queue_evaluator_consumers " . $stats['evaluator']['consumers'] . "\n";
echo "ofborg_queue_evaluator_waiting " . $stats['evaluator']['messages']['waiting'] . "\n";
echo "ofborg_queue_evaluator_in_progress " . $stats['evaluator']['messages']['in_progress'] . "\n";

foreach ($stats['build-queues'] as $archstr => $stats) {
    $arch = str_replace("build-inputs-", "", $archstr);

    echo 'ofborg_queue_builder_consumers{arch="' . $arch .'"} '. $stats['consumers'] . "\n";
    echo 'ofborg_queue_builder_waiting{arch="' . $arch .'"} '. $stats['messages']['waiting'] . "\n";
    echo 'ofborg_queue_builder_in_progress{arch="' . $arch .'"} '. $stats['messages']['in_progress'] . "\n";
}

$versions_by_user = array_reduce(
    $connections,
    function($collector, $conn) {
        $user = $conn['user'];
    $version = $conn['client_properties']['ofborg_version'];

        if (!isset($collector[$user])) {
            $collector[$user] = array();
    }
        if (!isset($collector[$user][$version])) {
            $collector[$user][$version] = 0;
    }

    $collector[$user][$version]++;

    return $collector;
    },
    []
);

$versions = array_map(
    function($conn) {
        return $conn['client_properties']['ofborg_version'];
    },
    $connections
);

$filtered_versions = array_filter($versions,
                                  function ($v) { return !is_null($v); }
);

sort($filtered_versions);
$counted_versions = array_reduce($filtered_versions,
             function($c, $v) {
                 if (!isset($c[$v])) {
                     $c[$v] = 0;
                 }
                 $c[$v]++;

                 return $c;
             },
             []
);

foreach ($counted_versions as $version => $count) {
    echo 'ofborg_version{version="'.$version.'"} ' . $count . "\n";
}

echo "# HELP ofborg_per_user_version Number of connections by user and version.\n";
echo "# TYPE ofborg_per_user_version gauge\n";
foreach ($versions_by_user as $user => $details) {
    foreach ($details as $version => $count) {
        echo 'ofborg_per_user_version{user="'.$user.'",version="'.$version.'"} ' . $count . "\n";
    }
}
