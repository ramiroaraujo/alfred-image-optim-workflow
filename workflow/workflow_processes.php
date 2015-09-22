<?php
require_once __DIR__ . "/vendor/autoload.php";

use Workflow\ImageOptimWorkflow;

$workflow = new ImageOptimWorkflow();

$process = $argv[1];

if ($process == 'mute') {
    $workflow->muteCurrent();
} else if ($process == 'cancel') {
    $workflow->cancelCurrent();
}
