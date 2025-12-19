AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	
	self:SetModel("models/hunter/blocks/cube075x2x075.mdl")
	
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX) -- !!!!!
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self:SetTrigger(true)
	
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end
	
end

function ENT:UpdateDebugVisibility()
	local debug = GetConVar("metrostroi_signal_debug")
	if debug and debug:GetInt() == 1 then
		self:SetNoDraw(false)
		self:SetRenderMode(RENDERMODE_TRANSALPHA)
		self:SetColor(Color(255, 255, 255, 51))
	else
		self:SetNoDraw(true)
	end
end

function ENT:Use(ply)

end

function ENT:Think()
	self:UpdateDebugVisibility()
	self:NextThink(CurTime())
	return true
end

function ENT:StartTouch(ent)
	if ent:GetClass() ~= "gmod_train_bogey" then return end
	local train = ent:GetNW2Entity("TrainEntity")
	if train and IsValid(train) and train:GetDriver() and ent == train.FrontBogey then
		local driver = train:GetDriver()
		local driverNick = IsValid(driver) and driver:Nick() or "неизвестен"
		local debug = GetConVar("metrostroi_signal_debug")
		if debug and debug:GetInt() == 1 then
			RunConsoleCommand("say","[GID] Триггернул метку:", self.GidTriggerName, driverNick)
		end
		hook.Run("GID.TriggerPass", self.GidTriggerName, train)
	end
end


function ENT:OnRemove()
end

	

	