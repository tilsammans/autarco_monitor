-- QUICKAPP SolarEdge Monitor

-- This QuickApp monitors your SolarEdge managed Solar Panels
-- The QuickApp has (child) devices for Solar Power, Lastday Data, Lastmonth Data, Lastyear Data and Lifetime Data
-- The Solar Production values are only requested from the SolarEdge Cloud between sunrise and sunset
-- The QuickApp also shows the Environmental Benefits in the labels for CO2, SO2, NOX, Trees planted and Lightbulbs
-- The QuickApp also shows the SolarEdge Installation details in the labels
-- The Environmental Benefits are updated once a day after 12:00 hour
-- The settings for Peak Power and Currency are retrieved from the inverter 
-- The rateType interface of Child device Last Day is automatically set to "production" and values from this child devices can be used for the Energy Panel 
-- The readings for lastyear and lifetime energy are automatically set to the right Wh unit (Wh, kWh, MWh or GWh) 
-- See API documentation on https://www.solaredge.com/sites/default/files/se_monitoring_api.pdf 


-- Changes version 2.0 (26th Match 2022)
-- All *meter device types can now be shown in the Yubii app so: 
   -- Changed main device SolarEdge Monitor to device type com.fibaro.powerMeter
   -- Changed child device solarPower to device type com.fibaro.powerMeter
   -- Changed child devices lastDayData, lastMonthData, lastYearData and lifeTimeData to com.fibaro.energyMeter
   -- Configured storeEnergyData property of lastDayData, lastMonthData, lastYearData and lifeTimeData to com.fibaro.energyMeter to false
   -- Configured storeEnergyData property of main device SolarEdge Monitor to true
-- Added "pause" mode during sunset and sunrise. During this time NO requests will be send to the Cloud (because there is no solar production during that time). This saves on the ratelimit of 300 requests a day. 
-- Added Environmental Benefits to the labels, with an update once a day
-- Added new QuickApp Variable systemUnits Metrics (kg) or Imperial (lb) for Environmental Benefits
-- Added SolarEdge Installation details to the labels
-- Added extra timeout and debug logging in case of a bad response 
-- Optimized some code


-- Changes version 1.5 (5th March 2022)
-- Improved the handling of decreasing values

-- Changes version 1.4 (22nd February 2022)
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


