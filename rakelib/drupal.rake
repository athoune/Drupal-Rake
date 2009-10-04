require 'rakelib/drupal'
require 'rakelib/db'
require 'rakelib/tools'
require 'rakelib/subversion'

@drupal ||= Drupal.new @profile['drupal']['path']
if `uname`.strip == 'Linux'
	server = 'linux'
else
	server = @profile.fetch 'server', 'mamp'
end
@db ||= Db.new server, @profile['drupal']['db']

namespace :drupal do
	namespace :core do
		
		file @profile['drupal']['path'] do
			tarball = @fetcher.fetch "http://ftp.drupal.org/files/projects/drupal-#{@profile['drupal']['version']}.tar.gz"
			sh "mkdir -p #{@profile['drupal']['path']}"
			Dir.chdir '/tmp' do
				sh "tar -xvzf #{tarball}"
				sh "mv /tmp/drupal-#{@profile['drupal']['version']}/* #{noTrailingSpace(@profile['drupal']['path'])}"
			end
			sh "rm -r /tmp/drupal-#{@profile['drupal']['version']}"
			sh "rm -r #{@profile['drupal']['path']}sites/*"
		end
		
		task :clean do
			rm_r @profile['drupal']['path']
		end
		
		task :patch => @profile['drupal']['path'] do
		end
		
		task :sites => @profile['drupal']['path'] do
			@profile['drupal']['sites'].each do |key, url|
				Subversion.get url, "#{@profile['drupal']['path']}sites/#{key}"
			end
		end
		
		desc "Install Drupal project"
		task :install => [:patch, :sites] do
		end
		
		task :upgrade do
			
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
		task :clean do
			if File.exist? 'bin/drush'
				rm_r 'bin/drush'
			end
		end
	end
	namespace :db do
		task :dump do
			@db.dump @profile.fetch('dump', 'dump')
		end
		task :upgrade do
			Subversion.update "dump/#{@profile.fetch('dump', 'dump')}.sql.bz2"
		end
	end
	task :install => ['core:install', 'drush:install']
	task :clean => ['core:clean', 'drush:clean']
end
