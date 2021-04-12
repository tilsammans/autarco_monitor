-- QUICKAPP SolarEdge Monitor

-- This QuickApp monitors your SolarEdge managed Solar Panels
-- The QuickApp has (child) devices for currentPower, lastDayData, lastMonthData, lastYearData and lifeTimeData
-- See API documentation on https://www.solaredge.com/sites/default/files/se_monitoring_api.pdf 

-- Changes version 0.3 (12th April 2021)
-- Added last update date / time
-- Cleaned up the code

-- Changes version 0.2 (12th April 2021)
-- Disabled revenue value (not for lifeTimeData)

-- Changes version 0.1 (11th April 2021)
-- First (test) version


-- Variables (mandatory): 
-- siteID = ID of your SolarEdge Monitor
-- apiKey = API key of your SolarEdge Monitor
-- valuta = Name of the valuta your saving with solar energy (default = euro)
-- solarM2 = The amount of m2 Solar Panels (use . for decimals) for calculating Solar Power m2 (default = 0)
-- interval = The daily API limitiation is 300 requests. The default request interval is 360 seconds (6 minutes).
-- debugLevel = Number (1=some, 2=few, 3=all, 4=simulation mode) (default = 1)
-- icon = User defined icon number (add the icon via an other device and lookup the number) (default = 0)


-- Example json overview string from API documentation:
-- {"overview": {"lastUpdateTime": "2021-03-01 02:37:47","lifeTimeData": {"energy": 761985.75,"revenue": 946.13104},"lastYearData": {"energy": 761985.8,"revenue": 946.13104},"lastMonthData": {"energy": 492736.7,"revenue": 612.09528},"lastDayData": {"energy": 1327.3,"revenue": 1.64844},"currentPower": {"power": 304.8}}}

-- Example json overview string from SolarEdge response:
-- {"overview":{"lastUpdateTime":"2021-04-12 13:46:04","lifeTimeData":{"energy":7827878.0,"revenue":1728.5211},"lastYearData":{"energy":573242.0},"lastMonthData":{"energy":113386.0},"lastDayData":{"energy":7373.0},"currentPower":{"power":134.73499},"measuredBy":"INVERTER"}}


-- No editing of this code is needed 


class 'currentPower'(QuickAppChild)
function currentPower:__init(dev)
  QuickAppChild.__init(self,dev)
  --self:trace("currentPower QuickappChild initiated, deviceId:",self.id)
end
function currentPower:updateValue(data) 
  self:updateProperty("value", tonumber(data.currentPower))
  self:updateProperty("unit", "Watt")
  self:updateProperty("log", data.lastUpdateTime)
end

class 'solarPower'(QuickAppChild)
function solarPower:__init(dev)
  QuickAppChild.__init(self,dev)
  --self:trace("solarPower QuickappChild initiated, deviceId:",self.id)
end
function solarPower:updateValue(data) 
  self:updateProperty("value", tonumber(data.solarPower))
  self:updateProperty("unit", "Watt/m²")
  self:updateProperty("log", "")
end


class 'lastDayData'(QuickAppChild)
function lastDayData:__init(dev)
  QuickAppChild.__init(self,dev)
  --self:trace("lastDayData QuickappChild initiated, deviceId:",self.id)
end
function lastDayData:updateValue(data) 
  self:updateProperty("value", tonumber(data.lastDayData))
  self:updateProperty("unit", "kWh")
  self:updateProperty("log", "")
end

class 'lastMonthData'(QuickAppChild)
function lastMonthData:__init(dev)
  QuickAppChild.__init(self,dev)
  --self:trace("lastMonthData QuickappChild initiated, deviceId:",self.id)
end
function lastMonthData:updateValue(data) 
  self:updateProperty("value", tonumber(data.lastMonthData))
  self:updateProperty("unit", "kWh")
  self:updateProperty("log", "")
end

class 'lastYearData'(QuickAppChild)
function lastYearData:__init(dev)
  QuickAppChild.__init(self,dev)
  --self:trace("lastYearData QuickappChild initiated, deviceId:",self.id)
end
function lastYearData:updateValue(data) 
  self:updateProperty("value", tonumber(data.lastYearData))
  self:updateProperty("unit", "kWh")
  self:updateProperty("log", "")
