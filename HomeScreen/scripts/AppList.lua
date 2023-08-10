local AppList = {}

AppList.notifyUpdateFunction = function()
  assert("Update function of AppList not set")
end

local private = {} -- internal private members

private.lastAppListJson = "[]"

-- public interface to get the current applist as full json for the ui
AppList.getAsJson = function()
  return private.lastAppListJson
end

AppList.update = function()
  local appList = private.getAppList()
  private.lastAppListJson = private.convertAppListToJson(appList)
  --print("Update: " .. private.lastAppListJson)
  AppList.notifyUpdateFunction(private.lastAppListJson)
  private.timer:start() -- start timer manually again to avoid overruns if we need longer for handling
end

-- update the app list cyclic internally
private.timer = Timer.create()
private.timer:setExpirationTime(3000)
private.timer:setPeriodic(false) -- starting the timer manually to avoid overruns because handling might need longer
private.timer:register("OnExpired", AppList.update)

-- Create the list of the current apps on the device
private.getAppList = function()
  local appList
  if (Engine.listApps) then -- this function is only available with AppEngine >= 2.11
    appList = Engine.listApps()
  else
    -- FOLLOWING CODE IS JUST WORKAROUND FOR APPENGINE < 2.11 -- IGNORE AND REMOVE IN FUTURE !!!
    appList = private.getAppListLegacy()
  end
  --appList = {"app1", "app2"}
  return appList
end

-- Create the string representing the apps for displaying in tabelview
private.convertAppListToJson = function(apps)
  local json = "["
  for _,appName in pairs(apps) do
    local appStatus = private.getAppStatusString(appName)
    --local hasWebpage = private.getAppHasWebpage(appName)

    json = json .. "{"
    json = json .. "\"appName\":\""    .. tostring(appName)     .. "\","
    json = json .. "\"appStatus\":\""  .. tostring(appStatus)   .. "\","
    --json = json .. "\"hasWebpage\":"   .. tostring(hasWebpage)  .. ","
    json = json .. "\"href\":\"?msdd=" .. tostring(appName)     .. ".msdd\""
    json = json .. "},"
  end

  if(json:len() > 1) then
    json = json:sub(1, -2)
  end
  json = json .. "]"

  return json
end

private.getAppStatusString = function(appName)
  local appStatus = "UNKNOWN"
  if Monitor.App then -- only if there is already the app monitor API integrated
    local monitor = Monitor.App.create(appName)
    if monitor then
      appStatus = monitor:getStatusInfo()
    end
  end
  return appStatus
end

private.getAppHasWebpage = function(appName)
  local hasWebpage = "false"
  -- TODO
  -- Idea: add a new API function to get app infos like has-webpage

  -- ATTENION: FOLLOWING CODE IS TEMPORARY WORKAROUND
  -- Workaround: Check with TCPIPClient if there is an msdd of the app on the URL
  --             (probably also HTTPClient, but HTTPClient has more API dependencies and is not on every device)
  local handle = TCPIPClient.create()
  handle:setIPAddress("127.0.0.1")
  handle:setPort(80)
  handle:connect(500)
  if (handle:isConnected()) then
    local httpRequest = "GET /current.msdd?msdd=" .. tostring(appName) .. ".msdd HTTP/1.1\r\n"
    --httpRequest = httpRequest .. "HOST: 127.0.0.1\n"
    --httpRequest = httpRequest .. "Connection: close\n"
    httpRequest = httpRequest .. "\r\n"
    --print("httpRequest: ")
    --print(httpRequest)
    if (handle:transmit(httpRequest)) then
      local httpResponse = handle:receive(1000)
      --print("httpResponse: " .. httpResponse)
      local seeOther = "HTTP/1.1 303 See Other" -- Compatibility to older AE where there is a session needed for msdd. On newer AE it isn't
      if (httpResponse and string.sub(httpResponse, 1, string.len(seeOther)) == seeOther) then
        local locationKeyText = "Location: "
        local locationInd = httpResponse:find(locationKeyText)
        local locationStart = locationInd + locationKeyText:len()
        local locationEnd = httpResponse:find("\r\n", locationStart + 1) - 1
        local redirection = httpResponse:sub(locationStart, locationEnd)
        --print(redirection)
        handle:disconnect()
        handle:connect()
        httpRequest = "GET " .. redirection .. " HTTP/1.1\r\n"
        httpRequest = httpRequest .. "\r\n"
        assert(handle:transmit(httpRequest))
        httpResponse = handle:receive(1000)
        --print("httpResponse: " .. httpResponse)
      end
      local expected = "HTTP/1.1 200 OK"
      if (httpResponse and string.sub(httpResponse, 1, string.len(expected)) == expected) then
        hasWebpage = true
      end
      repeat -- always receive rest of data to avoid webserver warnings
        httpResponse = handle:receive(500)
        --print(httpResponse)
      until not httpResponse or #httpResponse == 0
    end
    handle:disconnect()
  end
  return hasWebpage
end

-------------------------------------
-- IGNORE FOLLOWING OLD CODE FOR COMPATIBILITY
private.getAppListLegacy = function()
  local appList = {}
  if (Command.Client) then
    -- Try to list like AppStudio does. Very prelimary!
    local conHandle = TCPIPClient.create()
    conHandle:setIPAddress("127.0.0.1")
    conHandle:setPort(2111)
    conHandle:connect()
    assert( conHandle:isConnected() )

    local tempCidPath = "/resources/HomeScreenTempLegacy.cid.xml"
    assert(File.exists(tempCidPath))

    local handle = Command.Client.create()
    handle:setDescriptionFile(tempCidPath)
    handle:setProtocol("COLA_A")
    handle:setConnection(conHandle)
    assert ( handle:open() )

    local curPos = 0
    local goOn = true

    while (goOn) do
      goOn = false
      local paramNode = handle:createNode("mFSAcc")
      assert(paramNode)
      assert(paramNode:set("plugins:///?subdir&nr=" .. tostring(curPos), "URL"))
      assert(paramNode:set("", "Buffer"))
      assert(paramNode:set(0, "BufferCRC"))

      local success, retNode = handle:invoke("mFSAcc", paramNode)
      assert(success == true)
      assert(retNode)
      
      local retUrl = retNode:get("URL")
      if (retUrl) then
        goOn = (retUrl:sub(1,3) == "?ok")
        if goOn then
          local appNameKeyText = "name="
          local appNameInd = retUrl:find(appNameKeyText)
          if (appNameInd) then
            local appNameStart = appNameInd + appNameKeyText:len()
            local appNameEnd = retUrl:find("%.sar&", appNameStart + 1)
            if nil == appNameEnd then
              appNameEnd = retUrl:find("%.csar&", appNameStart + 1)
            end

            if (appNameEnd) then
              local appName = retUrl:sub(appNameStart, appNameEnd - 1)
              --print(appName)
              table.insert(appList, appName)
            end
          end
        end
      end

      --print(retNode:get("URL"))
      --print(retNode:get("Buffer"))
      --print(retNode:get("BufferCRC"))

      curPos = curPos + 1
    end
  else
    appList = {"This AppEngine does not support the needed functions"}
  end
  return appList
end
-----------------------------

return AppList
