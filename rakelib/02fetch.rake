require 'rakelib/fetch'

@fetcher ||= Fetch::Fetcher.new((@profile.key? 'fetcher') ? @profile['fetcher']['path'] : 'file:///tmp/fetcher/')

namespace :fetch do
	desc "Cleanup download cache"
	task :clean do
		if File.exist? @fetcher.uri.path
			sh "rm -r #{@fetcher.uri.path}"
		end
	end
end