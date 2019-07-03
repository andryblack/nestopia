
local version = '1.50-WIP'

local pkgconfig = function(module,var)
	local res,status = os.outputof("pkg-config " .. module .. " --" .. var)
	assert(status==0,"not found package " .. module .. " var " .. var)
	return res
end

solution 'Nestopia'
	configurations { 'debug', 'release' }
	language 'c++'

	objdir '../build' 
	location '../build'
	--cppdialect "C++11"

	
	configuration{ 'debug'}
		symbols "On"
	configuration{ 'release'}
		optimize "On"
	configuration{}

	project 'Nestopia'
		kind 'WindowedApp'

		local sources = require 'sources'

		includedirs{
			'../source',
			'../source/common',
		}
		defines('VERSION="' .. version..'"')
		defines 'NST_PRAGMA_ONCE'

		buildoptions{ 
			pkgconfig('libarchive','cflags'),
			pkgconfig('epoxy','cflags'),
		}
		linkoptions { 
			pkgconfig('libarchive','libs'),
			pkgconfig('epoxy','libs'),
		}
		links {
			'z'
		}

		if os.istarget('macosx') then
			files { '../NstDatabase.xml' }
			xcodebuildresources {
				'NstDatabase.xml'
			}
			files {
				'osx/Info.plist',
				'osx/nestopia.icns'
			}
			includedirs {
				'../source/osx',
			}
			files {
				'../source/osx/*.h',
				'../source/osx/*.cpp',
				'../source/osx/*.mm',
			}
			links {
				'Cocoa.framework',
				'AudioToolbox.framework'
			}
		end
		filter{}
		files(sources.SOURCES)

