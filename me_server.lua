me = require("component").me_controller
modem = require("component").modem
event = require("event")
serial = require("serialization")

a = {...} --terminal arguments
itemtable = {} --item data from the ME system
msg = {} --client message

me_getItems = function() --update item list in memory
  local items = me.getItemsInNetwork()
  local i = 1
  while items[i] ~= nil do
    itemtable[items[i].label] = items[i].size
    i = i + 1
  end
end

me_search = function(label) --find all items containing the searched string and return the full name and amount
  matches = {}
  if label ~= nil then
    for k,v in pairs(itemtable) do
      if string.find(string.lower(k),string.lower(label)) ~= nil then
        matches[k] = v
      end
    end
  end
  return matches
end

parse_message = function(message)
  local i = 1
  for s in string.gmatch(message, "%S+") do
    msg[i] = s
    i = i + 1
  end
  return msg
end

--main loop
os.execute("clear")
modem.open(202)
while true do
  me_getItems()
  print("Item table updated")
  
  local _, _, from, port, _, message = event.pull(10,"modem_message") --listen for incoming requests
  if message ~= nil then
    print("Got request: ",message)
    msg = parse_message(message)
    if msg[1] == "search" then modem.send(from, 202, serial.serialize(me_search(msg[2]))) --if the client wants to search for items
    else modem.send(from, 202, "no_cmd") --if the client sent a non-command
    end
    print("Request completed successfully")
    from = nil
    port = nil
    message = nil
    msg = {}
  end
 
  os.sleep(1)
end