-- Variables (mandatory and created automatically): 
-- siteID = Site ID of your SolarEdge Inverter (see your Inverter Site Details)
-- apiKey = API key of your SolarEdge Inverter (contact your installer if you don't have one)
-- systemUnits = SystemUnits is Metrics (kg) or Imperial (Lb) (default is Metrics)
-- solarM2 = The amount of m2 Solar Panels (use . for decimals) for calculating Solar Power m2 (default = 0)
-- interval = The daily API limitation is 300 requests. The default request interval is 360 seconds (6 minutes)
-- pause = Should the SolardEdge go in pause mode after sunset (default = true)
-- debugLevel = Number (1=some, 2=few, 3=all, 4=simulation mode) (default = 1)


-- No editing of this code is needed 


class 'solarPower'(QuickAppChild)
function solarPower:__init(dev)
  QuickAppChild.__init(self,dev)
end
function solarPower:updateValue(data) 
  self:updateProperty("value", tonumber(data.solarPower))
  self:updateProperty("unit", "Watt/m²")
  self:updateProperty("log", data.peakPower .." kWp / " ..solarM2 .." m²")
end

class 'lastDayData'(QuickAppChild)
function lastDayData:__init(dev)
  QuickAppChild.__init(self,dev) 
  --self:trace("Retrieved value from lastDayData: " ..self.properties.value) 
  data.prevlastDayData = string.format("%.1f", self.properties.value) -- Initialize prevlastDayData with value of child device
  if fibaro.getValue(self.id, "rateType") ~= "production" then 
    self:updateProperty("rateType", "production")
    self:warning("Changed rateType interface of SolarEdge lastDayData child device (" ..self.id ..") to production")
    if not fibaro.getValue(self.id, "storeEnergyData") then
     self:updateProperty("storeEnergyData", false)
     self:warning("Configured storeEnergyData property of lastDayData child device (" ..self.id ..") to true")
    end
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
  if fibaro.getValue(self.id, "rateType") ~= "production" then 
    self:updateProperty("rateType", "production")
    self:warning("Changed rateType interface of SolarEdge lastMonthData child device (" ..self.id ..") to production")
    if not fibaro.getValue(self.id, "storeEnergyData") then
      self:updateProperty("storeEnergyData", false)
      self:warning("Configured storeEnergyData property of lastMonthData child device (" ..self.id ..") to false")
    end
  end
end
function lastMonthData:updateValue(data) 
  self:updateProperty("value", tonumber(data.lastMonthData))
  self:updateProperty("unit", "kWh")
  self:updateProperty("log", "")
end

class 'lastYearData'(QuickAppChild)
function lastYearData:__init(dev)
  QuickAppChild.__init(self,dev)
  if fibaro.getValue(self.id, "rateType") ~= "production" then 
    self:updateProperty("rateType", "production")
    self:warning("Changed rateType interface of SolarEdge lastYearData child device (" ..self.id ..") to production")
    if not fibaro.getValue(self.id, "storeEnergyData") then
      self:updateProperty("storeEnergyData", false)
      self:warning("Configured storeEnergyData property of lastYearData child device (" ..self.id ..") to false")
    end
  end
end
function lastYearData:updateValue(data) 
  self:updateProperty("value", tonumber(data.lastYearData))
  self:updateProperty("unit", data.lastYearUnit)
  self:updateProperty("log", "")
end

class 'lifeTimeData'(QuickAppChild)
function lifeTimeData:__init(dev)
  QuickAppChild.__init(self,dev)
  if fibaro.getValue(self.id, "rateType") ~= "production" then 
    self:updateProperty("rateType", "production")
    self:warning("Changed rateType interface of SolarEdge lifeTimeData child device (" ..self.id ..") to production")
    if not fibaro.getValue(self.id, "storeEnergyData") then
      self:updateProperty("storeEnergyData", false)
      self:warning("Configured storeEnergyData property of lifeTimeData child device (" ..self.id ..") to false")
    end
  end
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


function QuickApp:simData() -- Simulate SolarEdge Monitor
  self:logging(3,"QuickApp:simData()")
  local jsonTableDetails = json.decode('{"details":{"id":1234567, "name":"NAME-INSTALLATION", "accountId":123456, "status":"Active", "peakPower":6.8, "lastUpdateTime":"2022-02-01", "currency":"EUR", "installationDate":"2021-02-01", "ptoDate":null, "notes":"", "type":"Optimizers&Inverters", "location":{"country":"Earth", "city":"SimCity", "address":"Street1", "address2":"", "zip":"1234AA", "timeZone":"Europe/Amsterdam", "countryCode":"EU"}, "primaryModule":{"manufacturerName":"LG", "modelName":"LG340", "maximumPower":340}, "uris":{"DETAILS":"/site/1234567/details", "DATA_PERIOD":"/site/1234567/dataPeriod", "OVERVIEW":"/site/1234567/overview"}, "publicSettings":{"isPublic":false}}}')
  local jsonTableEnvBenefits = json.decode('{"envBenefits": { "gasEmissionSaved": {"units": "kg", "co2": 674.93066, "so2": 874.65515,"nox": 278.92545 }, "treesPlanted": 2.2555082200000003, "lightBulbs": 5217.4604 }}') -- Metrics response
  -- local jsonTableEnvBenefits = json.decode('{"envBenefits": { "gasEmissionSaved": {"units": "lb", "co2": 1486.63, "so2": 1926.55, "nox": 614.37 }, "treesPlanted": 2.2555082200000003, "lightBulbs": 5217.4604 }}') -- Imperial response
  local jsonTable = json.decode('{"overview":{"lastUpdateTime":"2021-08-12 13:46:04","lifeTimeData":{"energy":7827878.0,"revenue":1728.5211},"lastYearData":{"energy":573242.0},"lastMonthData":{"energy":113386.0},"lastDayData":{"energy":7373.0},"currentPower":{"power":134.73499},"measuredBy":"INVERTER"}}') -- With revenue

  self:valuesDetails(jsonTableDetails) -- Get the values from Details
  self:valuesEnvBenefits(jsonTableEnvBenefits) -- Get the values from EnvBenefits
  self:valuesOverview(jsonTable) -- Get the values from Overview
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
  labelText = labelText .."Peakpower: " ..data.peakPower .." kWp" .."\n"
  labelText = labelText .."Solar power: " ..data.solarPower .." Watt/m² (" ..solarM2 .." m²)" .."\n"
  labelText = labelText .."Lastday: " ..data.lastDayData .." kWh" .."\n"
  labelText = labelText .."Lastmonth: " ..data.lastMonthData .." kWh" .."\n"
  labelText = labelText .."Lastyear: " ..data.lastYearData .." " ..data.lastYearUnit .."\n"
  labelText = labelText .."Lifetime: " ..data.lifeTimeData .." " ..data.lifeTimeUnit .." (" ..data.lifeTimeData_revenue ..")" .."\n\n"
  labelText = labelText .."Environmental Benefits:" .."\n"
  labelText = labelText .."CO2: " ..data.co2 .." " ..data.units .."\n"
  labelText = labelText .."SO2: " ..data.so2 .." " ..data.units .."\n"
  labelText = labelText .."NOX: " ..data.nox .." " ..data.units .."\n"
  labelText = labelText .."Trees planted: " ..data.treesPlanted .."\n"
  labelText = labelText .."Lightbulbs: " ..data.lightBulbs .."\n\n"
  labelText = labelText .."SolarEdge installation: " .."\n"
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


function QuickApp:valuesCheck() -- Check for decreasing Cloud values for lastDayData
  self:logging(3,"QuickApp:valuesCheck()")
  self:logging(3,"Previous lastDayData: " ..data.prevlastDayData .. " / Next lastDayData: " ..data.lastDayData)
  if tonumber(data.lastDayData) < tonumber(data.prevlastDayData) and tonumber(data.prevlastDayData) ~= 0 and tonumber(data.lastDayData) ~= 0 then -- Decreasing value
    self:logging(2,"Decreasing value lastDayData ignored (Energy Panel Child Device), previous value: " ..data.prevlastDayData .." next value: " ..data.lastDayData)
    data.lastDayData = string.format("%.1f", data.prevlastDayData) -- Restore previous (higher) lastDayData value
  else
    data.prevlastDayData = string.format("%.1f", data.lastDayData) -- Save lastDayData to prevlastDayData only in case of increasing value
  end
end


function QuickApp:valuesEnvBenefits(table) --Get the values from json file Environmental Benefits
  self:logging(3,"QuickApp:valuesEnvBenefits()")
  local jsonTableEnvBenefits = table
  data.units = jsonTableEnvBenefits.envBenefits.gasEmissionSaved.units or "kg"
  data.co2 = string.format("%.0f", jsonTableEnvBenefits.envBenefits.gasEmissionSaved.co2 or "0") 
  data.so2 = string.format("%.0f", jsonTableEnvBenefits.envBenefits.gasEmissionSaved.so2 or "0") 
  data.nox = string.format("%.0f", jsonTableEnvBenefits.envBenefits.gasEmissionSaved.nox or "0") 
  data.treesPlanted = string.format("%.0f", jsonTableEnvBenefits.envBenefits.treesPlanted or "0") 
  data.lightBulbs = string.format("%.0f", jsonTableEnvBenefits.envBenefits.lightBulbs or "0") 
end


function QuickApp:valuesOverview(table) -- Get the values from json file Overview
  self:logging(3,"QuickApp:valuesOverview()")
  local jsonTable = table
  data.currentPower = string.format("%.0f", jsonTable.overview.currentPower.power or "0")
  data.solarPower = string.format("%.1f",self:solarPower(tonumber(data.currentPower), tonumber(solarM2)))
  data.lastDayData = string.format("%.1f",jsonTable.overview.lastDayData.energy or "0"/1000)
  data.lastMonthData = string.format("%.1f",jsonTable.overview.lastMonthData.energy or "0"/1000)
  data.lastYearData = jsonTable.overview.lastYearData.energy or "0"
  data.lastYearData, data.lastYearUnit = self:unitCheckWh(tonumber(data.lastYearData)) -- Set measurement and unit to kWh, MWh or GWh
  data.lifeTimeData = jsonTable.overview.lifeTimeData.energy or "0"
  data.lifeTimeData, data.lifeTimeUnit = self:unitCheckWh(tonumber(data.lifeTimeData)) -- Set measurement and unit to kWh, MWh or GWh
  data.lifeTimeData_revenue = string.format("%.2f", jsonTable.overview.lifeTimeData.revenue or "0.00") .." " ..data.currency -- lifeTimeData_revenue is not mandatory
  data.lastUpdateTime = jsonTable.overview.lastUpdateTime or os.date("%d-%m-%Y %H:%M")
  local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
  local runyear, runmonth, runday, runhour, runminute, runseconds = data.lastUpdateTime:match(pattern)
  local convertedTimestamp = os.time({year = runyear, month = runmonth, day = runday, hour = runhour, min = runminute, sec = runseconds})
  data.lastUpdateTime = os.date("%d-%m-%Y %H:%M", convertedTimestamp)
end


function QuickApp:valuesDetails(table) -- Get the values from json file Details
  self:logging(3,"QuickApp:valuesDetails()")
  local jsonTableDetails = table
  data.peakPower = string.format("%.1f", jsonTableDetails.details.peakPower or "0")
  data.currency = jsonTableDetails.details.currency or "EUR"
  data.type = jsonTableDetails.details.type or ""
  data.manufacturerName = jsonTableDetails.details.primaryModule.manufacturerName or ""
  data.modelName = jsonTableDetails.details.primaryModule.modelName or ""
  data.maximumPower = string.format("%.0f", jsonTableDetails.details.primaryModule.maximumPower or "0")
end


function QuickApp:getEnvBenefits() -- Get Environmental Benefits from the API
  self:logging(3,"QuickApp:getEnvBenefits()")
  local urlEnvBenefits = "https://monitoringapi.solaredge.com/site/"..self:getVariable('siteID').."/envBenefits?systemUnits="..string.lower(self:getVariable('systemUnits')):gsub("^%l", string.upper).."&api_key="..self:getVariable('apiKey')
  self:logging(2,"URL EnvBenefits: " ..urlEnvBenefits)

  http:request(urlEnvBenefits, {
    options={headers = {Accept = "application/json"},method = 'GET'}, success = function(response)
      self:logging(3,"response status: " ..response.status)
      self:logging(3,"headers: " ..response.headers["Content-Type"])
      self:logging(2,"Response data: " ..response.data)

      if response.data == nil or response.data == "" or response.data == "[]" or response.status > 200 then -- Check for empty result
        self:warning("Temporarily no Environmental Benefits data from SolarEdge Monitor")
        self:logging(1,"response status: " ..response.status)
        self:logging(1,"Response data: " ..response.data)
        return
      end

      local jsonTableEnvBenefits = json.decode(response.data) -- JSON decode from api to lua-table

      self:valuesEnvBenefits(jsonTableEnvBenefits) -- Get the values from EnvBenefits

    end,
    error = function(error)
      self:error("error: " ..json.encode(error))
      self:updateProperty("log", "error: " ..json.encode(error))
    end
  }) 
end


function QuickApp:getData() -- Get Production data from the API
  self:logging(3,"QuickApp:getData()")
  local urlOverview = "https://monitoringapi.solaredge.com/site/"..self:getVariable('siteID').."/overview.json?api_key="..self:getVariable('apiKey')
  self:logging(2,"URL Overview: " ..urlOverview)

  http:request(urlOverview, {
    options={headers = {Accept = "application/json"},method = 'GET'}, success = function(response)
      self:logging(3,"response status: " ..response.status)
      self:logging(3,"headers: " ..response.headers["Content-Type"])
      self:logging(2,"Response data: " ..response.data)

      if response.data == nil or response.data == "" or response.data == "[]" or response.status > 200 then -- Check for empty result
        self:warning("Temporarily no production data from SolarEdge Monitor")
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
    self:logging(3,"EnvBenefits countdown: " ..tonumber(os.date("%H%M"))-1200 .." < " ..interval/60 .." and >= 0")
    if tonumber(os.date("%H%M"))-1200 >= 0 and tonumber(os.date("%H%M"))-1200 < (interval/60) then -- Get Environmental Benefits data once every day after 12:00 hour
      self:logging(2,"Get EnvBenefits at " ..os.date("%d-%m-%Y %H:%M"))
      self:getEnvBenefits() -- Get Environmental Benefits data from SolarEdge Cloud
    end
    self:getData() -- Loop
  end)
end


function QuickApp:getDetails() -- Get the settings from the API
  self:logging(3,"QuickApp:getDetails()")
  local urlDetails = "https://monitoringapi.solaredge.com/site/"..self:getVariable('siteID').."/details?api_key="..self:getVariable('apiKey')
  self:logging(2,"URL Details: " ..urlDetails)
  http:request(urlDetails, {
    options={headers = {Accept = "application/json"},method = 'GET'}, success = function(response)
      self:logging(3,"response status: " ..response.status)
      self:logging(3,"headers: " ..response.headers["Content-Type"])
      self:logging(2,"Response data: " ..response.data)

      if response.data == nil or response.data == "" or response.data == "[]" or response.status > 200 then -- Check for empty result
        self:warning("Temporarily no details data from SolarEdge Monitor")
        self:logging(1,"response status: " ..response.status)
        self:logging(1,"Response data: " ..response.data)
        return
      end

      local jsonTableDetails = json.decode(response.data) -- JSON decode from api to lua-table

      self:valuesDetails(jsonTableDetails) -- Get the values from Details

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
  data.co2 = "0"
  data.so2 = "0"
  data.nox = "0"
  data.treesPlanted = "0"
  data.lightBulbs = "0"

  data.currentPower = "0"
  data.solarPower = "0" 
  data.lastDayData = "0"
  --data.prevlastDayData = "0" -- Is set in Child device class
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
  local systemUnits = string.lower(self:getVariable("systemUnits")):gsub("^%l", string.upper)
  solarM2 = tonumber(self:getVariable("solarM2"))
  interval = tonumber(self:getVariable("interval")) 
  httpTimeout = tonumber(self:getVariable("httpTimeout")) 
  pause = string.lower(self:getVariable("pause"))
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
      {className="lastMonthData", name="Last month", type="com.fibaro.energyMeter", value=0},
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
    self:getDetails() -- Get settings from SolarEdge Monitor from SolarEdge Cloud only at startup
    self:getEnvBenefits() -- Get Environmental Benefits initial data from SolarEdge Cloud
    self:getData() -- Go to loop getData()
  end
end

-- EOF  
