--MIT License
--
--Copyright (c) 2023 SICK AG
--
--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.

---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
-----------------------------------------------------------
-- If app property "LuaLoadAllEngineAPI" is FALSE, use this to load and check for required APIs
-- This can improve performance of garbage collection
_G.availableAPIs = require('Configuration.PersistentData.helper.checkAPIs') -- can be used to adjust function scope of the module related on available APIs of the device
-----------------------------------------------------------
-- Logger
_G.logger = Log.SharedLogger.create('ModuleLogger')
_G.logHandle = Log.Handler.create()
_G.logHandle:attachToSharedLogger('ModuleLogger')
_G.logHandle:setConsoleSinkEnabled(false) --> Set to TRUE if CSK_Logger module is not used
_G.logHandle:setLevel("ALL")
_G.logHandle:applyConfig()
-----------------------------------------------------------

-- Loading script regarding PersistentData_Model
-- Check this script regarding PersistentData_Model parameters and functions
_G.persistentData_Model = require('Configuration/PersistentData/PersistentData_Model')

--**************************************************************************
--**********************End Global Scope ***********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Function to react on startup event of the app
local function main()

  ----------------------------------------------------------------------------------------
  -- Can be used e.g. like this
  ----------------------------------------------------------------------------------------
  -- If you want to trigger other modules to optionally load stored parameters initially at app start
  -- (every module can decide itself if it should load its parameters...)
  if _G.persistentData_Model.initialLoading then
    Script.notifyEvent('PersistentData_OnInitialDataLoaded')
  end

  --OR
  --CSK_PersistentData.loadContent() -- if you want to load manually parameters saved last time

  -- OR
  --_G.persistentData_Model.setPath('/public/Test_Data.bin')

  --[[
  -- Create parameters (also in other modules)
  local parameter1 = {}
  parameter1.numbers = 123456
  parameter1.name = 'HeyThere'

  local parameter2 = {}
  parameter2.numbers = 654987
  parameter2.name = 'HeyThere2'
  parameter2.img = Image.create(800, 800, "INT8")

  -- CROWN interface function
  CSK_PersistentData.addParameter(_G.persistentData_Model.funcs.convertTable2Container(parameter1), 'TestParameter1')
  CSK_PersistentData.addParameter(_G.persistentData_Model.funcs.convertTable2Container(parameter2), 'TestParameter2')
  CSK_PersistentData.addParameter(_G.persistentData_Model.funcs.convertTable2Container(parameter2), 'TestParameter3')
  CSK_PersistentData.removeParameter('TestParameter3')
  CSK_PersistentData.saveData()

  -- OR

  -- internal function
  --_G.persistentData_Model.addParameterTable(parameter1, 'TestParameter1')
  --_G.persistentData_Model.addParameterTable(parameter2, 'TestParameter2')
  --_G.persistentData_Model.addParameterTable(parameter2, 'TestParameter3')
  --_G.persistentData_Model.removeParameter('TestParameter3')
  --_G.persistentData_Model.saveData()
  --print(_G.persistentData_Model.data.TestParameter2.numbers)

  local paramsContainer = CSK_PersistentData.getParameter('TestParameter2')  -- Get Parameters as Container object
  local paramsTable = _G.persistentData_Model.funcs.convertContainer2Table(paramsContainer)
  print(paramsTable.numbers)
  ]]
  ----------------------------------------------------------------------------------------
  CSK_PersistentData.pageCalled() -- Update UI
end
Script.register("Engine.OnStarted", main)

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************