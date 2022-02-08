<div id="top"></div>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/3pi-Dev/cityzen-lights">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a>
  <h3 align="center">cityzen-lights</h3>
  <p align="center">
    Web application for the management of electric street lights inside or outside an urban area
  </p>
</div>


### Built With

* [SQL Server](https://www.microsoft.com/en-us/sql-server/sql-server-2019)
* [PHP](https://www.php.net/)
* [JavaScript](https://www.javascript.com/)
* [AngularJS](https://angularjs.org/)
* [Bootstrap](https://getbootstrap.com)
* [JQuery](https://jquery.com)
* [Leaflet](https://leafletjs.com/)
* [ChartJS](https://www.chartjs.org/)




<!-- GETTING STARTED -->
## Getting Started

This project is part of an integrated electric luminaire management system. In the code you'll find the client 
that a user can see information about the lighting devices and manage them. 
A Sql Server database dump file is also included with the schema of the database which the client links to. 
The database should be seted up for all devices to store their data in it.

### Installation

1. create a new SQL Server database & import the dump file (DB/db.sql)
2. Clone the repo in your localhost folder or your web server
   ```sh
   git clone https://github.com/3pi-Dev/cityzen-lights.git
   ```
3. Open the file api/libs/mssql.php and add all needed information ($host,$user,$password,$database,$schema) about the DB you created in step 1
4. Open a browser & navigate to your localhost or your domain
