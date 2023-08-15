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
			local code =  pluginConfig.code
			local caller = nil
			address = address:gsub('%b[]', '')
			-- Checking if there are any description arguments.
			if args[1] then
				local description = table.concat(args, " ")
				if type == "ts" then
					description = "Traffic Stop - "..description
					if isPluginLoaded("wraithv2") and wraithLastPlates ~= nil then
						if wraithLastPlates.locked ~= nil then
							local plate = wraithLastPlates.locked.plate:gsub("%s+","")
							description = description..(" PLATE: %s"):format(plate)
						end
					end
				end
				if isPluginLoaded("frameworksupport") then
					-- Getting the ESX Identity Name
					GetIdentity(source, function(identity)
						if identity.name ~= nil then
							caller = identity.name
						else
							caller = GetPlayerName(source)
							debugLog("Unable to get player name from ESX. Falled back to in-game name.")
						end
					end)
					while caller == nil do
						Wait(10)
					end
				else
					caller = GetPlayerName(source) 
				end
				-- Sending the API event
				TriggerEvent('snailyCAD::trafficstop:SendTrafficApi',playerCoords, caller,address, postal, description, source)
				-- Sending the user a message stating the call has been sent
				TriggerClientEvent("chat:addMessage", source, {args = {"^0^5^*[snailyCAD]^r ", "^7Details regarding you traffic Stop have been added to CAD"}})
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
		AddEventHandler('snailyCAD::trafficstop:SendTrafficApi', function( targetCoords,caller, address, postal, description, source)
			-- send an event to be consumed by other resources
			if Config.apiSendEnabled then
		
		
					for k,v in pairs(GetPlayerIdentifiers(source))do
						if string.sub(v, 1, string.len("discord:")) == "discord:" then
							local discord = v:sub(9)
						performApiGETRequest( 'admin/manage/units/null?discordId='..discord,true, function(resultData)
						local unitdata = json.decode(resultData)["userOfficers"][1]
						local datas = { unit = unitdata["id"] }
						local callsignone = unitdata["callsign1"]
						local callsign = callsignone ..unitdata["callsign2"]
			
				local call = {
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
				performApiRequest(call, '911-calls',true, function(resultData)
					local callnum = json.decode(resultData)["id"]
						performApiRequest(datas, '911-calls/assign/'..callnum,'', function(resultData)
						end)
				end)
						end)
					end
				end
			else
				debugPrint("[snailyCAD] API sending is disabled. Traffic Stop ignored.")
			end
		end)
	end