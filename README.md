# Autarco Monitor
This QuickApp monitors your Autarco managed Solar Panels
The QuickApp has (child) devices for Solar Power, Lastday Data, Lastmonth Data, Lastyear Data and Lifetime Data
The Solar Production values are only requested from the Autarco API between sunrise and sunset
The QuickApp also shows the Environmental Benefits in the labels for CO2, SO2, NOX, Trees planted and Lightbulbs
The QuickApp also shows the Autarco Installation details in the labels
The Environmental Benefits are updated once a day after 12:00 hour
The settings for Peak Power and Currency are retrieved from the inverter 
The rateType interface of Child device Last Day is automatically set to "production" and values from this child devices can be used for the Energy Panel 
The readings for lastyear and lifetime energy are automatically set to the right Wh unit (Wh, kWh, MWh or GWh) 

This is a fork of the excellent [SolarEdge_monitor by @GitHub4Eddy](https://github.com/GitHub4Eddy/solaredge_monitor)


Variables (mandatory and created automatically): 
- siteID = Site ID of your Autarco Inverter (see your Inverter Site Details)
- apiKey = API key of your Autarco Inverter (contact your installer if you don't have one)
- systemUnits = SystemUnits is Metrics (kg) or Imperial (Lb) (default is Metrics)
- solarM2 = The amount of m2 Solar Panels (use . for decimals) for calculating Solar Power m2 (default = 0)
- interval = The daily API limitation is 300 requests. The default request interval is 360 seconds (6 minutes)
- pause = Should the SolardEdge go in pause mode after sunset (default = true)
- debugLevel = Number (1=some, 2=few, 3=all, 4=simulation mode) (default = 1)
