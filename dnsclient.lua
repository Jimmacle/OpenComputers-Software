event = require("event")
modem = require("component").modem
serial = require("serialization")
a = {...}

splitMessage = function(message)
  local i = 1
  local msgArgs = {"",""}
  msgArgs[1] = message
  for x in string.gmatch(message, "%S+") do
    msgArgs[i] = x
    i = i + 1
  end
  return msgArgs
end

if a[1] == "debug" then
  while true do
    modem.broadcast(53,serial.serialize(splitMessage(io.read())))
    
    modem.open(53)
    local _,_,from,port,_,message = event.pull(5,"modem_message")
    modem.close(53)
    
    if message == nil then print("Error: Request timed out")
    else
      print(message)
      message = nil
    end
  end
elseif a[1] == "initialize" then --check in with dns server
  hostname = os.getenv("HOSTNAME")
  if hostname == nil then
    print("DNS FAIL: No hostname")
  elseif string.len(hostname) <= 3 then
    print("DNS FAIL: Hostname must be greater than 3 characters")
  else
    modem.broadcast(53,serial.serialize(splitMessage("set "..hostname)))
  end
elseif a[1] == "refresh" then --get dns table from dns server
  modem.open(53)
  modem.broadcast(53,serial.serialize(splitMessage("get")))
  local _,_,from,port,_,message = event.pull(5,"modem_message")
  modem.close(53)
  if message ~= nil then
    local f = io.open("/etc/hosts","w")
    f:write(message)
    f:flush()
    f:close()
    print("DNS SUCCESS: Updated /etc/hosts")
  end
end