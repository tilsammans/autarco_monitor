-- QUICKAPP SolarEdge Monitor

-- This QuickApp monitors your SolarEdge managed Solar Panels
-- The QuickApp has (child) devices for currentPower, lastDayData, lastMonthData, lastYearData and lifeTimeData
-- The settings for Peak Power and Currency are retrieved from the inverter 
-- The rateType interface of Child device Last Day is automatically set to "production" and can be shown in the Energy Panel 
-- The readings for lastmonth, lastyear and lifetime energy are automatically set to the right Wh unit (Wh, kWh, MWh or GWh) 
-- See API documentation on https://www.solaredge.com/sites/default/files/se_monitoring_api.pdf 


-- Changes version 1.4 (22th February 2022)
-- Changed rounding of all Wh values to one number after the decimal point, to prevent issues with decreasing values from SolarEdge Cloud
-- Added extra check for decreasing values from SolarEdge Cloud lastDayData
-- Changed handling bad responses from SolarEdge Cloud
-- Removed QuickApp variable icon, icon can be selected in the user interface with the new firmware


-- Changes version 1.3 (8th January 2022)
-- Extra check on return value API for "Too many requests"

-- Changes version 1.2 (26th August 2021)
-- Added values update main device to power interface to show usage in Power consumption chart
-- Solved a bug in the lifeTimeData.revenue existence check

-- Changes version 1.1 (21th August 2021)
-- Changed back currentPower measurement to Watt and lastDayData, lastMonthData to kWh (not to mess up statistics in Energy panel or InfluxDB/Grafana installations)
-- Changed Child device currentPower to Main device with type com.fibaro.powerSensor (Watt). So the Main device will show the current power production, no Child device necessary. 
-- Changed Child device lastDayData to type com.fibaro.energyMeter (kWh). These values will be shown in the new energy panel. 
-- Added automaticaly change rateType interface of Child device lastDayData to "production"
-- Added extra check on apiKey and siteID, if not OK then change to simulation mode
-- SolarEdge Monitor settings currency and PiekPower also available in simulation mode
-- Changed the lastUpdateTime to format dd-mm-yyyy hh:mm 

-- Changes version 1.0 (30th July 2021)
-- Total m² solar panels added to log text and label text
-- Check for API existance of lifeTimeData_revenue (not available in older firmware)
-- Automatic conversion added for lastmonthData, lastYearData and lifetimeData production to Wh, kWh, MWh or GWh
-- Automatic conversion added for currentPower to Watt, Kilowatt, Megawatt or Gigawatt (yes, Megawatt and Gigawatt is optimistic)
-- Get the Peakpower and Currency settings from Inverter
-- Peakpower added to label text and child device log text

-- Changes version 0.3 (12th April 2021)
-- Added last update date / time
-- Cleaned up the code

-- Changes version 0.2 (12th April 2021)
-- Disabled revenue value (except for lifeTimeData)

-- Changes version 0.1 (11th April 2021)
-- First (test) version


