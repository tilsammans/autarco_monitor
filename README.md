# SolarEdge_Monitor
This QuickApp (for the Fibaro Homecenter 3) monitors your SolarEdge managed Solar Panels. The QuickApp has (child) devices for current Power, solar Power, lastday, lastmonth, lastyear and lifetime energy. 

Changes version 1.1 (21th August 2021)
- Changed back currentPower measurement to Watt and lastDayData, lastMonthData to kWh (not to mess up statistics in Energy panel or InfluxDB/Grafana installations)
- Changed Child device currentPower to Main device with type com.fibaro.powerSensor (Watt). So the Main device will show the current power production, no Child device necessary. 
- Changed Child device lastDayData to type com.fibaro.energyMeter (kWh). These values will be shown in the new energy panel. 
- Added automaticaly change rateType interface of Child device lastDayData to "production"
- Added extra check on apiKey and siteID, if not OK then change to simulation mode
- SolarEdge Monitor settings currency and PiekPower also available in simulation mode
- Changed the lastUpdateTime to format dd-mm-yyyy hh:mm 

Changes version 1.0 (30th July 2021)
- Total m² solar panels added to log text and label text
- Check for API existance of lifeTimeData_revenue (not available in older firmware)
- Automatic conversion added for lastmonthData, lastYearData and lifetimeData production to Wh, kWh, MWh or GWh
- Automatic conversion added for currentPower to Watt, Kilowatt, Megawatt or Gigawatt (yes, Megawatt and Gigawatt is optimistic)
- Get the Peakpower and Currency settings from Inverter
- Peakpower added to label text and child device log text

Changes version 0.3 (12th April 2021)
- Added last update date / time
- Cleaned up the code

Changes version 0.2 (12th April 2021)
- Disabled revenue value (not for lifeTimeData)

Changes version 0.1 (11th April 2021)
- First (test) version


Variables (mandatory): 
- siteID = ID of your SolarEdge Monitor
- apiKey = API key of your SolarEdge Monitor
- valuta = Name of the valuta your saving with solar energy (default = euro)
- solarM2 = The amount of m2 Solar Panels (use . for decimals) for calculating Solar Power m2 (default = 0)
- interval = The daily API limitiation is 300 requests. The default request interval is 360 seconds (6 minutes).
- debugLevel = Number (1=some, 2=few, 3=all, 4=simulation mode) (default = 1)
- icon = User defined icon number (add the icon via an other device and lookup the number) (default = 0)
