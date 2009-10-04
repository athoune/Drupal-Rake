Build your Drupal project with Rake
===================================

Profile
=======
All configurations are done in a YAML file.
You can put your own data, but there is some standard data

Server
------
You have to use php + httpd + mysql server.

	server: 'mamp'

Fetcher
-------
The fetcher is a tool wich download and cache distant data. For now, the fetcher works in local, but soon, scp and S3 will be handled.

	fetcher:
	  path:    'file:///tmp/fetcher/'

Drupal
------

	drupal:
	  version: 6.14
	  path:    '/Applications/MAMP/htdocs/drupal_test/'
	  db:      'mysqli://druser:drupassword@localhost:8889/drupaldb_test'

Dump
----
The name of the dump

	dump: 'dump'
