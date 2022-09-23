-- QUICKAPP Autarco Monitor

-- This QuickApp monitors your Autarco Solar Panels
-- The QuickApp has (child) devices for Solar Power, Energy generated today, Energy generated this month, and Energy generated to date.
-- The Solar Production values are only requested from the Autarco API between sunrise and sunset
-- The QuickApp also shows the Autarco Installation details in the labels
-- The settings for Peak Power and Currency are retrieved from the inverter
-- The rateType interface of Child device Last Day is automatically set to "production" and values from this child devices can be used for the Energy Panel
-- The readings for lastyear and lifetime energy are automatically set to the right Wh unit (Wh, kWh, MWh or GWh)
class 'solarPower'(QuickAppChild)
function solarPower:__init(dev)
  QuickAppChild.__init(self,dev)
end
function solarPower:updateValue(data)
  self:updateProperty("value", tonumber(data.solarPower))
  self:updateProperty("unit", "Watt")
end

class 'currentDayData'(QuickAppChild)
function currentDayData:__init(dev)
  QuickAppChild.__init(self,dev)
  --self:trace("Retrieved value from currentDayData: " ..self.properties.value)
  data.prevcurrentDayData = string.format("%.1f", self.properties.value) -- Initialize prevcurrentDayData with value of child device
  if fibaro.getValue(self.id, "rateType") ~= "production" then
    self:updateProperty("rateType", "production")
    self:warning("Changed rateType interface of Autarco currentDayData child device (" ..self.id ..") to production")
    if not fibaro.getValue(self.id, "storeEnergyData") then
     self:updateProperty("storeEnergyData", false)
     self:warning("Configured storeEnergyData property of currentDayData child device (" ..self.id ..") to true")
    end
  end
end
function currentDayData:updateValue(data)
  self:updateProperty("value", tonumber(data.currentDayData))
  self:updateProperty("unit", "kWh")
  self:updateProperty("log", "")
end

class 'currentMonthData'(QuickAppChild)
function currentMonthData:__init(dev)
  QuickAppChild.__init(self,dev)
  if fibaro.getValue(self.id, "rateType") ~= "production" then
    self:updateProperty("rateType", "production")
    self:warning("Changed rateType interface of Autarco currentMonthData child device (" .. self.id .. ") to production")
    if not fibaro.getValue(self.id, "storeEnergyData") then
      self:updateProperty("storeEnergyData", false)
      self:warning("Configured storeEnergyData property of currentMonthData child device (" ..self.id ..") to false")
    end
  end
function currentData:updateValue(data)
  self:updateProperty("value", tonumber(data.pvMonth))
  self:updateProperty("unit", "kWh")
  self:updateProperty("log", "")
end


class 'lifeTimeData'(QuickAppChild)
function lifeTimeData:__init(dev)
  QuickAppChild.__init(self,dev)
  if fibaro.getValue(self.id, "rateType") ~= "production" then
    self:updateProperty("rateType", "production")
    self:warning("Changed rateType interface of Autarco lifeTimeData child device (" ..self.id ..") to production")
    if not fibaro.getValue(self.id, "storeEnergyData") then
      self:updateProperty("storeEnergyData", false)
      self:warning("Configured storeEnergyData property of lifeTimeData child device (" ..self.id ..") to false")
    end
  end
end
function lifeTimeData:updateValue(data)
  self:updateProperty("value", tonumber(data.lifeTimeData))
  self:updateProperty("unit", "kWh")
end


local function getChildVariable(child,varName)
  for _,v in ipairs(child.properties.quickAppVariables or {}) do
    if v.name==varName then return v.value end
  end
  return ""
end


-- QuickApp functions


function QuickApp:updateChildDevices()
  for id,child in pairs(self.childDevices) do -- Update Child Devices
    child:updateValue(data)
  end
end


function QuickApp:logging(level,text) -- Logging function for debug
  if tonumber(debugLevel) >= tonumber(level) then
      self:debug(text)
  end
end


function QuickApp:solarPower(power, m2) -- Calculate Solar Power M2
  self:logging(3,"QuickApp:solarPower()")
  if m2 > 0 and power > 0 then
    solarPower = power / m2
  else
    solarPower = 0
  end
  return solarPower
end


