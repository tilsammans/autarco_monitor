# SolarEdge_Monitor
This QuickApp (for the Fibaro Homecenter 3) monitors your SolarEdge managed Solar Panels. The QuickApp has (child) devices for current Power, solar Power, lastday, lastmonth, lastyear and lifetime energy. 

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
