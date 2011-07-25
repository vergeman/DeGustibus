
<?php
/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


//SETUP DB CONNECTION
@ $db = new mysqli('localhost', 'foodie', 'foodie82', 'foodie');

if (mysqli_connect_errno()) {
  echo 'Error: Could not connect to database.  Please try again later.';
  exit;
}



$GLOBALS['THRIFT_ROOT'] = 'thrift/lib/php/src';

require_once $GLOBALS['THRIFT_ROOT'].'/Thrift.php';
require_once $GLOBALS['THRIFT_ROOT'].'/protocol/TBinaryProtocol.php';
require_once $GLOBALS['THRIFT_ROOT'].'/transport/TSocket.php';
require_once $GLOBALS['THRIFT_ROOT'].'/transport/THttpClient.php';
require_once $GLOBALS['THRIFT_ROOT'].'/transport/TBufferedTransport.php';

/**
 * Suppress errors in here, which happen because we have not installed into
 * $GLOBALS['THRIFT_ROOT'].'/packages/tutorial' like we are supposed to!
 *
 * Normally we would only have to include Calculator.php which would properly
 * include the other files from their packages/ folder locations, but we
 * include everything here due to the bogus path setup.
 */
error_reporting(0);
$GEN_DIR = './gen-php';
require_once $GEN_DIR.'/cluster/cluster_types.php';
require_once $GEN_DIR.'/cluster/ClusterEngine.php';


//get data parameters from client
$S = $_POST['S'];
$L = $_POST['L'];
$C = $_POST['C'];
$num_results = $_POST['num_results'];


/*
 *connect to lunch engine and get suggestions given user "profile"
 */

//connect
try {
  if (array_search('--http', $argv)) {
    $socket = new THttpClient('localhost', 9090);
  } else {
    $socket = new TSocket('localhost', 9090);
  }
  $transport = new TBufferedTransport($socket, 1024, 1024);
  $protocol = new TBinaryProtocol($transport);
  $client = new ClusterEngineClient($protocol);

  $transport->open();

  
  //send profile, and get id list of item results
  $results = $client->getItems($L, $S, $C, $num_results);

  //given id's, look up data in mysql db
  $return_val = getData($db, $results);

  //return sql data to client
  echo json_encode($return_val);


  //close DB connection
  $db->close();

  //close thrift connection
  $transport->close();

} catch (TException $tx) {
  print 'TException: '.$tx->getMessage()."\n";
}



/*
 *GETDATA($db, $ids)
 *builds a query string to retrieve appropriate results
 *from mysql db, given a list of ids
 */
function getData($db, $ids) {

  $final;  //final datastructre to be returned

  //build item query string
  $items = "AND (";

  $i = 0;
  foreach ($ids as $id) {
    $items .= "F.item_id = $id";
    ++$i;    

    if ($i < count($ids)) {
      $items .= " OR ";
    }

  }
  $items .= ")";
  $items = trim($items);

  //general format of query (with items to be appended)
  $query = "SELECT F.item_id AS Fid, F.name AS Fname, F.description AS Fdescription, F.price AS Fprice, 
R.name AS Rname, R.cuisines AS Rcuisines , R.description AS Rdescription, R.latitude AS Rlatitude, R.longitude AS Rlongitude  
FROM food_items F, restaurants R 
WHERE F.rest_id = R.rest_id $items";

  //Query DB
  $result = $db->query($query);

  //build result set
  while ($row = $result->fetch_assoc()) {
    
    //add to results
    $final[] = $row;

  }
  //free connection
  $result->free();

  return $final;
}

?>
