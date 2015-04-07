modem = require("component").modem
event = require("event")
serial = require("serialization")
term = require("term")

modem.open(202)
os.execute("clear")
print("ME CLIENT v0.1")

getCommand = function()
  io.flush()
  print(">")
  local x,y = term.getCursor()
  term.setCursor(x+1,y-1)
  return io.read()
end

printHelp = function()
  print("Available Commands:")
  print("help - display this menu")
  print("search \"<string>\" - search for items")
  print("quit - exits the program")
end

printHelp()
while true do
  input = getCommand()
  if input == "quit" then break
  elseif input == "help" then printHelp()
  else
    modem.broadcast(202, input)
    local _, _, from, port, _, message = event.pull(5,"modem_message")
    if message == "no_cmd" then 
      print("Bad input, check the command you typed")
    elseif message == nil then
      print("Request timed out, please contact admin")
    else
      print("------------------------------")
      print("Press any key to scroll down")
      for k,v in pairs(serial.unserialize(message)) do print(k,v) event.pull(10,"key_down") end
      print("------------------------------")
    end
  end
  input = nil
  from = nil
  port = nil
  message = nil
end