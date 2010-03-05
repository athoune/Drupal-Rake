require 'rakelib/profile'

@profile ||= Profile.profile
directory 'etc'
@etc ||= "#{`pwd`.strip}/etc"

namespace :profile do
	desc "Show current profile"
	task :dump do
		p @profile.to_yaml
	end
end
