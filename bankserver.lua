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
local fileLocation = "/bank.dbm"
local userDBLocation = "/users.dbm"
local defualtForeground = 0x00FF00
local defaultPort = 6179 --In columbs, these keys are above the letters 'bank' on a keyboard.
bank = {} --Current Database

--Functions
function modemHandle (lastSent, iterationLimit)  --Allows for debouncing
	for i = 1,iterationLimit do
		name, e2, e3, e4, e5, e6 = event.pull(0.5,"modem_message")
		if not e6 == lastSent then
			break
		end
	end
	return e6
end

	
function reloadFile(location) --Refresh Database
	bankFile = io.open(location, "r")
	data = bankFile:read(fs.size(location))
	bankFile:close()
	return serial.unserialize(data)
end

	
function saveData(location, data) --Save to database
	bankFile = io.open(location, "w")
	bankFile:write(serial.serialize(data))
	bankFile:close()
end


--Setup UI
term.clear()
gpu.setForeground(defualtForeground)

modem.open(defaultPort) --Default


--Setup Filesystem

--If it doesn't exist create it
if not fs.exists(fileLocation) then
	bank["default"] = 0
	saveData(fileLocation, bank)
end

print(fileLocation)
bank = reloadFile(fileLocation)

os.sleep(0.5) --Debouce
print("Initialize Done")
print("-------------------------------")
print("Current State:")
for k,v in pairs(bank) do print(k,v) end
print("+-----------------------------+")
print("|Switching to normal Operation|")
print("|Press any key to open prompt.|")
print("+-----------------------------+")

while true do
	name, e2, e3, e4, e5, e6 = event.pull(2) --Timeout after 2 seconds
	
	
	if name == "modem_message" then
		dataTable = serial.unserialize(e6) --Kinda like JSON, right? xD
	end
	
	if name == "modem_message" and dataTable["STATE"] == "TOSERVER" then --Network Messages
		print("Modem:")
		print("Bytestring:")
		print(e6)
		print("---Action---")
		
		if dataTable["ACTION"] == "GET" then --Get the value
			if bank[dataTable["SENDER"]] then 
				print("Uploading bank data for " .. dataTable["SENDER"] .. "(" .. bank[dataTable["SENDER"]] .. ")")
				modem.broadcast(defaultPort,bank[dataTable["SENDER"]])
			end
		end
		
		if dataTable["ACTION"] == "TRANSFER" then --Transfer money
			if bank[dataTable["SENDER"]] and bank[dataTable["TO"]] then 
				print("Transferring " .. dataTable["AMOUNT"] .. " From " .. dataTable["SENDER"] .. " To " .. dataTable["TO"]) 
				if tonumber(bank[dataTable["SENDER"]]) > 0 and tonumber(dataTable["AMOUNT"]) <= tonumber(bank[dataTable["SENDER"]]) then
					bank[dataTable["TO"]] = bank[dataTable["TO"]] + dataTable["AMOUNT"]
					bank[dataTable["SENDER"]] = bank[dataTable["SENDER"]] - tonumber(dataTable["AMOUNT"])
				else
					Print("User has insufficient funds!")
				end
			else
				print("Account does not exist!")
			end
			
			os.sleep(1) --Debounce
		end
		
		
		
		
		os.sleep(1) -- debounce
		
		print("-------------------------------")
		
	elseif name == "key_up" then --Open the prompt
		print("Command:") 
		input = io.read()
		
		if input == "exit" then
			saveData(fileLocation, bank)
			os.exit()
		end
		
		if input == "listAll" then
			for k,v in pairs(bank) do
				print(k,v)
			end
		end
		
		if input == "set" then
			gpu.setForeground(0x00AAFF)
			print("Set Data for:")
			user = io.read()
			print("Set To:")
			bank[user] = tonumber(io.read())
			print(user .. "'s balance is now: " .. tostring(bank[user]))
			gpu.setForeground(defualtForeground)
		end
		
		if input == "remove" then
			print("Remove:")
			entry = io.read()
			bank[entry] = nil
		end
		
		if input == "save" then
			saveData(fileLocation, bank)
		end
		
		if input == "help" then
			print("Help Screen:")
			print("	exit = Exit this program")
			print("	listAll = List all users and their account balances")
			print("	set = Set the balance of someone")
			print("	remove = remove entry")
			print("	save = Save the data into system memory")
		end
		
		print("-------------------------------")
		
		os.sleep(0.5) --Debounce
	end
end



print("Initialize done")
print("Bank server v0.1A")