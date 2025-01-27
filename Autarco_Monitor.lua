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

class 'energyToday'(QuickAppChild)
function energyToday:__init(dev)
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
function energyToday:updateValue(data)
  self:updateProperty("value", tonumber(data.currentDayData))
  self:updateProperty("unit", "kWh")
  self:updateProperty("log", "")
end


class 'energyThisMonth'(QuickAppChild)
function energyThisMonth:__init(dev)
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
function energyThisMonth:updateValue(data)
  self:updateProperty("value", tonumber(data.currentDayData))
  self:updateProperty("unit", "kWh")
  self:updateProperty("log", "")
end

class 'energyToDate'(QuickAppChild)
function energyToDate:__init(dev)
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
function energyToDate:updateValue(data)
  self:updateProperty("value", tonumber(data.currentDayData))
  self:updateProperty("unit", "kWh")
  self:updateProperty("log", "")
end

local function getChildVariable(child,varName)
  for _,v in ipairs(child.properties.quickAppVariables or {}) do
    if v.name==varName then return v.value end
  end
  return ""
end


-- QuickApp functions

-- Update Child Devices
function QuickApp:updateChildDevices()
  for id,child in pairs(self.childDevices) do
    child:updateValue(data)
  end
end

-- Logging function for debug
function QuickApp:logging(level,text)
  if tonumber(self.debugLevel) >= tonumber(level) then
      self:debug(text)
  end
end

