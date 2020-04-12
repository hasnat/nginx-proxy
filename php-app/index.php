<?php
//var_dump(getallheaders());
//$headers = '';
//foreach (getallheaders() as $name => $value) {
//    if (strpos($name, 'x-b3-') === 0)
//        $headers .= "$name: $value\r\n";
//}

//stream_context_set_default(
//    array(
//        'http' => array(
//            'proxy' => "mitmproxy:8080",
//            'request_fulluri' => true,
////            'header' => $headers,
//            // Remove the 'header' option if proxy authentication is not required
//        )
//    )
//);
echo file_get_contents('http://whoami:8000/abc');
echo file_get_contents('http://whoami:8000/abc');
echo file_get_contents('http://whoami:8000/abc');
echo file_get_contents('http://whoami:8000/abc');
echo file_get_contents('http://whoami:8000/abc');
echo file_get_contents('http://php-app:80/index2.php');

echo file_get_contents('http://127.0.0.1:9411/abc');
$c=curl_init("http://whoami:8000/bbc");curl_exec($c);
$c=curl_init("http://php-app:80/index2.php");curl_exec($c);

echo 'Done';