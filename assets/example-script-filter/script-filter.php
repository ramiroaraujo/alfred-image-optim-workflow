<?php
require_once __DIR__ . "/vendor/autoload.php";
use Alfred\Workflow;

if ($argc < 2) exit;

$w = new Workflow();
$query = $argv[1];

//find files
$find = $w->mdfind($query);

//remove empty last one
array_pop($find);

//check results
if (count($find)) {
    //build result array
    $results = array_map(function ($file) {
        return [
            'uid' => $file,
            'arg' => $file,
            'title' => basename($file),
            'subtitle' => $file,
            'icon' => false,
            'valid' => 'yes',
            'autocomplete' => 'autocomplete'
        ];
    }, $find);
} else {
    //build not found msg
    $results = [[
        'uid' => '',
        'arg' => '',
        'title' => '404 Not Found',
        'subtitle' => '',
        'icon' => false,
        'valid' => 'yes',
        'autocomplete' => ''
    ]];
}

//set results
$w->results = $results;

//return alfred's xml
echo $w->toXML();