-- Variables (mandatory): 
-- siteID = Site ID of your SolarEdge Inverter (see your Inverter Site Details)
-- apiKey = API key of your SolarEdge Inverter (contact your installer if you don't have one)
-- solarM2 = The amount of m2 Solar Panels (use . for decimals) for calculating Solar Power m2 (default = 0)
-- interval = The daily API limitation is 300 requests. The default request interval is 360 seconds (6 minutes).
-- debugLevel = Number (1=some, 2=few, 3=all, 4=simulation mode) (default = 1)


-- Example json overview string from API documentation:
-- {"overview": {"lastUpdateTime": "2021-03-01 02:37:47","lifeTimeData": {"energy": 761985.75,"revenue": 946.13104},"lastYearData": {"energy": 761985.8,"revenue": 946.13104},"lastMonthData": {"energy": 492736.7,"revenue": 612.09528},"lastDayData": {"energy": 1327.3,"revenue": 1.64844},"currentPower": {"power": 304.8}}}

-- Example json overview string from SolarEdge response:
-- {"overview":{"lastUpdateTime":"2021-04-12 13:46:04","lifeTimeData":{"energy":7827878.0,"revenue":1728.5211},"lastYearData":{"energy":573242.0},"lastMonthData":{"energy":113386.0},"lastDayData":{"energy":7373.0},"currentPower":{"power":134.73499},"measuredBy":"INVERTER"}}


-- No editing of this code is needed 


class 'solarPower'(QuickAppChild)
function solarPower:__init(dev)
  QuickAppChild.__init(self,dev)
end
function solarPower:updateValue(data) 
  self:updateProperty("value", tonumber(data.solarPower))
  self:updateProperty("unit", "Watt/m²")
  self:updateProperty("log", details.peakPower .." kWp / " ..solarM2 .." m²")
end

class 'lastDayData'(QuickAppChild)
function lastDayData:__init(dev)
  QuickAppChild.__init(self,dev)
  if fibaro.getValue(self.id, "rateType") ~= "production" then 
    self:updateProperty("rateType", "production")
  self:warning("Changed rateType interface of SolarEdge lastDayData child device (" ..self.id ..") to production")
  end
end
function lastDayData:updateValue(data) 
  self:updateProperty("value", tonumber(data.lastDayData))
  self:updateProperty("unit", "kWh")
  self:updateProperty("log", "")
end

class 'lastMonthData'(QuickAppChild)
function lastMonthData:__init(dev)
  QuickAppChild.__init(self,dev)
end
function lastMonthData:updateValue(data) 
  self:updateProperty("value", tonumber(data.lastMonthData))
  self:updateProperty("unit", "kWh")
  self:updateProperty("log", "")
end

class 'lastYearData'(QuickAppChild)
function lastYearData:__init(dev)
  QuickAppChild.__init(self,dev)
end
function lastYearData:updateValue(data) 
  self:updateProperty("value", tonumber(data.lastYearData))
  self:updateProperty("unit", data.lastYearUnit)
  self:updateProperty("log", "")
end

class 'lifeTimeData'(QuickAppChild)
function lifeTimeData:__init(dev)
  QuickAppChild.__init(self,dev)
end
function lifeTimeData:updateValue(data) 
  self:updateProperty("value", tonumber(data.lifeTimeData))
  self:updateProperty("unit", data.lifeTimeUnit)
  self:updateProperty("log", data.lifeTimeData_revenue)
end


local function getChildVariable(child,varName)
  for _,v in ipairs(child.properties.quickAppVariables or {}) do
    if v.name==varName then return v.value end
  end
  return ""
end


-- QuickApp functions


function QuickApp:logging(level,text) -- Logging function for debug
  if tonumber(debugLevel) >= tonumber(level) then 
      self:debug(text)
  end
end


function QuickApp:solarPower(power, m2) -- Calculate Solar Power M2
  self:logging(3,"Start solarPower")
  if m2 > 0 and power > 0 then
    solarPower = power / m2
  else
    solarPower = 0
  end
  return solarPower
end


function QuickApp:unitCheckWh(measurement) -- Set the measurement and unit to kWh, MWh or GWh
  self:logging(3,"Start unitCheckWh")
  if measurement > 1000000000 then
    return string.format("%.1f",measurement/1000000000),"GWh"
  elseif measurement > 1000000 then
    return string.format("%.1f",measurement/1000000),"MWh"
  elseif measurement > 1000 then
    return string.format("%.1f",measurement/1000),"kWh"
  else
    return string.format("%.0f",measurement),"Wh"
  end
end


function QuickApp:updateProperties() -- Update the properties
  self:logging(3,"updateProperties")
  self:updateProperty("value", tonumber(data.currentPower))
  self:updateProperty("power", tonumber(data.currentPower))
  self:updateProperty("unit", "Watt")
  self:updateProperty("log", data.lastUpdateTime)
end


function QuickApp:updateLabels() -- Update the labels
  self:logging(3,"updateLabels")
  local labelText = ""
  if debugLevel == 4 then
    labelText = labelText .."SIMULATION MODE" .."\n\n"
  end
  labelText = labelText .."Current power: " ..data.currentPower .." Watt" .."\n\n"
  labelText = labelText .."Peakpower: " ..details.peakPower .." kWp" .."\n"
  labelText = labelText .."Solar power: " ..data.solarPower .." Watt/m² (" ..solarM2 .." m²)" .."\n"
  labelText = labelText .."Lastday: " ..data.lastDayData .." kWh" .."\n"
  labelText = labelText .."Lastmonth: " ..data.lastMonthData .." kWh" .."\n"
  labelText = labelText .."Lastyear: " ..data.lastYearData .." " ..data.lastYearUnit .."\n"
  labelText = labelText .."Lifetime: " ..data.lifeTimeData .." " ..data.lifeTimeUnit .." (" ..data.lifeTimeData_revenue ..")" .."\n\n"
  labelText = labelText .."Last update: " ..data.lastUpdateTime .."\n" 
  self:updateView("label1", "text", labelText)
  self:logging(2,labelText)
end


function QuickApp:valuesCheck() -- Check of Cloud value lastDayData
  self:logging(3,"valuesCheck")
  self:logging(2,"Previous lastDayData: " ..data.prevlastDayData .. " / Next lastDayData: " ..data.lastDayData)
  local templastDayData = data.lastDayData -- Save lastDayData
  if tonumber(data.prevlastDayData) ~= 0 and tonumber(data.lastDayData) ~= 0 and (tonumber(data.lastDayData) < tonumber(data.prevlastDayData)) then -- Check previous value with next value 
    self:trace("Decreasing value lastDayData ignored (Energy Panel Child Device), previous value: " ..data.prevlastDayData .." next value: " ..data.lastDayData)
    data.lastDayData = string.format("%.1f", data.prevlastDayData) -- Restore previous lastDayData value
  end
  data.prevlastDayData = string.format("%.1f", templastDayData) -- Save lastDayData to 
end


function QuickApp:valuesOverview() -- Get the values from json file Overview
  self:logging(3,"valuesOverview")
  data.currentPower = string.format("%.0f", jsonTable.overview.currentPower.power)
  data.solarPower = string.format("%.1f",self:solarPower(tonumber(data.currentPower), tonumber(solarM2)))
  data.lastDayData = string.format("%.1f",jsonTable.overview.lastDayData.energy/1000)
  data.lastMonthData = string.format("%.1f",jsonTable.overview.lastMonthData.energy/1000)
  data.lastYearData = jsonTable.overview.lastYearData.energy
  data.lastYearData, data.lastYearUnit = self:unitCheckWh(tonumber(data.lastYearData)) -- Set measurement and unit to kWh, MWh or GWh
  data.lifeTimeData = jsonTable.overview.lifeTimeData.energy
  data.lifeTimeData, data.lifeTimeUnit = self:unitCheckWh(tonumber(data.lifeTimeData)) -- Set measurement and unit to kWh, MWh or GWh
  if jsonTable.overview.lifeTimeData.revenue ~= nil then -- lifeTimeData_revenue is not mandatory
    data.lifeTimeData_revenue = string.format("%.2f", jsonTable.overview.lifeTimeData.revenue) .." " ..details.currency
  end
  data.lastUpdateTime = jsonTable.overview.lastUpdateTime
  local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
  local runyear, runmonth, runday, runhour, runminute, runseconds = data.lastUpdateTime:match(pattern)
  local convertedTimestamp = os.time({year = runyear, month = runmonth, day = runday, hour = runhour, min = runminute, sec = runseconds})
  data.lastUpdateTime = os.date("%d-%m-%Y %H:%M", convertedTimestamp)
  
  self:valuesCheck() -- Temporarily check of Cloud values
  
end


function QuickApp:valuesDetails() -- Get the values from json file Details
  self:logging(3,"valuesDetails")
  if details.peakPower ~= nil then -- details.peakPower is not mandatory
    details.peakPower = string.format("%.1f", jsonTableDetails.details.peakPower)
  end
  if details.currency ~= nil then -- details.currency is not mandatory
    details.currency = jsonTableDetails.details.currency
  end
end


function QuickApp:simData() -- Simulate SolarEdge Monitor
  self:logging(3,"simData")
  apiResult = '{"overview":{"lastUpdateTime":"2021-08-12 13:46:04","lifeTimeData":{"energy":7827878.0,"revenue":1728.5211},"lastYearData":{"energy":573242.0},"lastMonthData":{"energy":113386.0},"lastDayData":{"energy":7373.0},"currentPower":{"power":134.73499},"measuredBy":"INVERTER"}}' -- With revenue
  --apiResult = '{"overview":{"lastUpdateTime":"2021-08-26 10:58:29","lifeTimeData":{"energy":1.6099509E7},"lastYearData":{"energy":6773922.0},"lastMonthData":{"energy":836428.0},"lastDayData":{"energy":4276.0},"currentPower":{"power":2206.0},"measuredBy":"INVERTER"}}' -- Without revenue
 
  jsonTable = json.decode(apiResult) -- Decode the json string from api to lua-table 
  
  self:valuesOverview()
  self:updateLabels()
  self:updateProperties()

  for id,child in pairs(self.childDevices) do 
    child:updateValue(data,userID) 
  end
  
  self:logging(3,"SetTimeout " ..interval .." seconds")
  fibaro.setTimeout(interval*1000, function() 
     self:simData()
  end)
end


function QuickApp:getData() -- Get the data from the API
  self:logging(3,"getData")
  self:logging(2,"URL Overview: " ..urlOverview)
  http:request(urlOverview, {
    options={headers = {Accept = "application/json"},method = 'GET'},   
      success = function(response)
        self:logging(3,"response status: " ..response.status)
        self:logging(3,"headers: " ..response.headers["Content-Type"])
        self:logging(2,"Response data: " ..response.data)

        if response.data == nil or response.data == "" or response.data == "[]" or response.status > 200 then -- Check for empty result
          self:warning("Temporarily no production data from SolarEdge Monitor")
          return
        end
        
        jsonTable = json.decode(response.data) -- JSON decode from api to lua-table

        self:valuesOverview()
        self:updateLabels()
        self:updateProperties()

        for id,child in pairs(self.childDevices) do 
          child:updateValue(data,userID) 
        end

      end,
      error = function(error)
        self:error("error: " ..json.encode(error))
        self:updateProperty("log", "error: " ..json.encode(error))
      end
    }) 
  
  self:logging(3,"SetTimeout " ..interval .." seconds")
  fibaro.setTimeout(interval*1000, function() 
     self:getData()
  end)
end


function QuickApp:simDetails() -- Simulate Details SolarEdge Monitor
  self:logging(3,"simDetails")
  details.peakPower = "4.5" -- PiekWatt in kWp
  details.currency = "EUR" -- Standard Euro currency
end


function QuickApp:getDetails() -- Get the settings from the API
  self:logging(3,"getDetails")
  self:logging(2,"URL Details: " ..urlDetails)
  http:request(urlDetails, {
    options={headers = {Accept = "application/json"},method = 'GET'},   
      success = function(response)
        self:logging(3,"response status: " ..response.status)
        self:logging(3,"headers: " ..response.headers["Content-Type"])
        self:logging(2,"Response data: " ..response.data)

        if response.data == nil or response.data == "" or response.data == "[]" then -- Check for empty result
          self:warning("Temporarily no details data from SolarEdge Monitor")
          return
        end

        jsonTableDetails = json.decode(response.data) -- JSON decode from api to lua-table

        self:valuesDetails()

      end,
      error = function(error)
        self:error("error: " ..json.encode(error))
        self:updateProperty("log", "error: " ..json.encode(error))
      end
    }) 
end


function QuickApp:createVariables() -- Create all Variables 
  jsonTable = {}
  jsonTableDetails = {}
  details = {}
  details.peakPower = "0"
  details.currency = "EUR"
  data = {}
  data.currentPower = "0"
  data.solarPower = "0" 
  data.lastDayData = "0"
  data.prevlastDayData = "0"
  data.lastMonthData = "0"
  data.lastYearData= "0"
  data.lastYearUnit= "Wh"
  data.lifeTimeData= "0"
  data.lifeTimeUnit= "Wh"
  data.lifeTimeData_revenue = "0"
  data.lastUpdateTime = ""
end


function QuickApp:getQuickAppVariables() -- Get all Quickapp Variables or create them
  local siteID = self:getVariable("siteID")
  local apiKey = self:getVariable("apiKey")
  solarM2 = tonumber(self:getVariable("solarM2"))
  interval = tonumber(self:getVariable("interval")) 
  httpTimeout = tonumber(self:getVariable("httpTimeout")) 
  debugLevel = tonumber(self:getVariable("debugLevel"))

  -- Check existence of the mandatory variables, if not, create them with default values
  if siteID == "" or siteID == nil then
    siteID = "0" -- This siteID is just an example, it is not working 
    self:setVariable("siteID",siteID)
    self:trace("Added QuickApp variable siteID")
  end
 if apiKey == "" or apiKey == nil then
    apiKey = "0" -- This API key is just an example, it is not working
    self:setVariable("apiKey",apiKey)
    self:trace("Added QuickApp variable apiKey")
  end 
  if solarM2 == "" or solarM2 == nil then 
    solarM2 = "0" 
    self:setVariable("solarM2",solarM2)
    self:trace("Added QuickApp variable solarM2")
  end 
  if interval == "" or interval == nil then
    interval = "360" -- The default interval is 6 minutes (360 seconds) 
    self:setVariable("interval",interval)
    self:trace("Added QuickApp variable interval")
    interval = tonumber(interval)
  end
  if httpTimeout == "" or httpTimeout == nil then
    httpTimeout = "5" -- Default http timeout 
    self:setVariable("httpTimeout",httpTimeout)
    self:trace("Added QuickApp variable httpTimeout")
    httpTimeout = tonumber(httpTimeout)
  end 
  if debugLevel == "" or debugLevel == nil then
    debugLevel = "1" -- Default debug level
    self:setVariable("debugLevel",debugLevel)
    self:trace("Added QuickApp variable debugLevel")
    debugLevel = tonumber(debugLevel)
  end
  if apiKey == nil or apiKey == ""  or apiKey == "0" then -- Check mandatory apiKey 
    self:error("API key is empty! Get your API key from your installer and copy the apiKey to the quickapp variable")
    self:warning("No API Key: Switched to Simulation Mode")
    debugLevel = 4 -- Simulation mode due to empty apiKey
  end
  if siteID == nil or siteID == ""  or siteID == "0" then -- Check mandatory siteID   
    self:error("Site ID is empty! Get your siteID key from your inverter and copy the siteID to the quickapp variable")
    self:warning("No siteID: Switched to Simulation Mode")
    debugLevel = 4 -- Simulation mode due to empty siteID 
  end
  
  urlOverview = "https://monitoringapi.solaredge.com/site/"..siteID .."/overview.json?api_key="..apiKey
  urlDetails = "https://monitoringapi.solaredge.com/site/"..siteID .."/details?api_key="..apiKey
end


function QuickApp:setupChildDevices()
  local cdevs = api.get("/devices?parentId="..self.id) or {} -- Pick up all Child Devices
  function self:initChildDevices() end -- Null function, else Fibaro calls it after onInit()...

  if #cdevs == 0 then -- If no Child Devices, create them
      local initChildData = { 
        {className="solarPower", name="Solar Power", type="com.fibaro.powerSensor", value=0},
        {className="lastDayData", name="Last day", type="com.fibaro.energyMeter", value=0},
        {className="lastMonthData", name="Last month", type="com.fibaro.multilevelSensor", value=0},
        {className="lastYearData", name="Last year", type="com.fibaro.multilevelSensor", value=0},
        {className="lifeTimeData", name="Lifetime", type="com.fibaro.multilevelSensor", value=0},
      }
    for _,c in ipairs(initChildData) do
      local child = self:createChildDevice(
        {name = c.name,
          type=c.type,
          value=c.value,
          unit=c.unit,
          initialInterfaces = {},
        },
        _G[c.className] -- Fetch class constructor from class name
      )
      child:setVariable("className",c.className)  -- Save class name so we know when we load it next time
    end   
  else 
    for _,child in ipairs(cdevs) do
      local className = getChildVariable(child,"className") -- Fetch child class name
      local childObject = _G[className](child) -- Create child object from the constructor name
      self.childDevices[child.id]=childObject
      childObject.parent = self -- Setup parent link to device controller 
    end
  end
end


function QuickApp:onInit()
  __TAG = fibaro.getName(plugin.mainDeviceId) .." ID:" ..plugin.mainDeviceId
  self:debug("onInit") 
  
  self:setupChildDevices()
  
  if not api.get("/devices/"..self.id).enabled then
    self:warning("Device", fibaro.getName(plugin.mainDeviceId), "is disabled")
    return
  end
  
  self:getQuickAppVariables() 
  self:createVariables()
  
  http = net.HTTPClient({timeout=httpTimeout*1000})
  
  
  if tonumber(debugLevel) >= 4 then 
    self:simDetails() -- Set settings to standard values
    self:simData() -- Go in simulation
  else
    self:getDetails() -- Get settings from SolarEdge Monitor
    self:getData() -- Get data from SolarEdge Monitor
  end
end

-- EOF 
