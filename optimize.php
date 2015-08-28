<?php
require_once "ImageOptimWorkflow.php";

$workflow = new ImageOptimWorkflow();
echo $workflow->optimize($argv[1]);
