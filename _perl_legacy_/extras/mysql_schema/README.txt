Setting up MySQL for RiveScript-HTTPd
-------------------------------------

This is a quick guide to how to set up a MySQL server and import the
rs_session table schema. This guide assumes you're running on Fedora
or other RedHat-based Linux distro.

1) Install MySQL server:
	# yum install mysql-server

2) Start it up
	# service mysqld start
	# chkconfig mysqld on

3) Change your MySQL root password (recommended)
	# mysqladmin -u root password NEWPASSWORD

4) Create the database (not necessary if reusing an existing DB).
	# mysql -u root -p
	mysql> create database rs_httpd;

5) Create a MySQL user for RiveScript-HTTPd to use
	# mysql -u root -p
	mysql> grant select, insert, update, create, drop, index, alter on rs_httpd
			to 'rs_dbuser'@'localhost' identified by 'somepass';

6) Import the rs_session table:
	# mysql -u root -p rs_httpd < rs_session.sql

7) Configure the Perl/Python CGI to use MySQL as its session store, and input
	the settings for host, database name, user and password.
