trn.Roles = trn.Roles or {}

-- trn2 treats spectators differently than trn. Here spectators are only people with
-- trn_always_spectator enabled. Dead players are just dead reds/blues, not spectators.
ROLE_WAITING	= 0
ROLE_SPECTATOR	= 1
ROLE_BLUE	= 3
ROLE_RED	= 4

trn.Roles.Colors = {
	[ROLE_WAITING] = trn.Colors.Dead,
	[ROLE_SPECTATOR] = trn.Colors.Dead,
	[ROLE_BLUE] = trn.Colors.Blue,
	[ROLE_RED] = trn.Colors.Red
}

local PLAYER = FindMetaTable("Player")

------------------
-- PLAYER:SetRole
------------------
-- Desc:		Sets the of the player BUT DOES NOT NETWORK IT.
-- Arg One:		ROLE_ enum, to set the player to.
function PLAYER:SetRole(role)
	self.trn_role = role
end

------------------
-- PLAYER:GetRole
------------------
-- Desc:		Gets the player's role.
-- Returns:		ROLE_ enum of their role.
function PLAYER:GetRole()
	return self.trn_role or ROLE_WAITING
end

-- Role checker functions.
function PLAYER:IsWaiting() return self:GetRole() == ROLE_WAITING end
function PLAYER:IsSpectator() return self:GetRole() == ROLE_SPECTATOR end
function PLAYER:IsBlue() return self:GetRole() == ROLE_BLUE end
function PLAYER:IsRed() return self:GetRole() == ROLE_RED end

function PLAYER:GetRoleColor()
	return trn.Roles.Colors[self:GetRole()]
end

if CLIENT then
/*
	--------------------------
	-- trn.Roles.RoleAsString
	--------------------------
	-- Desc:		Gets a language translated version of the given player's role.
	-- Returns:		String, the player's role.
	local role_phrase = {
		[ROLE_WAITING] = "waiting",
		[ROLE_SPECTATOR] = "spectator",
		[ROLE_UNKNOWN] = "spectator",
		[ROLE_INNOCENT] = "innocent",
		[ROLE_DETECTIVE] = "detective",
		[ROLE_TRAITOR] = "traitor"
	}
	function trn.Roles.RoleAsString(ply)
		return trn.Languages.GetPhrase(role_phrase[ply:GetRole()] or "invalid")
	end
*/
end
