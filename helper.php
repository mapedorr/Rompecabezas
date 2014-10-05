<?php
if (isset($GLOBALS["HTTP_RAW_POST_DATA"])){ 
//    $xml = xmldoc($GLOBALS["HTTP_RAW_POST_DATA"]); 
    $xml = $GLOBALS["HTTP_RAW_POST_DATA"]; 
    $file = fopen("data.xml","wb"); 
    fwrite($file, $xml); 
    fclose($file);
    echo "<success>1</success>"; 
} 
?>