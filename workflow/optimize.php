<?php
require_once __DIR__ . "/vendor/autoload.php";

use Workflow\ImageOptimWorkflow;

$workflow = new ImageOptimWorkflow();
echo $workflow->optimize($argv[1]);
