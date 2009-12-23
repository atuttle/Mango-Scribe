
Thanks for downloading Scribe, the email subscriptions Mango plugin.

For more of my Mango plugins, check out my projects page:
	http://fusiongrokker.com/page/projects

*************************************************************************

This plugin needs to create a new table in your Mango Blog database, and
if your database access account (stored in the datasource or in Mango) has
sufficient privileges, it will create the necessary table and index for
you.

However, if for whatever reason the table or index is not able to be
created, a message will be displayed asking you to consult the 
documentation (this readme) to create them manually.

There are 4 potential error codes:

MSSQL1 - Error during creation of table, running in MS SQL Server
MSSQL2 - Error during creation of index, running in MS SQL Server
MSSQL3 - Error during addition of new column, running in MS SQL Server (during upgrade from 1.0)
MYSQL1 - Error during creation of table, running in MySQL

If you need to create or alter the table manually, here is its structure:

Table Name: [table prefix]emailSubscribers

Columns:
	email		- varchar(200), not null, primary key
	blogId		- varchar(50), not null, *
	ActiveFlag	- varchar(35), not null, default 'active' 
	
*Notes:
	In MSSQL, the blogId column should be a foreign key to [table prefix]blog.blogId
	In MySQL, the blogId column should be indexed (not unique)