function QuickApp:unitCheckWh(measurement) -- Set the measurement and unit to kWh, MWh or GWh
  self:logging(3,"QuickApp:unitCheckWh()")
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


function QuickApp:simData() -- Simulate Autarco Monitor
  self:logging(3,"QuickApp:simData()")
  local jsonTableEnergy = json.decode('{"stats":{"graphs":{"pv_energy":{"154E41209290014":{"2022-09-01":8,"2022-09-02":6,"2022-09-03":7,"2022-09-04":6,"2022-09-05":7,"2022-09-06":7,"2022-09-07":6,"2022-09-08":4,"2022-09-09":3,"2022-09-10":5,"2022-09-11":7,"2022-09-12":6,"2022-09-13":5,"2022-09-14":6,"2022-09-15":3,"2022-09-16":4,"2022-09-17":5,"2022-09-18":1,"2022-09-19":3,"2022-09-20":3,"2022-09-21":5,"2022-09-22":5,"2022-09-23":1,"2022-09-24":0,"2022-09-25":0,"2022-09-26":0,"2022-09-27":0,"2022-09-28":0,"2022-09-29":0,"2022-09-30":0}},"no_comms":[]},"kpis":{"pv_today":1,"pv_month":113,"pv_to_date":2017}}}')
  local jsonTablePower = json.decode('{"dt_config_changed":"2021-11-26T15:34:20+00:00","inverters":{"154E41209290014":{"sn":"154E41209290014","dt_latest_msg":"2022-09-23T09:55:14+00:00","out_ac_power":357,"out_ac_energy_total":2017,"error":null,"grid_turned_off":false,"health":"OK"}},"stats":{"graphs":{"pv_power":{"154E41209290014":{"2022-09-23 00:00:00":0,"2022-09-23 00:15:00":0,"2022-09-23 00:30:00":0,"2022-09-23 00:45:00":0,"2022-09-23 01:00:00":0,"2022-09-23 01:15:00":0,"2022-09-23 01:30:00":0,"2022-09-23 01:45:00":0,"2022-09-23 02:00:00":0,"2022-09-23 02:15:00":0,"2022-09-23 02:30:00":0,"2022-09-23 02:45:00":0,"2022-09-23 03:00:00":0,"2022-09-23 03:15:00":0,"2022-09-23 03:30:00":0,"2022-09-23 03:45:00":0,"2022-09-23 04:00:00":0,"2022-09-23 04:15:00":0,"2022-09-23 04:30:00":0,"2022-09-23 04:45:00":0,"2022-09-23 05:00:00":0,"2022-09-23 05:15:00":0,"2022-09-23 05:30:00":0,"2022-09-23 05:45:00":0,"2022-09-23 06:00:00":0,"2022-09-23 06:15:00":0,"2022-09-23 06:30:00":0,"2022-09-23 06:45:00":0,"2022-09-23 07:00:00":0,"2022-09-23 07:15:00":0,"2022-09-23 07:30:00":0,"2022-09-23 07:45:00":0,"2022-09-23 08:00:00":118,"2022-09-23 08:15:00":117,"2022-09-23 08:30:00":117,"2022-09-23 08:45:00":117,"2022-09-23 09:00:00":117,"2022-09-23 09:15:00":189,"2022-09-23 09:30:00":221,"2022-09-23 09:45:00":206,"2022-09-23 10:00:00":190,"2022-09-23 10:15:00":166,"2022-09-23 10:30:00":158,"2022-09-23 10:45:00":182,"2022-09-23 11:00:00":221,"2022-09-23 11:15:00":237,"2022-09-23 11:30:00":213,"2022-09-23 11:45:00":309}},"no_comms":[]},"kpis":{"pv_now":357}}}')

  self:valuesEnergy(jsonTableEnergy) -- Get the values from Energy, in kWh
  self:valuesPower(jsonTablePower) -- Get the values from Power, in W
  self:updateLabels() -- Update the labels
  self:updateProperties() -- Update the properties
  self:updateChildDevices() -- Update the Child Devices

  self:logging(3,"Timeout " ..interval .." seconds")
  fibaro.setTimeout(interval*1000, function()
     self:simData()
  end)
end


