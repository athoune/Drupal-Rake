require 'rakelib/fetch'

@fetch ||= Fetch::Fetcher.new @profile['fetcher']['path']

namespace :fetch do
	task :clean do
		sh "rm -r #{@fetcher.uri.path}"
	end
end