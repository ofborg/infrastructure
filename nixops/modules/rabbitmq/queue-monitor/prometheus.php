<?php

$queues = json_decode(file_get_contents('http://@user@:@password@@127.0.0.1:15672/api/queues/ofborg'), true);
$connections = json_decode(file_get_contents('http://@user@:@password@@127.0.0.1:15672/api/connections'), true);

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




$versions = array_map(
    function($conn) {
        echo '# ' . $conn['user'] . $conn['client_properties']['ofborg_version'] . "\n";
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
