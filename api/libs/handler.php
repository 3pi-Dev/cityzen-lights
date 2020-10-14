<?php

    session_start();
    set_time_limit(0);
    ignore_user_abort();
    include_once('mssql.php');

    date_default_timezone_set('Europe/Athens');

    class ExandasJsonApi{ // JSON data creator class
        
        private $msDB,
                $md,
                $dataArray,
                $type,
                $ProjectID,
                $lang;

        function __construct(){

            // Check for requests here and return error message if too many (temp or long term).
            $this->md = (isset($_REQUEST['act']))?$_REQUEST['act'].'Api':'nada';
            $this->msDB = new mssqlDb();
            $this->type = (isset($_REQUEST['type']))?$_REQUEST['type']:'nada';
            $this->action = $_REQUEST;
            $this->user = (isset($_SESSION[user])?$_SESSION[user]:null);
            $this->lastCall = $_SESSION[LastCall];
        }

        function __destruct() { // destructor smash!

            unset($this); // destroy current instance.
        }

        // Auth
            public function checkUser(){

                return ($this->user)?true:false;
            }

            private function checkLogin($torun){
            
                if($this->ProjectID < 1){
                    $this->dataArray=array('login'=>'failed');
                }else{
                    $this->dataArray=$this->$torun();
                }
                return $this->dataArray;
            }
            
            private function checkLoginApi(){
                
                if($this->ProjectID < 1){
                    $this->dataArray=array('login'=>'failed');
                }else{
                    $this->dataArray=array('usr'=>$this->ProjName);
                }
                return $this->dataArray;
            }
            
            private function loginApi(){
                
                $params = array();
                $params['username'] = array('varchar',mysql_escape_string($this->action['username']));
                $params['password'] = array('varchar',mysql_escape_string($this->action['password']));

                $this->msDB->execProc('web_checkUser',$params);
                $result = $this->msDB->getData();
                
                if ($result['id']) {
                    $this->user = $result[id];
                    $_SESSION[user] = $this->user;
                    return array('login'=>true,'id'=>$result['id'],'user'=>$result['name'],'type'=>$result['type']);
                }else{
                    $this->user = null;
                    $_SESSION[user] = null;
                    return array('login'=>false);
                }
            }

            private function logoutApi(){

                session_destroy();
                return array('login'=>'reset');
            }
        // ----------


        // Initial & Live Data
            public function manageData(){

                $torun = $this->md;
                if($torun != 'nada' && method_exists(ExandasJsonApi,$torun)){
                    $this->dataArray=$this->$torun();
                }else{
                    $this->dataArray=array('error'=>'nothing requested');
                }
                return $this->dataArray;
            }

            private function initDataApi(){
                
                $data = array();
                $params = array();
                $this->msDB->execProc('web_getPillarsList');
                while($row=$this->msDB->getData()){
                    $data[$row['PIL_ID']] = $row;
                }
                
                foreach($data as $key=>$value){
                    
                    $data[$key]['poles'] = array();
                    $params['pil_id'] = array('int',(int)$key);
                    $this->msDB->execProc('web_getPolesForPilar',$params);
                    while($row=$this->msDB->getData()){
                        $data[$key]['poles'][$row['POL_ID']] = $row;
                    }
                }
                
                return $data;
            }

            private function getPillarAndLightTypesApi(){
                
                $data = array();
                $data['lightTypes'] = array();
                $data['poleTypes'] = array();
                $this->msDB->execProc('usp_getLightTypes');
                while($row=$this->msDB->getData()){
                    $data['lightTypes'][] = $row;
                }
                $this->msDB->execProc('usp_getPoleTypes');
                while($row=$this->msDB->getData()){
                    $data['poleTypes'][] = $row;
                }
                
                return $data;
            }

            private function getCurrentStateApi(){
                
                $data = array();
                $this->msDB->execProc('web_getCurrentState');
                while($row=$this->msDB->getData()){$data[] = $row;}
                return $data;
            }

            private function changeStateApi(){
                
                $params = array();
                $params['pil_id'] = array('int',(int)$this->action['pil_id']);
                $params['dateActive'] = array('varchar',$this->action['dateActive']);
                $params['stateType'] = array('int',(int)$this->action['stateType']);
                $params['status'] = array('int',(int)$this->action['status']);
                $this->msDB->execProc('web_triggerPIllarEvent',$params);
                $row=$this->msDB->getData();
                
                return $row;
            }
        // ----------


        // Users
            private function getUsersApi(){
                
                $data = array();
                $this->msDB->execProc('web_getUsers');
                while($row=$this->msDB->getData()){
                    $data[] = $row;
                }
                
                return $data;
            }
            
            private function insertUserApi(){
                
                $params = array();
                $params['username'] = array('varchar',$this->action['username']);
                $params['password'] = array('varchar',$this->action['password']);
                $params['type'] = array('int',(int)$this->action['type']);
                $params['email'] = array('varchar',$this->action['email']);
                $params['phone'] = array('varchar',$this->action['phone']);
                $params['name'] = array('varchar',$this->action['name']);
                
                $this->msDB->execProc('web_insertUser',$params);
                return $this->msDB->getData();
            }

            private function updateUserApi(){
                
                $params = array();
                $params['id'] = array('int',(int)$this->action['id']);
                $params['username'] = array('varchar',$this->action['username']);
                $params['password'] = array('varchar',$this->action['password']);
                $params['type'] = array('int',(int)$this->action['type']);
                $params['email'] = array('varchar',$this->action['email']);
                $params['phone'] = array('varchar',$this->action['phone']);
                $params['name'] = array('varchar',$this->action['name']);

                $this->msDB->execProc('web_updateUser',$params);
                return $this->msDB->getData();
            }

            private function deleteUserApi(){
                
                $params = array();
                $params['id'] = array('int',(int)$this->action['id']);

                $this->msDB->execProc('web_deleteUser',$params);
                return $this->msDB->getData();
            }
        // ----------


        // Pillars
            private function getPillarHistoryApi(){
                
                $data = array();
                $params = array();
                $params['pil_id'] = array('int',$this->action['pillarID']);
                $params['dateFrom'] = array('varchar',$this->action['dateFrom']);
                $params['dateTo'] = array('varchar',$this->action['dateTo']);
                $this->msDB->execProc('web_getPillarHistory',$params);
                while($row=$this->msDB->getData()){
                    $data[] = $row;
                }
                
                return $data;
            }

            private function getPillarEventsApi(){
                
                $data = array();
                $data['values'] = array();
                $params = array();
                $params['pil_id'] = array('int',(int)$this->action['pil_id']);
                $params['dateFrom'] = array('varchar',$this->action['dateFrom']);
                $params['dateTo'] = array('varchar',$this->action['dateTo']);
                
                $this->msDB->execProc('usp_getPillarEvents',$params);
                while($row=$this->msDB->getData()){
                    $data['values'][] = $row;
                }
                
                return $data;
            }
        // ----------


        // Poles & Lights
            private function updatePoleAndLightsApi(){
                
                $data = array('done'=>'true');
                $params = array();
                $params['pole_id'] = array('int',(int)$this->action['pol_id']);
                $params['pole_type'] = array('int',(int)$this->action['pole_type']);
                $params['pole_height'] = array('int',(int)$this->action['pole_height']);
                $params['lat'] = array('varchar',$this->action['lat']);
                $params['lng'] = array('varchar',$this->action['lng']);
                $this->msDB->execProc('usp_updatePole',$params);
                
                $lights = explode('|', $this->action['lights']);
                foreach($lights as $key=>$value){
                    $lightsparts = explode(',',$value);
                    $params = array();
                    $params['light_id'] = array('int',(int)$lightsparts[0]);
                    $params['light_watt'] = array('int',(int)$lightsparts[1]);
                    $params['light_type'] = array('int',(int)$lightsparts[2]);
                    
                    $this->msDB->execProc('usp_updateLight',$params);
                }
                
                return $data;
            }

            private function updateMultiplePolesApi(){

                $poles = explode('|', $this->action['poles']);
                foreach ($poles as $key => $value) {
                    $poleParts = explode(',', $value);
                    $params = array();
                    $params['id'] = array('int',(int)$poleParts[0]);
                    $params['lat'] = array('varchar',$poleParts[1]);
                    $params['lng'] = array('varchar',$poleParts[2]);
                    $this->msDB->execProc('web_updatePolePosition',$params);
                }

                return true;
            }
            
            private function getLatestPollImageApi(){

                $params = array();
                $params['pole_id'] = array('int',(int)$this->action['pol_id']);
                $this->msDB->execProc('usp_getLatestPoleImage',$params);
                $row=$this->msDB->getData();

                $data = array();
                $data['image'] = $row['POLI_IMAGE'];
                $data['date'] = $row['POLI_DATE'];
                $data['description'] = $row['POLI_DESCR'];
                
                return $data;
            }
            
            private function getImageApi(){

                $params = array();
                $params['pole_id'] = array('int',(int)$this->action['pol_id']);
                $this->msDB->execProc('usp_getLatestPoleImage',$params);
                $row=$this->msDB->getData();
                
                header('Content-Type: image/png');
                echo base64_decode($row['POLI_IMAGE']);
                die();
            }
        // ----------


        // Alerts
            private function insertAlertApi(){
                
                $params = array();
                $params['pil_id'] = array('int',(int)$this->action['pillarID']);
                $params['enabled'] = array('int',(int)$this->action['enabled']);
                $params['datefrom'] = array('varchar',$this->action['datefrom']);
                $params['dateto'] = array('varchar',$this->action['dateto']);
                $params['timefrom'] = array('varchar',$this->action['timefrom']);
                $params['timeto'] = array('varchar',$this->action['timeto']);
                $params['condition'] = array('int',(int)$this->action['condition']);
                $params['pvalue'] = array('int',(int)$this->action['pvalue']);
                $params['sms'] = array('varchar',$this->action['sms']);
                $params['email'] = array('varchar',$this->action['email']);
                $this->msDB->execProc('usp_insertAlert',$params);

                return $this->msDB->getData();
            }

            private function updateAlertApi(){
                
                $params = array();
                $params['pila_id'] = array('int',(int)$this->action['alertID']);
                $params['enabled'] = array('int',(int)$this->action['enabled']);
                $params['datefrom'] = array('varchar',$this->action['datefrom']);
                $params['dateto'] = array('varchar',$this->action['dateto']);
                $params['timefrom'] = array('varchar',$this->action['timefrom']);
                $params['timeto'] = array('varchar',$this->action['timeto']);
                $params['condition'] = array('int',(int)$this->action['condition']);
                $params['pvalue'] = array('int',(int)$this->action['pvalue']);
                $params['sms'] = array('varchar',$this->action['sms']);
                $params['email'] = array('varchar',$this->action['email']);
                $this->msDB->execProc('usp_updateAlert',$params);
                return $this->msDB->getData();
            }

            private function deleteAlertApi(){
                
                $params = array();
                $params['pila_id'] = array('int',(int)$this->action['alertID']);
                $this->msDB->execProc('usp_deleteAlert',$params);
                $return $this->msDB->getData();
            }

            private function getAlertsApi(){
                
                $data = array();
                $params = array();
                $params['pil_id'] = array('int',(int)$this->action['pillarID']);
                $this->msDB->execProc('usp_getAlertsForPillar',$params);
                while($row=$this->msDB->getData()){
                    $data[$row['PILA_ID']] = $row;
                }
                return $data;
            }
        // ----------


        // Reports
            private function getApoleiaApi(){
                
                $params = array();
                $params['pillarID'] = array('int',(int)$this->action['pillarID']);
                $this->msDB->execProc('usp_ektimisiVlavis',$params);
                return $this->msDB->getData();
            }

            private function getDailyUsageApi(){
                
                $data = array();
                $data['values'] = array();
                $params = array();
                $params['pil_id'] = array('int',(int)$this->action['pil_id']);
                $params['dateIn'] = array('varchar',$this->action['date']);
                
                $this->msDB->execProc('usp_reportByHour',$params);
                while($row=$this->msDB->getData()){
                    $data['values'][] = $row;
                }

                $this->msDB->execProc('usp_getDailyTotalUsage',$params);
                $row=$this->msDB->getData();
                $data['total'] = $row['total'];
                
                return $data;
            }

            private function getDailyPowerApi(){
                
                $data = array();
                $data['values'] = array();
                $params = array();
                $params['pil_id'] = array('int',(int)$this->action['pil_id']);
                $params['dateFrom'] = array('varchar',$this->action['dateFrom']);
                $params['dateTo'] = array('varchar',$this->action['dateTo']);
                
                $this->msDB->execProc('usp_dailyPowerUsage',$params);
                while($row=$this->msDB->getData()){
                    $data['values'][$row['date']] = $row['average'];
                }

                return $data;
            }
            
            private function getWeeklyUsageApi(){
                
                $data = array();
                $data['values'] = array();
                $params = array();
                $params['pil_id'] = array('int',(int)$this->action['pil_id']);
                $params['dateFrom'] = array('varchar',$this->action['dateFrom']);
                $params['dateTo'] = array('varchar',$this->action['dateTo']);
                
                $this->msDB->execProc('usp_reportByDay',$params);
                while($row=$this->msDB->getData()){
                    if(!$data['values'][$row['TimeSep']]) $data['values'][$row['TimeSep']] = array();
                    $data['values'][$row['TimeSep']][] = $row;

                }

                $this->msDB->execProc('usp_getTotalUsage',$params);
                $row=$this->msDB->getData();
                $data['total'] = $row['total'];
                
                return $data;
            }
             
            private function getMonthlyUsageApi(){
                
                $data = array();
                $data['values'] = array();
                $params = array();
                $params['pil_id'] = array('int',(int)$this->action['pil_id']);
                $params['dateFrom'] = array('varchar',$this->action['dateFrom']);
                $params['dateTo'] = array('varchar',$this->action['dateTo']);
                
                $this->msDB->execProc('usp_reportByMonth',$params);
                while($row=$this->msDB->getData()){
                    if(!$data['values'][$row['TimeSep']]) $data['values'][$row['TimeSep']] = array();
                    $data['values'][$row['TimeSep']][] = $row;

                }

                $this->msDB->execProc('usp_getTotalUsage',$params);
                $row=$this->msDB->getData();
                $data['total'] = $row['total'];
                
                return $data;
            }
        // ----------


        // Logs
            private function getLogsApi(){
                
                $data = array();
                $params = array();
                $params['user'] = array('int',(int)$this->action['user']);
                $this->msDB->execProc('web_getLogs',$params);
                while($row=$this->msDB->getData()){$data[] = $row;}
                return $data;
            }
            
            private function insertLogApi(){
                
                $params = array();
                $params['user'] = array('int',(int)$this->action['user']);
                $params['description'] = array('varchar',$this->action['description']);
                $this->msDB->execProc('web_insertLog',$params);
            }
        // ----------
    }
?>