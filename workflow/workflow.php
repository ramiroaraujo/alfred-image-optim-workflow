<?php
require_once "ImageOptimWorkflow.php";

$workflow = new ImageOptimWorkflow();
$feedback = new \Alfred\Workflow();

$current = $workflow->getCurrentProcess();
if (!$current) {
    $feedback->result([
        'title' => 'No optimization currently running',
        'valid' => false
    ]);
    echo $feedback->toXML();
    exit();
}

$count_images = "Optimizing {$current->total} " . ($current->total < 2 ? 'Image' : 'Images');
$eta = $current->done == 0 ? 'unknown' : round(($current->total - $current->done) * (($current->time - $current->start) / $current->done));
$feedback->result([
    'uid' => uniqid(),
    'title' => "Currently optimizing {$count_images}",
    'subtitle' => "Processed: {$current->done}, ETA: {$eta} seconds",
    'valid' => false
]);
$feedback->result([
    'uid' => uniqid(),
    'title' => 'Mute Notifications',
    'subtitle' => 'stop the progress notifications',
    'arg' => 'mute'
]);
$feedback->result([
    'uid' => uniqid(),
    'title' => 'Cancel Optimization',
    'subtitle' => "already optimized images (currently {$current->done}) will remain optimized",
    'arg' => 'cancel'
]);
echo $feedback->toXML();
