<?php
    
    if(isset($_REQUEST) && $_REQUEST[act]){

        include_once('libs/handler.php');

        $myApiObj = new ExandasJsonApi();
        $whiteList = array(login,logout,getLogs,insertLog);
        
        header("Content-type:application/json");
        if (in_array($_REQUEST[act], $whiteList)) {
            echo json_encode($myApiObj->manageData());
        } else {
            // check if the requests comes from a valid user
            if ($myApiObj->checkUser()) {
                echo json_encode($myApiObj->manageData());
            }else{
                echo json_encode(array(error=>'Error, User not authorized!'));
                session_unset();
                session_destroy();
                die();
            }
        }
    }else {
        header("Content-type:application/json");
        echo json_encode(array(error=>'Error, Bad request!'));
    }