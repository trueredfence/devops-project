<?php
// Get MySQL connection details from environment variables
$servername = getenv('MYSQL_HOST');            // Database host
$username   = getenv('MYSQL_USER');            // Database user
$password   = getenv('MYSQL_PASSWORD');        // Database password
$dbname     = getenv('MYSQL_DATABASE');        // Database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
echo "Connected successfully";
?>
