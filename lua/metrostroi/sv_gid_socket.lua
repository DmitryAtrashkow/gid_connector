if SERVER then
	require("gwsockets")
	
	local path = "datrashkow_data/gid_key.txt"

	if file.Exists(path, "DATA") then
			Metrostroi.GIDKey = string.Trim(file.Read(path, "DATA"))
	else
			if not file.Exists("datrashkow_data", "DATA") then
				file.CreateDir("datrashkow_data")
			end
			local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			local key = ""
			for i = 1, 32 do
				local n = math.random(#chars)
				key = key .. chars:sub(n, n)
			end
		file.Write(path, key)
		Metrostroi.GIDKey = key
	end

	
	
	timer.Simple( 30, function()
		if Metrostroi.GIDSocket then
			Metrostroi.GIDSocket:close()  
		end

		local wsUrl = "wss://ru.datrashkow.ru/ws/"
		local ip = wsUrl
		local hostname = GetHostName():lower()
		if string.find(hostname, "datrashkow", 1, true) then
			ip = "ws://10.1.2.19:9988"
		end

		Metrostroi.GIDSocket = GWSockets.createWebSocket(ip)

		function Metrostroi.GIDSocket:onMessage(txt)
			local Message = util.JSONToTable(txt)
			if not Message and not istable(Message) then
				return
			end

			if Message[1] == "ThreadIDChange" then
				local thrid = tostring(Message[2])
				local entid = tonumber(Message[3])
				local gidname = Message[4]

				local headEntity = ents.GetByIndex(entid)
				if headEntity and not Metrostroi.GIDThreads[thrid] then
					Metrostroi.GIDThreads[thrid] = headEntity.WagonList
					hook.Run("GID.TriggerPass", gidname, headEntity)
				end
			end
		end
		
		function Metrostroi.GIDSocket:onError(txt)
			print("Error: ", txt)
		end

		function Metrostroi.GIDSocket:onDisconnected()
			timer.Simple( 5, function()
				if Metrostroi.GIDSocket:isConnected() == false then
					Metrostroi.GIDSocket:open()
				end
			end)
		end
		Metrostroi.GIDSocket:open()
	end )
	
	Metrostroi.GIDThreads = {}

	timer.Remove("Metrostroi.GIDSocketPing")
	timer.Create("Metrostroi.GIDSocketPing", 5, 0, function()
		if not Metrostroi.GIDSocket then return end
		if not Metrostroi.GIDSocket:isConnected() then return end

		Metrostroi.GIDSocket:write("ping")
	end)


	hook.Remove("TrainSpawnerSpawn", "GID.TrainSpawn")
	hook.Remove("EntityRemoved", "GID.TrainRemove")
	
	hook.Add("GID.TriggerPass","GID.TriggerPass", function (gidname,train)
		trigname = string.Split( gidname, "-" )[1]
		pathname = string.Split( gidname, "-" )[2]
		local RN = nil
		local ARS = 0
		local class = train and train:GetClass() or ""
		if not RN then
			if train.ASNP and not train.ASNP.Disable and (train:GetNW2Int("ASNP:RouteNumber",0) ~= 0) then
				RN = train:GetNW2Int("ASNP:RouteNumber",0)
			elseif train.PAM and train.PAM_VV and train.PAM_VV.Power and train:GetNW2String("PAM:RouteNumber","") ~= "" then
				RN = tonumber(train:GetNW2String("PAM:RouteNumber","0"))
			elseif train.MFDU and train.MFDU.RouteNumber and train.MFDU.RouteNumber > 0 then
				RN = train.MFDU.RouteNumber
			elseif train.MFDU and train.MFDU.RouteN and tonumber(train.MFDU.RouteN) > 0 then
				RN = tonumber(train.MFDU.RouteN)
			elseif train.RouteNumber then
				RN = tonumber(train:GetNW2String("RouteNumber",0))
				if train.RouteNumber.Max == 2 and class ~= 'gmod_subway_81-717_5a' and class ~= 'gmod_subway_81-717_freight' and class ~= 'gmod_subway_81-717_6' and class ~= 'gmod_subway_em508' and class ~= 'gmod_subway_em508t' then RN = RN/10 end
			elseif train.RouteNumberSys then
				RN = tonumber(train.RouteNumberSys.RouteNumber)
			end
		end
		if not RN then RN = 0 end
		
		if class == "gmod_subway_81-502" then 
			if train.Electric.Type == 2 then 
				if CS ~= 0 and train.RCAV5.Value == 1 and train.RCAV4.Value == 1 and train.RCAV3.Value == 1 then ARS = 1 end         
			elseif train.MARS then
				if CS ~= 0 and train.RCARS.Value == 1 and train.RCBPS.Value == 1 then ARS = 1 end
			end
		elseif class == 'gmod_subway_ezh3' then 
			if CS==1 and train.RUM.Value == 1 then ARS = 1 end
		elseif class == 'gmod_subway_ezh' then 
			if CS==1 and train.RC1.Value == 1 then ARS = 1 end
		elseif class == 'gmod_subway_81-718' then 
			if CS != 0 and train.RC.Value == 1 then ARS = 1 end
		elseif class == 'gmod_subway_81-720' or class == 'gmod_subway_81-760' or class == 'gmod_subway_81-760a' then
			if CS != 0 and train.BARSBlock.Value == 0 and train.ALS.Value == 0 then ARS = 1 end
			if CS != 0 and train.ALS.Value == 0 and train.BARSBlock.Value == 1 or train.BARSBlock.Value == 2 then ARS = 2 end 
		elseif class == 'gmod_subway_81-722' or class == 'gmod_subway_81-722_new' then
			if CS != 0 and train.RCARS.Value == 1 then
				ARS = 1
				if train.BARSMode.Value != 1 then ARS = 2 end
			end
		elseif class == 'gmod_subway_81-717_lvz' or class == 'gmod_subway_81-540_2_lvz' or class == 'gmod_subway_81-540_1' or class == 'gmod_subway_81-717_6' then 
			if train.Electric.Type == 5 then 
				if CS != 0 and train.RC1.Value == 1 then ARS = 1 end
			elseif train.Electric.Type == 3 or train.Electric.Type == 4 then 
				if CS != 0 and  train.RC1.Value == 1 and train.RC2.Value == 1  then ARS = 1 end
				if (CS != 0 and train.RC1.Value == 0 and train.RC2.Value == 1) or (CS != 0 and train.RC1.Value == 1 and train.RC2.Value == 0)  then ARS = 2 end
			end 
		elseif train.RC1 and train.ReadTrainWire then
			if CS != 0 and train.RC1.Value == 1 then ARS = 1 end
			if CS != 0 and train:ReadTrainWire(87) > 0 then ARS = 2 end
		end
		
		if Metrostroi.GIDSocket then
			
			local WagonList = train.WagonList
			
			local ThreadID = nil
			
			for thrID,thread in pairs(Metrostroi.GIDThreads) do
				for _, ent in pairs(thread) do
					for _, wagon in pairs(WagonList) do
						if ent == wagon then
							ThreadID = thrID
							
							local SendTable = {
								["Type"] = "Pass", 
								["Message"] = {
									["StInfo"] = trigname, 
									["Player"] = train:GetDriverPly() and train:GetDriverPly():SteamID() or nil,
									["Nick"] = train:GetDriverPly() and train:GetDriverPly():Nick() or nil,
									["Route"] = RN,
									["ThreadID"] = thrID,
									["ARS"] = ARS,
									["Path"] = pathname
								},
								["Key"] = Metrostroi.GIDKey,
								["Hostname"] = GetHostName()
							}
							local debug = GetConVar("metrostroi_signal_debug")
							if debug and debug:GetInt() == 1 then
								print("================== GID Debug ==================")
								PrintTable(SendTable)
							end
							Metrostroi.GIDSocket:write(util.TableToJSON(SendTable))
							break
						end
					end
					if ThreadID then
						break
					end
				end
			end
			if not ThreadID then
				local SendTable = {
					["Type"] = "Start", 
					["Message"] = {
						["TrainType"] = train:GetClass(), 
						["Route"] = RN,
						["Map"] = game.GetMap(),
						["ServerID"] = 1,
						["TrainID"] = train:EntIndex(),
						["StInfo"] = trigname,
						["GidInfo"] = gidname
					},
					["Key"] = Metrostroi.GIDKey,
					["Hostname"] = GetHostName()
				}
				local debug = GetConVar("metrostroi_signal_debug")
				if debug and debug:GetInt() == 1 then
					print("================== GID Debug ==================")
					PrintTable(SendTable)
				end
				Metrostroi.GIDSocket:write(util.TableToJSON(SendTable))
			end
			
		end
	end)
end