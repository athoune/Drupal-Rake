require 'profile'

namespace :profile do
	desc "Show current profile"
	task :dump do
		p @profile.to_yaml
	end
end