end

class 'lifeTimeData'(QuickAppChild)
function lifeTimeData:__init(dev)
  QuickAppChild.__init(self,dev)
  --self:trace("lifeTimeData QuickappChild initiated, deviceId:",self.id)
end
function lifeTimeData:updateValue(data) 
  self:updateProperty("value", tonumber(data.lifeTimeData))
  self:updateProperty("unit", "kWh")
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


function QuickApp:updateProperties() -- Update the properties
  self:logging(3,"updateProperties")
  self:updateProperty("value", tonumber(data.currentPower))
  self:updateProperty("unit", "Watt")
  self:updateProperty("log", "")
end


function QuickApp:updateLabels() -- Update the labels
  self:logging(3,"updateLabels")
  local labelText = ""
  labelText = labelText .."Current power: " ..data.currentPower .." Watt " .."\n\n"
  labelText = labelText .."Solar power: " ..data.solarPower .." Watt/m²" .."\n"
  labelText = labelText .."Lastday: " ..data.lastDayData .." kWh" .."\n"
  labelText = labelText .."Lastmonth: " ..data.lastMonthData .." kWh" .."\n"
  labelText = labelText .."Lastyear: " ..data.lastYearData .." kWh" .."\n"
  labelText = labelText .."Lifetime: " ..data.lifeTimeData .." kWh (" ..data.lifeTimeData_revenue ..")" .."\n\n"
  labelText = labelText .."Last update: " ..data.lastUpdateTime .."\n" 
  self:updateView("label1", "text", labelText)
  self:logging(2,labelText)
end


function QuickApp:valuesOverview() -- Get the values from json file Overview
  self:logging(3,"valuesOverview")
  data.currentPower = string.format("%.0f", jsonTable.overview.currentPower.power)
  data.lastDayData = string.format("%.2f", tonumber(jsonTable.overview.lastDayData.energy/1000))
  data.lastMonthData = string.format("%.2f", tonumber(jsonTable.overview.lastMonthData.energy/1000))
  data.lastYearData = string.format("%.2f", tonumber(jsonTable.overview.lastYearData.energy/1000))
  data.lifeTimeData = string.format("%.2f", tonumber(jsonTable.overview.lifeTimeData.energy/1000))
  data.lifeTimeData_revenue = string.format("%.2f", jsonTable.overview.lifeTimeData.revenue) .." " ..valuta
  data.lastUpdateTime = jsonTable.overview.lastUpdateTime
  data.solarPower = string.format("%.2f",self:solarPower(tonumber(data.currentPower), tonumber(solarM2)))
end


function QuickApp:simData() -- Simulate SolarEdge Monitor
  self:logging(3,"Simulation mode")
  apiResult = '{"overview":{"lastUpdateTime":"2021-04-12 13:46:04","lifeTimeData":{"energy":7827878.0,"revenue":1728.5211},"lastYearData":{"energy":573242.0},"lastMonthData":{"energy":113386.0},"lastDayData":{"energy":7373.0},"currentPower":{"power":134.73499},"measuredBy":"INVERTER"}}'
 
  jsonTable = json.decode(apiResult) -- Decode the json string from api to lua-table 
  
  self:valuesOverview()
  self:updateLabels()
  self:updateProperties()

  for id,child in pairs(self.childDevices) do 
    child:updateValue(data,userID) 
  end
  
  self:logging(3,"SetTimeout " ..interval .." seconds")
  fibaro.setTimeout(interval*1000, function() 
     self:getData()
  end)
end


