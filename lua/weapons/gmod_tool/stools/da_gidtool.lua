TOOL.Category   = "Metro"
TOOL.Name       = "DAtrashkow Gid Tool"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Information = {
	{ name = "left" },
	{ name = "right" },
	{ name = "reload" }
}

if CLIENT then
	language.Add("Tool.Gid.name", "DAtrashkow Gid Tool")
	language.Add("Tool.Gid.desc", "Sets Gids")
	language.Add("Tool.Gid.left", "Set/Update")
	language.Add("Tool.Gid.right", "Remove")
	language.Add("Tool.Gid.reload", "Scan")
end

if SERVER then util.AddNetworkString("metrostroi-stool-da-gid") end

function TOOL:SpawnGid(ply,trace,param)
    local pos = trace.HitPos
	local startPos = ply:EyePos()
	local direction = ply:EyeAngles():Forward() -- куда смотрит игрок
	local angle_ofeye = (pos - startPos):Angle() -- угол от игрока до точки попадания
	
    local ent
    local found = false
    local entlist = ents.FindInSphere(pos,64)
    for k,v in pairs(entlist) do
        if v:GetClass() == "gmod_track_gid_trigger" then
            ent = v
            found = true
        end
    end

    if not ent then
		ent = ents.Create("gmod_track_gid_trigger") 
	end
    if IsValid(ent) then
        ent:SetPos(pos + Vector (0,0,15))
		
        ent:SetAngles(Angle(0,angle_ofeye.yaw,0) + Angle (0,0,0))
		if not ent.Gid then ent.Gid = {} end
        
		
        ent:Spawn() 
        ent:Activate()
		ent.GidTriggerName = self.Gid.Name
        if not found then
            ent:Spawn()
            undo.Create("gid")
                undo.AddEntity(ent)
                undo.SetPlayer(ply)
            undo.Finish()
        end
    end
    return ent
end

function TOOL:GetGid(ply,trace)
    local ent
    local pos = trace.HitPos

    local entlist = ents.FindInSphere(pos,64)
    for k,v in pairs(entlist) do
        if v:GetClass() == "gmod_track_gid_trigger" then
            ent = v
        end
    end

    return ent
end

function TOOL:LeftClick(trace)
    if CLIENT then
        return true
    end

    local ply = self:GetOwner()
    if (ply:IsValid()) and (not ply:IsAdmin()) then return false end
    if not trace then return false end
    if trace.Entity and trace.Entity:IsPlayer() then return false end
  
    ent = self:SpawnGid(ply,trace)
    return true
end


function TOOL:RightClick(trace)
    if CLIENT then
        return true
    end

    local ply = self:GetOwner()
    if (ply:IsValid()) and (not ply:IsAdmin()) then return false end
    if not trace then return false end
    if trace.Entity and trace.Entity:IsPlayer() then return false end

    local entlist = ents.FindInSphere(trace.HitPos,(self.Type == 3 and self.Auto.Type == 5) and 192 or 64)
    for k,v in pairs(entlist) do
        if v:GetClass() == "gmod_track_gid_trigger" then
            if IsValid(v) then SafeRemoveEntity(v) end
        end
    end
    return true
end

function TOOL:Reload(trace)
    if CLIENT then return true end
    
    local ply = self:GetOwner()
    
    if not trace then return false end
    if trace.Entity and trace.Entity:IsPlayer() then return false end
    
    local ent = self:GetGid(ply, trace)

    if (not ent ) then return true end

    if (self.Gid.RightNumber ~= self.Gid.LeftNumber) then
        self.Gid.LeftNumberCheck = true   
    end

    net.Start("metrostroi-stool-da-gid")
        net.WriteTable(self.Gid)
    net.Send(self:GetOwner())

    return true
end

function TOOL:SendSettings()
    if not self.Gid then return end

    net.Start("metrostroi-stool-da-gid")
        net.WriteTable(self.Gid)
    net.SendToServer()
end

net.Receive("metrostroi-stool-da-gid", function(_, ply)
    local TOOL = LocalPlayer and LocalPlayer():GetTool("da_gidtool") or ply:GetTool("da_gidtool")
    TOOL.Gid = net.ReadTable()
    if CLIENT then
        NeedUpdate = true
    end
end)

function TOOL:BuildCPanelCustom()
    local tool = self
    local CPanel = controlpanel.Get("da_gidtool")
    if not CPanel then return end

    CPanel:ClearControls()
    CPanel:SetPadding(0)
    CPanel:SetSpacing(0)
    CPanel:Dock( FILL )

    local VName = CPanel:TextEntry("Название метки для ГИДа:")
    VName:SetValue(tool.Gid.Name or "")
    function VName:OnChange()
        local value = self:GetValue()
        self:SetText(value)
        self:SetCaretPos(#value)
        tool.Gid.Name = self:GetValue()
        tool:SendSettings()
    end
end

TOOL.NotBuilt = true
function TOOL:Think()
    if CLIENT and (self.NotBuilt or NeedUpdate) then
        self.Gid = self.Gid or util.JSONToTable(string.Replace(GetConVarString("da_gidtool"),"'","\"")) or {}
        self:SendSettings()
        self:BuildCPanelCustom()
        self.NotBuilt = false
        NeedUpdate = false
    end
end
function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", { Text = "#Tool.Gid.name", Description = "#Tool.Gid.desc" })
    if not self then return end
    self:BuildCPanelCustom()
end