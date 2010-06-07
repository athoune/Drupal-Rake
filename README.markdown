Build your Drupal project with Rake
===================================

With a build tool, you can work in a Drupal project, with different environements,
like working on a Mac, and deploying it on a Linux.
All your work is managed by a versionning tool, Subversion.

Install
=======

Ruby tools needs Ubuntu >= 9.04, with an older version, you have to do handmade install

The rubygems installed in Snow Leopard is just fine.

You can now install dependencies :

	sudo gem install deep_merge
	sudo gem install aws-s3

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
	  version: 6.17
	  path:    '/Applications/MAMP/htdocs/drupal_test/'
	  db:      'mysqli://druser:drupassword@localhost:8889/drupaldb_test'

Dump
----
The name of the dump

	dump: 'dump'

Rakefile
========

Build an empty Rakefile :

	touch Rakefile

It's up to you to add mores tasks, rake, just like ruby loves monkey patching.