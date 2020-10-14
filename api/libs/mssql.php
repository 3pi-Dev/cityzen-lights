<?php

	use \PDO;

	class mssqlDb extends \PDO {

		private
			$host = '',
			$user = '',
			$password = '',
			$database = '',
			$schema = '';

		protected
			$result,
			$q,
			$stmt,
			$params=array(),
			$dbLink = NULL,
			$records=array();

		public function __construct(){

			try{
				if($this->dbLink == NULL )
				$this->dbLink = new PDO ('dblib:host='.$this->host.';dbname='.$this->database.';charset=UTF-8;',$this->user,$this->password);
			}catch (PDOException $e){
				echo 'error: '.$e->getMessage( ).' - '.$e->getCode( );
			}
		}

		public function execProc($call,$params=NULL){

			$cl='';

			if(is_array($params)){
				foreach($params as $param) $param[0]=='varchar'?$cl .= ' "'.$param[1].'",':$cl .= ' '.$param[1].',';
			}

			$cl = substr($cl,0,strlen($cl)-1);

			try{
				$this->stmt= $this->dbLink->prepare('EXEC '.$this->schema.'.'.$call.' '.$cl);
				$this->stmt->execute();
			}catch(Exception $e){
				echo $e->getMessage();
			}
		}

		public function getData(){

			try{
				return  $this->records=$this->stmt->fetch(PDO::FETCH_ASSOC);
			}  catch (Exception $e){
				echo $e->getMessage();
			}
		}

		public function numRows($query=''){	

			if(isset($this->stmt))return $this->stmt->rowCount();
			else return 0;
		}

		public function custom_query($sql){

			$this->lastCall='query';
			$this->stmt=$this->dbLink->query($sql);
		}
	}
?>