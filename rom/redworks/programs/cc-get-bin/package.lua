local installDir = '/bin';
Package = {}
Package.__index = Package

-- Package.get gets the package from cc-get website
function Package.get( name, version )
	local url = urlBase .. 'get/' .. name
	if version then
		url = url .. '?v=' .. params.version
	end
	
	local package = json.decode( http.get(url).readAll() )
	
	if package.error ~= nil then
		return false, package.error
	else
		setmetatable(package, Package)
		return true, package
	end
end

-- Package.load looks for the program on file
function Package.load( name )
	if data.packages[name] ~= nil then
		local package = data.packages[name]
		setmetatable(package, Package)
		return true, package
	else
		return false, 'Package is not installed'
	end
end

function Package:install()
	data.installed = data.installed + 1
	
	local installPath = fs.combine(installDir, self.name .. '-lib')
	fs.makeDir(installPath)

	function create_files( items, path )
		for k, item in pairs( items ) do
			local itemPath = fs.combine( path, item.name )
			if item.type == 'file' then
				local fh = fs.open(itemPath, 'w')
				fh.write( item.script )
				fh.close()
			elseif item.type == 'folder' then
				fs.makeDir( itemPath )
				create_files( item.files, itemPath )
			end
		end
	end

	create_files( self.source, installPath )
	
	if self.onpath then
		self:link()
	end
	return true
end

function Package:uninstall()
	fs.delete( fs.combine(installDir, self.name .. '-lib') )
	self:unlink()
	data.installed = data.installed - 1
	data.packages[ self.name ] = nil
	return true
end

function Package:link()
	if self.onpath ~= '' then
		if self.onpath_filename == 0 then
			-- Use name of file that is being linked to
			name = fs.combine( installDir, self.onpath:match('[^/]-$') )
		elseif self.onpath_filename == 1 then
			-- Use name of project
			name = fs.combine(installDir, self.name)
		end
		
		local fh = fs.open( name, 'w' )
	
		fh.writeLine('local dir = shell.dir()')
		fh.writeLine("shell.setDir('/"..fs.combine(installDir, self.name .. '-lib').."')")
		fh.writeLine("shell.run('/".. fs.combine(fs.combine(installDir, self.name .. '-lib'), self.onpath) .. "', table.concat({...}, ' ') )")
		fh.writeLine("shell.setDir(dir)")
		fh.close()
	end
	return true
end

function Package:unlink()
	if self.onpath ~= '' then
		if self.onpath_filename == 0 then
			-- Use name of file that is being linked to
			name = fs.combine( installDir, self.onpath:match('[^/]-$') )
		elseif self.onpath_filename == 1 then
			-- Use name of project
			name = fs.combine(installDir, self.name)
		end
		
		fs.delete(name)
	end
	
	return true
end

function Package:update()
	local status, package = Package.get( self.name )
	if status then
		self:uninstall()
		package:install()
		data.packages[ package.name ] = package
	end
end