-- Set the measurement and unit to kWh, MWh or GWh
function QuickApp:unitCheckWh(measurement)
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

  self:logging(3,"Timeout " ..self.interval .." seconds")
  fibaro.setTimeout(self.interval*1000, function()
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

-- Update the labels
function QuickApp:updateLabels()
  self:logging(3,"QuickApp:updateLabels()")
  local labelText = ""
  if self.debugLevel == 4 then
    labelText = labelText .."SIMULATION MODE" .."\n\n"
  end
  labelText = labelText .."Current power: " ..self.stats.kpis.pv_now .." Watt" .."\n"
  labelText = labelText .. "\n"
  labelText = labelText .."Energy today: " ..self.kpis.pv_today .." kWh" .."\n"
  labelText = labelText .."Energy this month: " ..self.kpis.pv_month .." kWh" .."\n"
  labelText = labelText .."Energy to date: " ..self.kpis.pv_to_date .." kWh" .."\n"
  labelText = labelText .. "\n"
  labelText = labelText .. "Inverters:"

  for inverter in self.inverters do
    labelText = labelText .."Serial number: " ..inverter.sn .."\n"
    labelText = labelText .."Latest message: " ..inverter.dt_latest_msg .."\n"
    labelText = labelText .."Output AC Power: " ..inverter.out_ac_power .."\n"
    labelText = labelText .."Output AC Energy total: " ..inverter.out_ac_energy_total .."\n"
    labelText = labelText .."Error: " ..inverter.error .."\n"
    labelText = labelText .."Grid turned off? " ..inverter.grid_turned_off .."\n"
    labelText = labelText .."Health: " ..inverter.health .."\n"
    labelText = labelText .. "--\n"
  end

  self:updateView("label", "text", labelText)
  self:logging(2,labelText)
end


-- Store the values from power API
function QuickApp:valuesPower(table)
  self:logging(3, "QuickApp:valuesPower()")

  self.dtConfigChanged = table.dt_config_changed
  self.inverters = table.inverters
  self.stats = table.stats

  -- store all inverters into an array
  local index = 1
  self.inverters = {}
  for _,inverter in ipairs(table.inverters) do
    self.inverters[index] = inverter
    index = index + 1
  end
end

-- Store the values from Energy API
function QuickApp:valuesEnergy(table)
  self:logging(3, "QuickApp:valuesEnergy()")

  self.graphs = table.graphs
  self.kpis = table.kpis
end

-- Get Production data from the API
function QuickApp:getPower()
  self:logging(3,"QuickApp:getPower()")
  local urlPower = "https://my.autarco.com/api/m1/site/"..self.siteID.."/power"
  self:logging(2,"URL Power: " ..urlPower)

  self.httpClient:request(urlPower, {
    options = { headers = self.headers, method = 'GET' },
    success = function(response)
      self:logging(3, "response status: " ..response.status)
      self:logging(3, "headers: " ..response.headers["Content-Type"])
      self:logging(2, "Response data: " ..response.data)

      if response.data == nil or response.data == "" or response.status > 200 then -- Check for empty result
        self:warning("Temporarily no production data from Autarco Monitor")
        self:logging(1,"response status: " ..response.status)
        self:logging(1,"Response data: " ..response.data)
        fibaro.setTimeout(self.interval*1000, function()
          return
        end)
      end

      local table = json.decode(response.data) -- JSON decode from api to lua-table

      self:valuesPower(table) -- store the power values
      self:updateLabels() -- Update the labels
      self:updateProperties() -- Update the properties
      self:updateChildDevices() -- Update the Child Devices

    end,
    error = function(error)
      self:error("error: " ..json.encode(error))
      self:updateProperty("log", "error: " ..json.encode(error))
    end
  })
end


function QuickApp:getEnergy() -- Get the settings from the API
  self:logging(3,"QuickApp:getEnergy()")
  local urlEnergy = "https://my.autarco.com/api/m1/site/"..self:getVariable('siteID').."/energy"
  self:logging(2,"URL Energy: " ..urlEnergy)

  self.httpClient:request(urlEnergy, {
    options={headers = headers,method = 'GET'},
    success = function(response)
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

  data.sn = ""
  data.latestMsg = ""
  data.outAcPower = 0
  data.outAcEnergyTotal = 0
  data.error = ""
  data.gridTurnedOff = false
  data.health = ""

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

-- Get all Quickapp Variables or create them
function QuickApp:getQuickAppVariables()
  self.siteID = self:getVariable("siteID") or ""
  self:trace("Added QuickApp variable siteID with value "..self.siteID)
  self.authorization = self:getVariable("authorization") or ""
  self:trace("Added QuickApp variable authorization with value "..self.authorization)
  self.interval = tonumber(self:getVariable("interval")) or 360 -- default 360 seconds (6 minutes)
  self:trace("Added QuickApp variable interval with value "..self.interval)
  self.httpTimeout = tonumber(self:getVariable("httpTimeout")) or 5 -- default 5 seconds
  self:trace("Added QuickApp variable httpTimeout with value "..self.httpTimeout)
  self.debugLevel = tonumber(self:getVariable("debugLevel")) or 1 -- default 1
  self:trace("Added QuickApp variable debugLevel with value "..self.debugLevel)

  self.headers = {Accept="application/json"}

  -- Check mandatory siteID
  if self.siteID == "" then
    self:error("siteID is empty! Get it from My Autarco and add it as a variable")
    self:warning("No siteID: Switched to Simulation Mode")
    self.debugLevel = 4 -- Simulation mode due to empty siteID
  end

  -- Check mandatory Authorization
  if self.authorization == "" then
    self:error("Authorization is empty! Get your username and password from My Autarco, join them with a colon and add the base64 encoded result as a variable")
    self:warning("No authorization: Switched to Simulation Mode")
    self.debugLevel = 4 -- Simulation mode due to empty Authorization
  else
    self.headers.Authorization=self.authorization
  end
end


function QuickApp:setupChildDevices()
  local cdevs = api.get("/devices?parentId="..self.id) or {} -- Pick up all Child Devices
  function self:initChildDevices() end -- Null function, else Fibaro calls it after onInit()...

  if #cdevs == 0 then -- If no Child Devices, create them
    local initChildData = {
      { className="solarPower", name="Solar Power", type="com.fibaro.powerMeter", value=0},
      { className="energyToday", name="Energy today", type="com.fibaro.egeryMeter", value=0},
      { className="energyThisMonth", name="Energy this month", type="com.fibaro.energyMeter", value=0},
      { className="energyToDate", name="Energy to date", type="com.fibaro.energyMeter", value=0}
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

  self.httpClient = net.HTTPClient({timeout=self.httpTimeout*1000})

  if tonumber(self.debugLevel) >= 4 then
    self:simData() -- Go in simulation
  else
    -- Loop
    fibaro.setTimeout(self.interval*1000, function()
      self:getPower()
      self:getEnergy()
    end)
  end
end

-- EOF
