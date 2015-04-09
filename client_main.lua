print("Initializing...")

--API Imports/Component binds/Component addressing
local serial = require("serialization")
local event = require("event")
local serial = require("serialization")
local comp = require("component")
local fs = require("filesystem")
local gpu = comp.getPrimary("gpu")
local computer = require("computer")
local term = require("term")
local modem = comp.getPrimary("modem")
local shell = require("shell")

--Running variable stuff
local mode = "file_explorer"
currentPath = "/"

--Profile file functions/Initialization/File functions

local userFile = {}
local userFilePath = "/userPrefs.usr"

--Check to see if they have a preference file, if not set up default values and get info
if not fs.exists(userFilePath) then
	--Set up default UI color values (Configurable!)
	if gpu.getDepth() > 1 then --Color Screen
		userFile["defBgColor"] = 0x000000
		userFile["hiBgColor"] = 0x228B22
		userFile["selBgColor"] = 0x62D962
		userFile["defFgColor"] = 0xFFFFFF
	else --Monochrome (not supported)
		print("Currently, the UI version of the client program does not support monochome monitors. You'll have to get tier 2 graphics cards/monitors or higher")
		os.sleep(2)
		os.exit()
	end

	print("You have not created an account on this computer yet. Please specify your name:")
	userFile["name"] = io.read()
	
	prefFile = io.open(userFilePath, "w")
	prefFile:write(serial.serialize(userFile))
	prefFile:close()
else
	prefFile = io.open(userFilePath, "r")
	userFile = serial.unserialize(prefFile:read(fs.size(userFilePath)))
	prefFile:close()
end

function tableFileList(path)
	fileList = {}
	
	--Convert to table
	m = 1
	for i in fs.list(path) do
		fileList[m] = i
		m = m + 1
	end
	return fileList
end

function saveUserPrefs()
	prefFile = io.open(userFilePath, "w")
	prefFile:write(serial.serialize(userFile))
	prefFile:close()
end

--UI set up and info variables
		
local charsPerFileName = 16
local gpuMaxResX, gpuMaxResY = gpu.maxResolution()
local dividerEndPos = math.floor(gpuMaxResX / 8)
local maxOnScreenFilesColumbs = math.floor((gpuMaxResX - dividerEndPos) / charsPerFileName) + 1
local optionsHalfDivPos = math.floor(gpuMaxResY / 2)

--UI Functions

function drawHomescreen()
	gpu.setForeground(userFile["defFgColor"])
	gpu.setBackground(userFile["hiBgColor"])
	gpu.fill(1,1,gpuMaxResX,gpuMaxResY," ") --Borders
	gpu.setBackground(userFile["defBgColor"])
	gpu.fill(2,2,gpuMaxResX-2,gpuMaxResY-2," ") --Background
	gpu.setBackground(userFile["hiBgColor"])
	gpu.fill(dividerEndPos,1,1,gpuMaxResY," ") --Options Divider Line
	gpu.fill(1,optionsHalfDivPos,dividerEndPos,1," ") --Options Divider Line
	
end