function QuickApp:updateProperties() -- Update the properties
  self:logging(3,"QuickApp:updateProperties()")
  self:updateProperty("value", tonumber(data.currentPower))
  self:updateProperty("power", tonumber(data.currentPower))
  self:updateProperty("unit", "Watt")
  self:updateProperty("log", data.lastUpdateTime)
end


function QuickApp:updateLabels() -- Update the labels
  self:logging(3,"QuickApp:updateLabels()")
  local labelText = ""
  if debugLevel == 4 then
    labelText = labelText .."SIMULATION MODE" .."\n\n"
  end
  labelText = labelText .."Current power: " ..data.currentPower .." Watt" .."\n\n"
  labelText = labelText .."Current day: " ..data.currentDayData .." kWh" .."\n"
  labelText = labelText .."Current month: " ..data.currentMonthData .." kWh" .."\n"
  labelText = labelText .."Lastyear: " ..data.lastYearData .." " ..data.lastYearUnit .."\n"
  labelText = labelText .."Lifetime: " ..data.lifeTimeData .." " ..data.lifeTimeUnit .." (" ..data.lifeTimeData_revenue ..")" .."\n\n"
  labelText = labelText .."Autarco installation: " .."\n"
  labelText = labelText .."Type: " ..data.type .."\n"
  labelText = labelText .."Module: " ..data.manufacturerName .."\n"
  labelText = labelText .."Model: " ..data.modelName .."\n"
  labelText = labelText .."Maximum Power: " ..data.maximumPower .."\n\n"
  labelText = labelText .."Last update: " ..data.lastUpdateTime .."\n"

  self:updateView("label", "text", labelText)
  self:logging(2,labelText)
end


function QuickApp:sunsetCheck() -- Check for sunset and sleep time
  self:logging(3,"QuickApp:sunsetCheck()")
  local sunset = fibaro.getValue(1, "sunsetHour")
  if sunset < os.date("%H:%M") and interval == tonumber(self:getVariable("interval")) then -- Sunset change interval when interval is set regular
    self:logging(3, "Sunset at " ..sunset .." < Current time " ..os.date("%H:%M"))
    local pause = ((2400 - os.date("%H%M")) + (fibaro.getValue(1, "sunriseHour"):gsub(":","")))*60*60/100 - (interval*2) -- Time in seconds minus two interval rounds
    interval = tonumber(string.format("%.0f", pause)) -- Set new interval time in seconds
    self:logging(3,"SET Timeout to " ..interval .." seconds")
  elseif interval ~= tonumber(self:getVariable("interval")) then-- Reset Reset interval to regular
    interval = tonumber(self:getVariable("interval"))
    data.lastUpdateTime = "Paused" -- Change log text main device
    self:logging(3,"RESET Timeout to " ..interval .." seconds")
  else  -- Daytime
    self:logging(3, "Sunset at " ..sunset .." > Current time " ..os.date("%H:%M"))
  end
end


function QuickApp:valuesCheck() -- Check for decreasing Cloud values for currentDayData
  self:logging(3,"QuickApp:valuesCheck()")
  self:logging(3,"Previous currentDayData: " ..data.prevcurrentDayData .. " / Next currentDayData: " ..data.currentDayData)
  if tonumber(data.currentDayData) < tonumber(data.prevcurrentDayData) and tonumber(data.prevcurrentDayData) ~= 0 and tonumber(data.currentDayData) ~= 0 then -- Decreasing value
    self:logging(2,"Decreasing value currentDayData ignored (Energy Panel Child Device), previous value: " ..data.prevcurrentDayData .." next value: " ..data.currentDayData)
    data.currentDayData = string.format("%.1f", data.prevcurrentDayData) -- Restore previous (higher)currentDayData value
  else
    data.prevcurrentDayData = string.format("%.1f", data.currentDayData) -- Save currentDayData to prevcurrentDayData only in case of increasing value
  end
end


function QuickApp:valuesOverview(table) -- Get the values from json file Overview
  self:logging(3,"QuickApp:valuesOverview()")
  local jsonTable = table
  data.currentPower = string.format("%.0f", jsonTableEnergy.stats.kpis.pv_now or "0")
  data.currentDayData = string.format("%.1f",jsonTableEnergy.stats.kpis.pv_today or "0")
  data.currentMonthData = string.format("%.1f",jsonTableEnergy.stats.kpis.pv_month or "0")
  data.lifeTimeData = jsonTableEnergy.stats.kpis.pv_to_date or "0"
  data.lastUpdateTime = jsonTablePower.inverters.154E41209290014.dt_latest_msg or os.date("%d-%m-%Y %H:%M:%S")
