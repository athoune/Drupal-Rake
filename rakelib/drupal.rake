require 'rakelib/drupal'

@drupal ||= Drupal.new @profile['drupal']['path']

namespace :drupal do
	namespace :core do
		task :fetch do
			@fetcher.fetch "http://ftp.drupal.org/files/projects/drupal-#{@profile['drupal']['version']}.tar.gz"
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
	end
end
