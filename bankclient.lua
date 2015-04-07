print("Initializing...")
local serial = require("serialization")
local event = require("event")
local serial = require("serialization")
local comp = require("component")
local fs = require("filesystem")
local gpu = comp.getPrimary("gpu")
local computer = require("computer")
local term = require("term")
local modem = comp.getPrimary("modem")

--Variables
local bankPort = 6179
local defaultPort = 1
local fileLocation = "/user.nam"

modem.open(defaultPort) --Default channel

--Functions

function modemHandle (lastSent, iterationLimit) --Allows for debouncing
	answer = "NOT AVAILABLE"
	i = 0
	while i < iterationLimit do
		name, e2, e3, e4, e5, e6 = event.pull(0.5,"modem_message")
		if e6 then
			if not (e6 == lastSent) then
				answer = e6
				i = iterationLimit
			end
		end
		i = i + 1
	end
	return answer
end

--Setup Filesystem

if not fs.exists(fileLocation) then
	print("You have not created an account yet. Please specify your name:")
	Username = io.read()
	userFile = io.open(fileLocation, "w")
	userFile:write(Username)
	userFile:close()
else
	userFile = io.open(fileLocation, "r")
	Username = userFile:read(fs.size(fileLocation))
	userFile:close()
end

--UI Setup
gpu.setBackground(0x414141)
term.clear()
gpu.setForeground(0x0080FF)
print("-----Masterchef365's Client Program -----")
print("Welcome, " .. Username .. "!")
print("Press enter for a command prompt.")
print("type 'help' for command list and descriptions!")


os.sleep(0.5) --Debounce
while true do
	name, e2, e3, e4, e5, e6 = event.pull(2) --Timeout after 2 seconds
	if name == "modem_message" then --Network Messages
		print("-------------NETWORK CONTACT-------------")
		
		--Debug, disable before release!
		print("Modem:")
		print("Bytestring:")
		print(e6)
		print("---Action---")
		
		dataTable = serial.unserialize(e6) 
		
		if dataTable["TO"] == "UPDATE" then
			print("Updating " .. dataTable["PROGRAM"] .. "...")
			--Its update time!
			if fs.exists(dataTable["PROGRAM"]) then
				fs.remove(dataTable["PROGRAM"])
			end
			
			file = io.open(dataTable["PROGRAM"], "w")
			file:write(dataTable["DATA"])
			file:close()
			print("Update done!")
			if (dataTable["REBOOT"] == 1) then
				computer.shutdown(true) --Reboot, changes to autorun.lua may have occurred
			end
		end
		
		if dataTable["TO"] == Username and dataTable["STATE"] == "TOCLIENT" then
			--Its for you, and from a client
			
			if dataTable["ACTION"] == "MESSAGE" then
				print(dataTable["SENDER"] .. ": " .. dataTable["MESSAGE"])
			end
			
		end
		
		os.sleep(1) -- debounce
		
		
		
	elseif name == "key_up" then --Open the prompt
		print("-------------ENTER COMMAND-------------")
		input = io.read()
		
		if input == "portopen" then
			print("What port?")
			if input == "default" then
				modem.open(defaultPort)
			else
				modem.open(tonumber(input))
			end
			print("Port now open.")
		end
		
		if input == "portclose" then
			print("What port?")
			if input == "default" then
				modem.close(defaultPort)
			else
				modem.close(tonumber(input))
			end
			print("Port now closed.")
		end
		
		if input == "bankTransfer" then --Send money to someone else
			m = {}
			print("Transfer money to:")
			m["TO"] = io.read()
			print("Of this amount:")
			m["AMOUNT"] = io.read()
			print("Optional message:")
			m["MESSAGE"] = io.read()
			m["SENDER"] = Username
			m["ACTION"] = "TRANSFER"
			m["STATE"] = "TOSERVER"
			modem.close(defaultPort)
			modem.open(bankPort)
			modem.broadcast(bankPort,serial.serialize(m))
			modem.close(bankPort)
			modem.open(defaultPort)
		end
		
		if input == "bankGet" then --get current balence
			modem.close(defaultPort)
			modem.open(bankPort)
			m = {}
			m["SENDER"] = Username
			m["ACTION"] = "GET"
			m["STATE"] = "TOSERVER"
			modem.broadcast(bankPort,serial.serialize(m))
			response = modemHandle(serial.serialize(m),5)
			if response then
				print("Your current balence is: " .. response)
			else
				print("ERROR: Timeout/nil value")
			end
			modem.close(bankPort)
			modem.open(defaultPort)
		end
		
		if input == "c" then
			m = {}
			m["ACTION"] = "MESSAGE"
			m["STATE"] = "TOCLIENT"
			m["SENDER"] = Username
			print("Enter recipient: ")
			m["TO"] = io.read()
			print("Message:")
			m["MESSAGE"] = io.read()
			modem.broadcast(1,serial.serialize(m))
		end
		
		if input == "exit" then
			os.exit()
		end
		
		
		if input == "help" then
			print("HELP SCREEN:")
			print("Commands:")
			print("c = Chat program, allows messaging")
			print("bankTransfer = Transfer money to someone")
			print("bankGet = Get your balance")
		end
		
		
		print("-------------------------------")
		
		os.sleep(0.5) --Debounce
	end
end