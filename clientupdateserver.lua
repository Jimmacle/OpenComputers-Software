print("Initializing...")
local shell = require("shell")
local serial = require("serialization")
local event = require("event")
local serial = require("serialization")
local comp = require("component")
local fs = require("filesystem")
local gpu = comp.getPrimary("gpu")
local computer = require("computer")
local term = require("term")
local modem = comp.getPrimary("modem")

args = shell.parse(...)
name = args[1]
reboot = args[2]

File = io.open(name, "r")
data = File:read(fs.size(name))
File:close()

m = {}
modem.open(1)
m["TO"] = "UPDATE"
m["PROGRAM"] = name
m["DATA"] = data
m["REBOOT"] = reboot
modem.broadcast(1, serial.serialize(m))
print("Done")