Build your Drupal project with Rake
===================================

With a build tool, you can work in a Drupal project, with different environements, like working on a Mac, and deploying it on a Linux.
All your work is managed by a versionning tool, Subversion.

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
You can handle classical drupal (aka vanilla), pressflow or even acquia

	drupal:
	  flavor: 'vanilla'
	  version: 6.14
	  path:    '/Applications/MAMP/htdocs/drupal_test/'
	  db:      'mysqli://druser:drupassword@localhost:8889/drupaldb_test'

Dump
----
The name of the dump

	dump: 'dump'

Rakefile
========

Put all this stuff inside your project **rakelib**, and build your own Rakefile, here is an example :

	desc "Update"
	task :update => 'drupal:install'
	
	desc "The last one"
	task :lastOne => 'drupal:lastOne'
	
	desc "Big cleanup"
	task :clean => 'drupal:clean'