end


function QuickApp:valuesEnergy(table) -- Get the values from Energy json API
  self:logging(3,"QuickApp:valuesEnergy()")
  local jsonTableEnergy = table
  data.stats = jsonTableEnergy.stats or {}
end


function QuickApp:getPower() -- Get Production data from the API
  self:logging(3,"QuickApp:getPower()")
  local urlOverview = "https://my.autarco.com/api/m1/site/"..self:getVariable('siteID').."/power"
  self:logging(2,"URL Overview: " ..urlOverview)

  local headers = {}
  headers['Accept'] = "application/json"
  headers['Authorization'] = self:getVariable("Authorization")

  http:request(urlOverview, {
    options={headers = headers, method = 'GET'}, success = function(response)
      self:logging(3,"response status: " ..response.status)
      self:logging(3,"headers: " ..response.headers["Content-Type"])
      self:logging(2,"Response data: " ..response.data)

      if response.data == nil or response.data == "" or response.status > 200 then -- Check for empty result
        self:warning("Temporarily no production data from Autarco Monitor")
        self:logging(1,"response status: " ..response.status)
        self:logging(1,"Response data: " ..response.data)
        fibaro.setTimeout(interval*1000, function()
          return
        end)
      end

      local jsonTable = json.decode(response.data) -- JSON decode from api to lua-table

      self:valuesOverview(jsonTable) -- Get the values from Overview
      self:valuesCheck() -- Check of Cloud decreasing values lastDayData
      if pause then self:sunsetCheck() end -- Check for Sunset to set higher interval or return to origional setting
      self:updateLabels() -- Update the labels
      self:updateProperties() -- Update the properties
      self:updateChildDevices() -- Update the Child Devices

    end,
    error = function(error)
      self:error("error: " ..json.encode(error))
      self:updateProperty("log", "error: " ..json.encode(error))
    end
  })
  self:logging(3,"Timeout " ..interval .." seconds")
  fibaro.setTimeout(interval*1000, function()
    self:getPower() -- Loop
  end)
end


function QuickApp:getEnergy() -- Get the settings from the API
  self:logging(3,"QuickApp:getEnergy()")
  local urlEnergy = "https://my.autarco.com/api/m1/site/"..self:getVariable('siteID').."/power"
  self:logging(2,"URL Energy: " ..urlEnergy)

  local headers = {}
  headers['Accept'] = "application/json"
  headers['Authorization'] = self:getVariable("Authorization")

  http:request(urlEnergy, {
    options={headers = headers,method = 'GET'}, success = function(response)
      self:logging(3,"response status: " ..response.status)
      self:logging(3,"headers: " ..response.headers["Content-Type"])
      self:logging(2,"Response data: " ..response.data)

      if response.data == nil or response.data == "" or response.data == "[]" or response.status > 200 then -- Check for empty result
        self:warning("Temporarily no energy data from Autarco Monitor")
        self:logging(1,"response status: " ..response.status)
        self:logging(1,"Response data: " ..response.data)
        return
      end

      local jsonTableEnergy = json.decode(response.data) -- JSON decode from api to lua-table

      self:valuesEnergy(jsonTableEnergy) -- Get the values from Energy

    end,
    error = function(error)
      self:error("error: " ..json.encode(error))
      self:updateProperty("log", "error: " ..json.encode(error))
    end
  })
end


function QuickApp:createVariables() -- Create all Variables
  data = {}

  data.peakPower = "0"
  data.currency = "EUR"
  data.type = ""
  data.manufacturerName = ""
  data.modelName = ""
  data.maximumPower = ""

  data.units = ""
  data.currentPower = "0"
  data.lastDayData = "0"
  --data.prevlastDayData = "0" -- Is set in Child device class
  data.currentMonthData = "0"
  data.lastYearData= "0"
  data.lastYearUnit= "Wh"
  data.lifeTimeData= "0"
  data.lifeTimeUnit= "kWh"
  data.lastUpdateTime = ""
