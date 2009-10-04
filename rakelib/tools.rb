def noTrailingSpace(path)
	if path[-1] == 47
		path[0, (path.length-1)]
	else
		path
	end
end