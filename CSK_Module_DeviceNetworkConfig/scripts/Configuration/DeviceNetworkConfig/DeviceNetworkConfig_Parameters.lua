---@diagnostic disable: redundant-parameter, undefined-global

--***************************************************************
-- Inside of this script, you will find the relevant parameters
-- for this module and its default values
--***************************************************************

local functions = {}

local function getParameters()

  local deviceNetworkConfigParameters = {}

  deviceNetworkConfigParameters.nameservers = {} -- Name servers (DNS)

  deviceNetworkConfigParameters.bridgeActive = false -- Set status to activate ethernet bridge
  deviceNetworkConfigParameters.bridgeInterfaces = {} -- List of ports to bridge
  deviceNetworkConfigParameters.bridgeIP = '192.168.0.123' -- IP address of bridge
  deviceNetworkConfigParameters.bridgeSubnetMask = '255.255.255.0' -- Subnet mask of bridge
  deviceNetworkConfigParameters.bridgeGateway = '0.0.0.0' -- Gateway of bridge
  deviceNetworkConfigParameters.bridgeDelay = 10 -- Time in seconds to wait after restart to activate bridge
  deviceNetworkConfigParameters.bridgeTestTime = 5 -- Time in minutes to reset bridge

  return deviceNetworkConfigParameters
end
functions.getParameters = getParameters

return functions