end


function QuickApp:getQuickAppVariables() -- Get all Quickapp Variables or create them
  local siteID = self:getVariable("siteID")
  local authorization = self:getVariable("Authorization")
  local systemUnits = string.lower(self:getVariable("systemUnits")):gsub("^%l", string.upper)
  solarM2 = tonumber(self:getVariable("solarM2"))
  interval = tonumber(self:getVariable("interval"))
  httpTimeout = tonumber(self:getVariable("httpTimeout"))
  pause = string.lower(self:getVariable("pause"))
  debugLevel = tonumber(self:getVariable("debugLevel"))

  -- Check existence of the mandatory variables, if not, create them with default values
  if siteID == "" or siteID == nil then
    siteID = "0" -- This is just an example, it is not working
    self:setVariable("siteID",siteID)
    self:trace("Added QuickApp variable siteID")
  end
 if authorization == "" or authorization == nil then
    authorization = "Authorization" -- This is just an example, it is not working
    self:setVariable("Authorization",authorization)
    self:trace("Added QuickApp variable Authorization")
  end
 if systemUnits ~= "Metrics" and systemUnits ~= "Imperial" then
    systemUnits = "Metrics" -- Default systemUnits is Metrics (kg)
    self:setVariable("systemUnits",systemUnits)
    self:trace("Added QuickApp variable systemUnits")
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
  if pause == "" or pause == nil then
    pause = "true"
    self:setVariable("pause",pause)
    self:trace("Added QuickApp variable pause")
  end
  if debugLevel == "" or debugLevel == nil then
    debugLevel = "1" -- Default debug level
    self:setVariable("debugLevel",debugLevel)
    self:trace("Added QuickApp variable debugLevel")
    debugLevel = tonumber(debugLevel)
  end
  if siteID == nil or siteID == ""  or siteID == "0" then -- Check mandatory siteID
    self:error("Site ID is empty! Get your siteID key from your inverter and copy the siteID to the quickapp variable")
    self:warning("No siteID: Switched to Simulation Mode")
    debugLevel = 4 -- Simulation mode due to empty siteID
  end
  if authorization == nil or authorization == ""  or authorization == "Authorization" then -- Check mandatory Authorization
    self:error("Authorization is empty! Get your username and password from My Autarco and copy the Base64 encoded version to the quickapp variable")
    self:warning("No Authorization: Switched to Simulation Mode")
    debugLevel = 4 -- Simulation mode due to empty Authorization
  end
  if pause == "true" then
    pause = true
  else
    pause = false
  end
end


function QuickApp:setupChildDevices()
  local cdevs = api.get("/devices?parentId="..self.id) or {} -- Pick up all Child Devices
  function self:initChildDevices() end -- Null function, else Fibaro calls it after onInit()...

  if #cdevs == 0 then -- If no Child Devices, create them
    local initChildData = {
      {className="solarPower", name="Solar Power", type="com.fibaro.powerMeter", value=0},
      {className="lastDayData", name="Last day", type="com.fibaro.energyMeter", value=0},
      {className="currentMonthData", name="Current month", type="com.fibaro.energyMeter", value=0},
      {className="lastYearData", name="Last year", type="com.fibaro.energyMeter", value=0},
      {className="lifeTimeData", name="Lifetime", type="com.fibaro.energyMeter", value=0},
    }
    for _,c in ipairs(initChildData) do
      local child = self:createChildDevice(
        {name = c.name, type=c.type, value=c.value, initialInterfaces = {}, },
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
  self:debug("QuickApp:onInit()")

  self:createVariables() -- Early because of initialise the value for prevlastDayData
  self:setupChildDevices() -- Setup all child devices

  if not api.get("/devices/"..self.id).enabled then
    self:warning("Device", fibaro.getName(plugin.mainDeviceId), "is disabled")
    return
  end

  self:getQuickAppVariables()

  http = net.HTTPClient({timeout=httpTimeout*1000})

  if tonumber(debugLevel) >= 4 then
    self:simData() -- Go in simulation
  else
    self:getEnergy() -- Get settings from Autarco API only at startup
    self:getPower() -- Go to loop getPower()
  end
end

-- EOF
