<?php
$scriptLoc = "/opt/scripts/4c-dl.sh";

$isPOST = true;
if(isset($_GET['url']) || isset($_GET['user']) || isset($_GET['pw'])) {
    $isPOST = false;
}

$url = $isPOST ? $_POST['url'] : $_GET['url'];
$user = $isPOST ? $_POST['user'] : $_GET['user'];
$pw = $isPOST ? $_POST['pw'] : $_GET['pw'];

if(isset($url) && isset($user) && isset($pw)) {
    $url = urldecode($url);
    $user = urldecode($user);
    $pw = urldecode($pw);

    $output = array();
    $exitCode = 0;
    $cmd = "echo '$pw' | su - $user -c \"$scriptLoc '$url'\" > /dev/null 2>&1 &";

    exec($cmd, $output, $exitCode);

    if($exitCode > 0) {
        http_response_code(500);
        print("Error<br /><br /><a href='#' onclick='window.close()'>Close</a>");
    } else {
        http_response_code(200);
        print("OK<br /><br /><a href='#' onclick='window.close()'>Close</a>");
    }
} else {
    print("Malformed request<br /><br /><a href='#' onclick='window.close()'>Close</a>");
}
