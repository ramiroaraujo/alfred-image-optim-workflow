<?php
require_once "ImageOptimWorkflow.php";

$workflow = new ImageOptimWorkflow();

$process = $argv[1];

if ($process == 'mute') {
    $current = $workflow->muteCurrent();
} else if ($process == 'cancel') {
    $current = $workflow->cancelCurrent();
}
