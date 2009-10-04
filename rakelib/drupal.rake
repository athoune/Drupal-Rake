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
			if File.directory? @profile['drupal']['path']
				rm_r @profile['drupal']['path']
			end
		end
		
		task :patch => @profile['drupal']['path'] do
		end
		
		task :sites => @profile['drupal']['path'] do
			@profile['drupal']['sites'].each do |key, url|
				Subversion.get url, "#{@profile['drupal']['path']}sites/#{key}"
			end
		end
		
		task :install => [:patch, :sites, :conf]
		
		task :upgrade do
			backup = "/tmp/drupal-backup/#{Time.now.to_i}/"
			sh "mkdir -p #{backup}"
			sh "cp -r #{@profile['drupal']['path']}sites/* #{backup}"
			rm_r @profile['drupal']['path']
			Rake::Task["drupal:core:patch"].invoke
			sh "mv #{backup}* #{@profile['drupal']['path']}sites/"
			sh "rm -r #{backup}"
		end
		
		task :conf => @profile['drupal']['path'] do
			sh "mkdir -p #{@profile['drupal']['path']}sites/default"
			generate "template/settings.php.rhtml", "#{@profile['drupal']['path']}sites/default/settings.php"
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
		
		task :install => 'bin/drush'
		task :clean do
			if File.exist? 'bin/drush'
				rm_r 'bin/drush'
			end
		end
	end
	
	namespace :db do
		dump = @profile.fetch('dump', 'dump')
		task :dump do
			@db.dump dump
		end
		
		task :upgrade do
			Subversion.update "dump/#{dump}.sql.bz2"
		end
		
		task :install do
		end
	end
	
	desc "Build Drupal's settings"
	task :conf => 'core:conf'

	desc "Install Drupal"
	task :install => ['core:install', 'drush:install']

	desc "Cleanup"
	task :clean => ['core:clean', 'drush:clean']
end
