print("Initializing...")

os.sleep(10)

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

--UI Variables:

if gpu.getDepth() > 1 then --Color Screen
	defBgColor = 0x000000
	hiBgColor = 0x228B22
	selBgColor = 0x62D962
	defFgColor = 0xFFFFFF
else --Monochrome (So users don't get a completely white screen :P)
	defBgColor = 0x000000
	hiBgColor = 0xFFFFFF
	defFgColor = 0xFFFFFF
end
		
local gpuMaxResX, gpuMaxResY = gpu.maxResolution()
local dividerEndPos = math.floor(gpuMaxResX / 8)

--UI Functions

function drawHomescreen()
	gpu.setBackground(hiBgColor)
	gpu.fill(1,1,gpuMaxResX,gpuMaxResY," ") --Borders
	gpu.setBackground(defBgColor)
	gpu.fill(2,2,gpuMaxResX-2,gpuMaxResY-2," ") --Background
	gpu.setBackground(hiBgColor)
	gpu.fill(dividerEndPos,1,1,gpuMaxResY," ") --Options Divider Line
end

function drawOptionList(options)
	gpu.setBackground(defBgColor)
	gpu.set(2,2,options["title"])
	for  y = 1,#options do
		gpu.set(3,2+y,options[y])
	end
end

--UI Initialization/HomeScreen

drawHomescreen()
m = {}
m["title"] = "This is a test!"
m[1] = "Hello, "
m[2] = "this"
m[3] = "is"
m[4] = "an"
m[5] = "options"
m[6] = "list"
drawOptionList(m)

while true do --Main Loop
	event = {}
	event = event.pull(2) --Timeout to keep the computer alive
	
	if event["name"] then
		print(event)
	
	
	
	
	end
end








