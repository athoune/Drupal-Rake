require 'rakelib/fetch'

@fetcher ||= Fetch::Fetcher.new @profile['fetcher']['path']

namespace :fetch do
	task :clean do
		if File.exist? @fetcher.uri.path
			sh "rm -r #{@fetcher.uri.path}"
		end
	end
end