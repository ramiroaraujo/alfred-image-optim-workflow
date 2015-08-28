<?php
require_once "ImageOptimWorkflow.php";

$workflow = new ImageOptimWorkflow();
echo $workflow->countFiles($argv[1]);

