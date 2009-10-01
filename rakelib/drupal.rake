namespace :drupal do
	namespace :core do
		task :fetch do
			@fetcher.fetch "http://ftp.drupal.org/files/projects/drupal-#{@profile['drupal']['version']}.tar.gz"
		end
	end
end