function QuickApp:getData()
  self:logging(3,"getData")
  self:logging(2,"URL: " ..url)
  http:request(url, {
    options={headers = {Accept = "application/json"},method = 'GET'},   
      success = function(response)
        self:logging(3,"response status: " ..response.status)
        self:logging(3,"headers: " ..response.headers["Content-Type"])
        self:logging(2,"Response data: " ..response.data)

        if response.data == nil or response.data == "" or response.data == "[]" then -- Check for empty result
          self:warning("Temporarily no data from SolarEdge Monitor")
          self:logging(3,"SetTimeout " ..interval .." seconds")
          fibaro.setTimeout(interval*1000, function() 
            self:getdata()
          end)
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


function QuickApp:createVariables() -- Create all Variables 
  jsonTable = {}
  data = {}
  data.currentPower = "0"
  data.solarPower = "0" 
  data.lastDayData = "0"
  data.lastMonthData = "0"
  data.lastYearData= "0"
  data.lifeTimeData= "0"
  data.lifeTimeData_revenue = "0"
  data.lastUpdateTime = ""
end


function QuickApp:getQuickAppVariables() -- Get all Quickapp Variables or create them
  local siteID = self:getVariable("siteID")
  local apiKey = self:getVariable("apiKey")
  valuta = self:getVariable("valuta")
  solarM2 = tonumber(self:getVariable("solarM2"))
  interval = tonumber(self:getVariable("interval")) 
  httpTimeout = tonumber(self:getVariable("httpTimeout")) 
  debugLevel = tonumber(self:getVariable("debugLevel"))
  local icon = tonumber(self:getVariable("icon")) 

  -- Check existence of the mandatory variables, if not, create them with default values
  if siteID == "" or siteID == nil then
    siteID = "1" 
    self:setVariable("siteID",siteID)
    self:trace("Added QuickApp variable siteID")
  end
 if apiKey == "" or apiKey == nil then
    apiKey = "L4QLVQ1LOKCQX2193VSEICXW61NP6B1O" -- This API key is just an example, it is not working
    self:setVariable("apiKey",apiKey)
    self:trace("Added QuickApp variable apiKey")
  end 
  if valuta == "" or valuta == nil then
    valuta = "euro" 
    self:setVariable("valuta",valuta)
    self:trace("Added QuickApp variable valuta")
  end  
  if solarM2 == "" or solarM2 == nil then 
    solarM2 = "0" 
    self:setVariable("solarM2",solarM2)
    self:trace("Added QuickApp variable solarM2")
  end 
  if interval == "" or interval == nil then
    interval = "360" 
    self:setVariable("interval",interval)
    self:trace("Added QuickApp variable interval")
    interval = tonumber(interval)
  end
  if httpTimeout == "" or httpTimeout == nil then
    httpTimeout = "5" 
    self:setVariable("httpTimeout",httpTimeout)
    self:trace("Added QuickApp variable httpTimeout")
    httpTimeout = tonumber(httpTimeout)
  end 
  if debugLevel == "" or debugLevel == nil then
    debugLevel = "1" 
    self:setVariable("debugLevel",debugLevel)
    self:trace("Added QuickApp variable debugLevel")
    debugLevel = tonumber(debugLevel)
  end
  if icon == "" or icon == nil then 
    icon = "0"
    self:setVariable("icon",icon)
    self:trace("Added QuickApp variable icon")
    icon = tonumber(icon)
  end
  if icon ~= 0 then 
    self:updateProperty("deviceIcon", icon) -- set user defined icon 
  end
  url = "https://monitoringapi.solaredge.com/site/"..siteID .."/overview.json?api_key="..apiKey
end


function QuickApp:setupChildDevices()
  local cdevs = api.get("/devices?parentId="..self.id) or {} -- Pick up all Child Devices
  function self:initChildDevices() end -- Null function, else Fibaro calls it after onInit()...

  if #cdevs == 0 then -- If no Child Devices, create them
      local initChildData = { 
        {className="currentPower", name="Current Power", type="com.fibaro.multilevelSensor", value=0},
        {className="solarPower", name="Solar Power", type="com.fibaro.multilevelSensor", value=0},
        {className="lastDayData", name="Lastday", type="com.fibaro.multilevelSensor", value=0},
        {className="lastMonthData", name="Lastmonth", type="com.fibaro.multilevelSensor", value=0},
        {className="lastYearData", name="Lastyear", type="com.fibaro.multilevelSensor", value=0},
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
  self:getQuickAppVariables() 
  self:createVariables()
  
  http = net.HTTPClient({timeout=httpTimeout*1000})
  
  if tonumber(debugLevel) >= 4 then 
    self:simData() -- Go in simulation
  else
    self:getData() -- Get data from SolarEdge Monitor
  end
end

-- EOF 