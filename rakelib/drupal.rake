require 'rakelib/drupal'
require 'rakelib/db'

@drupal ||= Drupal.new @profile['drupal']['path']
if `uname`.strip == 'Linux'
	server = 'linux'
else
	server = @profile.fetch 'server', 'mamp'
end
@db ||= Db.new server, @profile['drupal']['db']

namespace :drupal do
	namespace :core do
		task :fetch do
			@fetcher.fetch "http://ftp.drupal.org/files/projects/drupal-#{@profile['drupal']['version']}.tar.gz"
		end
		task :patch do
		end
	end
	namespace :drush do
		file 'bin/drush' do
			drush = @fetcher.fetch "http://ftp.drupal.org/files/projects/drush-All-Versions-2.0.tar.gz"
			sh "mkdir -p bin"
			Dir.chdir 'bin' do
				sh "tar -xvzf #{drush}"
			end
		end
		desc "Install drush"
		task :install => 'bin/drush'
	end
	namespace :db do
		task :dump do
			@db.dump @profile.fetch('dump', 'dump')
		end
	end
	task :fetch => ['core:fetch', 'drush:install']
end
