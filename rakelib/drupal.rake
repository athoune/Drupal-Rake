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
				sh "mv /tmp/drupal-#{@profile['drupal']['version']}/.htaccess #{noTrailingSpace(@profile['drupal']['path'])}"
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
			#[TODO] iterate over patch/*.patch and do it
		end
		
		task :sites => @profile['drupal']['path'] do
			sh "mkdir -p devel"
			@profile['drupal']['sites'].each do |key, url|
				Subversion.get url, "#{@profile['drupal']['path']}sites/#{key}"
				if not File.exist? "devel/#{key}"
					sh "ln -s #{@profile['drupal']['path']}sites/#{key} devel/#{key}"
				end
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
			@drupal.drush 'updatedb'
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
			sh "chmod +x bin/drush/drush"
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
		desc "Make a db snapshot"
		task :dump do
			@drupal.drush 'cache clear'
			@db.dump dump
		end
		
		task :_upgrade do
			Subversion.update "dump/#{dump}.sql.bz2"
		end
		
		desc "Load the last versionned snapshot"
		task :upgrade => [:_upgrade, :load]
		
		desc "Load the last local snapshot"
		task :load do
			@db.load dump
			@drupal.drush '-y updatedb'
		end
	end
	
	desc "Launch cron task"
	task :cron do
		@drupal.cron
	end

	desc "Clear cache"
	task :clear do
		@drupal.clear_cache
	end	
	
	desc "Build Drupal's settings"
	task :conf => 'core:conf'

	desc "Install Drupal"
	task :install => ['core:install', 'drush:install']
	
	desc "Get the newest Drupal with the newest snapshot"
	task :lastOne => [:clean, :install, 'db:upgrade']

	desc "Cleanup"
	task :clean => ['core:clean', 'drush:clean']
	
	desc "Upgrade drupal core without breaking customize"
	task :upgrade => 'core:upgrade'
end
