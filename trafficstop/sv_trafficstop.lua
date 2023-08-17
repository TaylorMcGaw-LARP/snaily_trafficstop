-----------------------------------------------    911 CALL COMMAND BY ILLUMIINATI-----------------------------------------------------------------
local pluginConfig = Config.GetPluginConfig("trafficstop")
if pluginConfig.enabled then

		if pluginConfig.trafficCommand == nil then
			pluginConfig.trafficCommand = "ts"
		end
	
	
		-- Traffic Stop Handler
		function HandleTrafficStop(type, source, args, rawCommand)
			local identifier = GetIdentifiers(source)[Config.primaryIdentifier]
			local index = findIndex(identifier)
			local address = LocationCache[source] ~= nil and LocationCache[source].location or 'Unknown'
			local postal = isPluginLoaded("postals") and getNearestPostal(source) or ""
			local player = source
			local ped = GetPlayerPed(player)
			local playerCoords = GetEntityCoords(ped)
			
			address = address:gsub('%b[]', '')
			-- Checking if there are any description arguments.
			
			if args[1] then
				local description = table.concat(args, " ")
				if type == "ts" then
					description = "Traffic Stop - "..description

					if isPluginLoaded("wraithv2") and wraithLastPlates ~= nil then
						if wraithLastPlates.locked ~= nil then
							local plate = wraithLastPlates.locked.plate:gsub("%s+","")
							local platedata = {
								plateOrVin = plate
							}
							performApiRequest(platedata,'search/vehicle?includeMany=true','is-from-dispatch', function(result)  
								local reg = false
								reg = json.decode(result)[1]
								if reg then
									TriggerEvent("snailyCAD::wraithv2:PlateLocked", source, reg, cam, plate, index)
									local plate = reg.plate
									local vin = reg.vinNumber
									local color = reg.color
									local registrationStatus = reg.registrationStatus.value
									local owner = ("%s %s"):format(reg.citizen.name, reg.citizen.surname)
									description = description..(" \nPLATE: %s \nOWNER: %s  \nSTATUS: %s"):format(plate,owner,registrationStatus)
								end
							end)

						end
					end
				end
				-- Sending the API event
				for k,v in pairs(GetPlayerIdentifiers(source))do
					if string.sub(v, 1, string.len(Config.primaryIdentifier..":")) == Config.primaryIdentifier..":" then
						local primaryid = v:sub(9)
						performApiGETRequest( 'admin/manage/units/null?'..Config.primaryIdentifier..'='..primaryid,true, function(resultData)
							local user = json.decode(resultData)["userOfficers"][1]
							TriggerEvent('snailyCAD::trafficstop:SendTrafficApi',playerCoords,user,address, postal, description, source)
				-- Sending the user a message stating the call has been sent
				TriggerClientEvent("chat:addMessage", source, {args = {"^0^5^*[snailyCAD]^r ", "^7Details regarding you traffic Stop have been added to CAD"}})
						end)
					end
				end
				
			else
				-- Throwing an error message due to now call description stated
				TriggerClientEvent("chat:addMessage", source, {args = {"^0[ ^1Error ^0] ", "You need to specify Traffic Stop details (IE: vehicle Description)."}})
			end
		end
	
		RegisterCommand(pluginConfig.trafficCommand, function(source, args, rawCommand)
			HandleTrafficStop("ts", source, args, rawCommand)
		end, pluginConfig.usePermissions)
	
		-- Client TraficStop request
		RegisterServerEvent('snailyCAD::trafficstop:SendTrafficApi')
		AddEventHandler('snailyCAD::trafficstop:SendTrafficApi', function( targetCoords,user, address, postal, description, source)
			-- send an event to be consumed by other resources
			if Config.apiSendEnabled then
				
			
							local datas = { unit = user["id"] }
							local callsignone = user["callsign"]
							local callsign = callsignone ..user["callsign2"]
				
							local calls = {
								name = callsign, 
								location = address, 
								postal = postal,
								description  = description,
								gtaMapPosition  = {
									x = targetCoords.x,
									y = targetCoords.y,
									z = targetCoords.z,
									heading = 0
								},
								situationCode = pluginConfig.situationcodeid
							}
							debugLog("sending Traffic Stop!")
							performApiRequest(calls, '911-calls','true', function(resulta)
								local callnum = json.decode(resulta)["id"]
								local unitid = { unit = user["id"] }
							
								performApiRequest(unitid, '911-calls/assign/'..callnum,'false', function(resultData) end)
							end)
					
			else
				debugPrint("[snailyCAD] API sending is disabled. Traffic Stop ignored.")
			end
		end)
end