function drawOptionList(options,secondary,selectable) --Secondary = second/options list + get Pressed
	gpu.setBackground(userFile["defBgColor"])
	if secondary then
		gpu.fill(2,optionsHalfDivPos+1,dividerEndPos - 2, gpuMaxResY - optionsHalfDivPos -2, " ") --Clear the area!
	else
		gpu.fill(2,2,dividerEndPos - 2, optionsHalfDivPos - 2, " ") --Clear the area!
	end
	
	if secondary then
		gpu.set(2,1+optionsHalfDivPos,options["title"])
	else
		gpu.set(2,2,options["title"])
	end
	
	
	--Print off options
	for  y = 1,#options do
		if secondary then
			gpu.set(3,y+optionsHalfDivPos+1,options[y]) -- -1 is because of the 'title' entry
		else
			gpu.set(3,2+y,options[y])
		end
	end
	
	
	if selectable then
		if secondary then --Bottom Slot, top slot has its own selection thing
			os.sleep(0.8) --Debounce
			press = table.pack(event.pull(2,"touch"))
			if (press[4]) then
				if (press[4] - optionsHalfDivPos -1) <= #options then --Make sure its not a random place on da screen
					return(options[press[4] - optionsHalfDivPos - 1])
				end
			else
				return options[#options]
			end
		end
	end
	
end

function openTextFeild (yValue)
	gpu.setBackground(userFile["hiBgColor"])
	gpu.fill(1,yValue,gpuMaxResX,3," ")
	gpu.setBackground(userFile["defBgColor"])
	gpu.fill(1,yValue + 1,gpuMaxResX,1," ")
	term.setCursor(1,yValue+1)
	output = io.read()
	drawHomescreen()
	return output
end


function drawFileView(path)
	currentPath = path
	gpu.setBackground(userFile["defBgColor"])
	gpu.fill(dividerEndPos+1,2,gpuMaxResX - 2 - dividerEndPos, gpuMaxResY - 2, " ") --Clear area
	gpu.setBackground(userFile["hiBgColor"])
	fileList = tableFileList(path)
	
	i = 1
	for row = 2, gpuMaxResY-2 do 
		for col = 1, maxOnScreenFilesColumbs do
			if i <= #fileList then
				gpu.set((col*16)+dividerEndPos-15,row,fileList[i])
				i = i + 1
			end
		end
	end
	
end



--UI Initialization/HomeScreen

function drawDefaultScreen()

optionListElements = {["title"]="File Explorer",[1]="Previous Dir",[2]="/Root",[3]="Exit"}

drawHomescreen()
drawOptionList(optionListElements,false,false)

drawFileView(currentPath)

end

drawDefaultScreen()

while true do --Main Loop
	action = table.pack(event.pull(8)) --Timeout to keep the computer alive and fix graphics articfacts
	
	if (action[1]) then -- its GO TIME
		if action[1] == "touch" then --Someone tapped the screen
			if action[3] <= dividerEndPos then --Options panel
				if action[4] > 2 and action[4] < optionsHalfDivPos then --Not secondary panel (Its has its own function this needs to run all the time)
					if mode == "file_explorer" then
						
						op = optionListElements[action[4] - 2]
						
						if op == "Previous Dir" then
							currentPath = fs.path(currentPath) --Get one level above
							drawFileView(currentPath)
						end
						
						if op == "Exit" then
							os.exit()
						end
						
						if op == "/Root" then
							currentPath = "/"
							drawFileView(currentPath)
						end
						
					end
				end
				
			else --Main Screen
			
				if mode == "file_explorer" then
					dirList = {}
					dirList = tableFileList(currentPath)
					col = math.floor(action[3]/16)
					row = action[4] - 1
					i = (maxOnScreenFilesColumbs * (row - 1))+col
					if dirList[i] then --Check if it exists or not
						if fs.isDirectory(dirList[i]) then
							currentPath = currentPath .. dirList[i]
							drawFileView(currentPath)
						else
							--Select and display options
							gpu.setBackground(userFile["selBgColor"])
							gpu.set((col * 16)+5,row + 1, dirList[i])
							op = drawOptionList({["title"]="File Options",[1]="Launch",[2]="Edit",[3]="Rename",[4]="Delete",[5]="Rename",[6]="Move to",[7]="Cancel"},true,true)
							
							if op == "Launch" then
								shell.execute(currentPath .. dirList[i])
								drawDefaultScreen()
							end
							
							if op == "Edit" then
								shell.execute("edit " .. currentPath .. dirList[i])
								drawDefaultScreen()
							end
							
							if op == "Rename" then
								ans = openTextFeild(action[4] + 1)
								shell.execute("mv " .. currentPath .. dirList[i] .. " " .. currentPath .. ask)
								drawDefaultScreen()
							end
							
							if op == "Move to" then
								ans = openTextFeild(action[4] + 1)
								shell.execute("mv " .. currentPath .. dirList[i] .. " " .. ask)
								drawDefaultScreen()
							end
							
							if op == "Delete" then
								ask = drawOptionList({["title"]="Are you sure?",[1]="Yes",[2]="No"},true,true) --Confirmation
								if ask == "Yes" then
									shell.execute("del " .. currentPath .. dirList[i])
								end
							end
							
							if op == "Cancel" then
								gpu.fill(2,optionsHalfDivPos+1,dividerEndPos - 2, gpuMaxResY - optionsHalfDivPos -2, " ") --Clear option list area
								drawFileView(currentPath)
							end
							
						end
					end
				end
			end
		end --Touch event
	else --Action Check
		drawDefaultScreen() --Fix graphics artifacts if theres an issue
	end
end --Main Loop

