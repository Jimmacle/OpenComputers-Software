event = require("event")
modem = require("component").modem
serial = require("serialization")
--dnsFile = io.open("dnstable.txt","r")

dnsTable = {}

modem.open(53)

findKForV = function(tbl, val)
  for k,v in pairs(tbl) do
    if v == val then return k
    else return nil end
  end
end

dnsTable["dns_server"] = modem.address
while true do
  local _,_,from,port,_,message = event.pull(10,"modem_message")
  if message ~= nil then 
    print(message)
    message = serial.unserialize(message)

    if message[1] == "set" then --if a client is registering itself
      dnsTable[message[2]] = from
      reply = from.."="..message[2]
    elseif message[1] == "unset" then --if a client is unregistering itself
      dnsTable[tostring(findKForV(dnsTable, from))] = nil
      reply = "unset"
    elseif message[1] == "get" then --if a client wants to resolve a name(s)
      if message[2] ~= "" then --if the client wants a specific name
        reply = dnsTable[message[2]]
      else reply = dnsTable --if the client doesn't specify a name
      end
    else reply = "bad_cmd" --if the recieved message makes no sense
    end
    print(serial.serialize(reply))
    modem.send(from, 53, serial.serialize(reply))
    reply = nil
  end
  os.sleep(0.1)
end