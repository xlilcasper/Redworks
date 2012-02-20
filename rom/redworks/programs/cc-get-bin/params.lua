--[[
Params version 1.0.0

Examples:
	If you were to run:
	cc-get install program -v 1.2 -f
	
	With this in the cc-get program:
	opts = parse_params({...}, {version = '-v *([^ ]+)', flag = '-f'})
	
	Opts would be:
	opts = {
		'install',
		'program',
		flag = true,
		version = '1.2'
	}
]]--
function parse_params(params, patterns)
	params = table.concat(params, ' ')
	local result = {}
	local left = params

	for k, pattern in pairs(patterns) do
		for x in string.gmatch(params, pattern) do
			if x == pattern then
				result[ k ] = true
			else
				result[ k ] = x
			end
			left = left:gsub(pattern, '')
		end
	end
	
	-- Remove extra spaces
	left = left:gsub('%s+', ' ')
	
	-- Trim before and after
	left = left:gsub('^%s*(.+)%s*$', '%1')
	
	for param in left:gmatch('[^ ]+') do
		table.insert( result, param )
	end
	
	return result
end