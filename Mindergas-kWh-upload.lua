--[[
 /home/pi/domoticz/scripts/dzVents/scripts/upload_gas_usage_to_minderGas.lua
 Author		: Roblom
 Adjusted       : Vandermark
 Description 	: This script collects the kWh-values from Domoticz (for example from the heatpump) and uploads the values to a MinderGas account.
		  For more information about MinderGas, see the API instructions on their website on https://mindergas.nl/member/api
]]--

---------------------------------------------------------------------------------------------------------------
local AUTH_TOKEN = 'YourMindergasAPI'	 -- Fill in here your Mindergas authentication token
---------------------------------------------------------------------------------------------------------------

return {
	active = true,
	on = {
		timer 			= {'at 0:12'},       --Time to upload kWh counter value to mindergas.nl
		--timer 			= {'every minute'},
		httpResponses 	= {'UploadToMindergas'}},
	 logging =    
    {   
        level = domoticz.LOG_ERROR, -- change to LOG_ERROR when OK - was LOG_DEBUG
        marker = scriptVar,
    },
	execute = function(domoticz, item)
		
        if item.isTimer then
		
			local kWhUsageCounter 	= domoticz.devices(145).WhTotal/1000  -- Idx of the Usage kWh counter device
			local TodaysDate 		= tostring(domoticz.time.rawDate)

			domoticz.log('WP kWh is ' .. kWhUsageCounter, domoticz.LOG_INFO)
			domoticz.log('The date is ' .. TodaysDate, domoticz.LOG_INFO )
		
			domoticz.openURL({
				url = 'https://www.mindergas.nl/api/meter_readings',        -- New URL of mindegas.nl
				method = 'POST',
				headers = {
					['Content-Type']	= 'application/json',
					['AUTH-TOKEN']		= AUTH_TOKEN
				},
				callback = 'UploadToMindergas',
				postData = {
					['date']			= TodaysDate,
					['reading']			= kWhUsageCounter
				},
			})
			
        elseif (item.isHTTPResponse) then
            local SubSystem   = domoticz.NSS_TELEGRAM
            local Priority      = domoticz.PRIORITY_NORMAL
            local Sound         = domoticz.SOUND_DEFAULT
            local Tittle        = "MinderGas - "
			local Message       = "Geen idee :" .. item.statusCode
			
			if (item.statusCode == 201) then Message ='WP kWh usage data is sucessfully upoaded.'
			    elseif (item.statusCode == 401) then Message = 'There was an authorisation problem with the Mindergas.nl database.'
			    elseif (item.statusCode == 422) then Message = 'There was an unprocessable enrty while trying to upload the gas usage data to Mindergas.nl'
			end 	
			domoticz.log(Message, domoticz.LOG_INFO)
			domoticz.notify(Tittle,Message,Priority,Sound,"",SubSystem)
        end
	end
}

--[[
De volgende HTTP status codes worden geretourneerd:

201 Created 
De meterstand is succesvol verwerkt en opgeslagen.

401 Unauthorized 
Het authenticatietoken is ongeldig of zit niet in de request.

422 Unprocessable Entity 
Er is een validatiefout opgetreden. Dit kan komen door:

Er is al een meterstand voor de opgegeven datum.
De meterstand is geen getal.
De meterstand is kleiner dan de vorige meterstand.
De meterstand is groter dan de volgende meterstand.
De datum ligt in de toekomst.
De datum ligt voor 31 december 2005.
]]--
