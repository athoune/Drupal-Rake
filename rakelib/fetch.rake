namespace :fetch
	task :clean do
		sh "rm -r #{@fetcher.uri.path}"
	end
end