-----------------------------------------------------------------------
--	Скрипт написан в 2025 году для аддона Metrostroi.
--	Аддон реализует необходимую логику триггеров для ГИДа
--	Автор: 	Dmitry_Atrashkow
--	www.datrashkow.ru
--	https://t.me/datrashkow_home
-----------------------------------------------------------------------

local function getFile(path,name,id)
    local data,found
    if file.Exists(Format(path..".txt",name),"DATA") then
        data= util.JSONToTable(file.Read(Format(path..".txt",name),"DATA"))
        found = true
    end
    if not data and file.Exists(Format(path..".lua",name),"LUA") then
        data = util.JSONToTable(file.Read(Format(path..".lua",name),"LUA"))
        found = true
    end
    if not found then
        print(Format("%s definition file not found: %s",id,Format(path,name)))
        return
    elseif not data then
        return
    end
    return data
end

local function loadGid(name, keep)
    name = name or game.GetMap()

    local gid_ents = ents.FindByClass("gmod_track_gid_trigger")
    for k,v in pairs(gid_ents) do SafeRemoveEntity(v) end

    if keep then return end
    local gid = getFile("datrashkow_data/"..name.."/gid","gid","Gid")
    if not gid then return end

    for k,v in pairs(gid) do
        local ent = ents.Create("gmod_track_gid_trigger")
        if IsValid(ent) then
            ent:SetPos(v.Pos)
            ent:SetAngles(v.Angles)
			ent:Spawn()
			ent:Activate()
			ent.GidTriggerName = v.GidTriggerName
			ent.UseSwitch = v.UseSwitch or nil
			ent.SwitchEntityName = v.SwitchEntityName or nil
			ent.TriggerOnDivergence = v.TriggerOnDivergence or nil
        end
    end
end 

hook.Add("Initialize", "Metrostroi_DAGidLoad", function()
    timer.Simple(4.0, loadGid)
end)


timer.Simple(4, function()
	local m_save = Metrostroi.Save
	function Metrostroi.Save(name)
		m_save(name)
		
		if not file.Exists("datrashkow_data","DATA") or file.Exists("datrashkow_data/"..game.GetMap(),"DATA") then
			file.CreateDir("datrashkow_data")
			file.CreateDir("datrashkow_data/"..game.GetMap())
		end
		name = name or game.GetMap()
		 
		local gid = {}
		local gid_ents = ents.FindByClass("gmod_track_gid_trigger")
		
		for k,v in pairs(gid_ents) do
			table.insert(gid, {
				GidTriggerName = v.GidTriggerName,
				UseSwitch = v.UseSwitch or nil,
				SwitchEntityName = v.SwitchEntityName or nil,
				TriggerOnDivergence = v.TriggerOnDivergence or nil,
				Pos = v:GetPos(),
				Angles = v:GetAngles()
			})
		end
		local data = util.TableToJSON(gid, true)
		file.Write(string.format("datrashkow_data/%s/gid.txt", name), data)
	end

	local m_load = Metrostroi.Load
	function Metrostroi.Load(name,keep_signs)
		m_load(name,keep_signs)
		loadGid(name,keep_signs)
	end
end)
