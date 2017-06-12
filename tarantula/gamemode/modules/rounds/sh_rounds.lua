trn.Rounds = trn.Rounds or {}

ROUND_WAITING = 0
ROUND_PREP = 1
ROUND_ACTIVE = 2
ROUND_POST = 3

WIN_NONE = 0
WIN_TIME = 1
WIN_RED = 2
WIN_BLUE = 3

trn.Rounds.State = trn.Rounds.State or ROUND_WAITING

-- Replicated ConVars need to be defined shared. Why do I always forget this.
local roundtime = CreateConVar("trn_roundtime_seconds", "600", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How long is the round in seconds. This is before any time extensions are added.")
local numrounds = CreateConVar("trn_rounds_per_map", "7", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How many rounds to play before a map change is initiated.")

-- Getter function for round states.
function trn.Rounds.GetState() return trn.Rounds.State end
function trn.Rounds.IsWaiting() return trn.Rounds.GetState() == ROUND_WAITING end
function trn.Rounds.IsPrep() return trn.Rounds.GetState() == ROUND_PREP end
function trn.Rounds.IsActive() return trn.Rounds.GetState() == ROUND_ACTIVE end
function trn.Rounds.IsPost() return trn.Rounds.GetState() == ROUND_POST end

-------------------------
-- trn.Rounds.Initialize
-------------------------
-- Desc:		Calls the trn.Rounds.Initialize hook to initialize the round system.
function trn.Rounds.Initialize()
	hook.Call("trn.Rounds.Initialize")
end

----------------------------
-- trn.Rounds.GetRoundsLeft
----------------------------
-- Desc:		Gets the number of rounds left on the current map.
-- Returns:		Number, rounds left on the map.
trn.Rounds.NumRoundsPassed = 0
function trn.Rounds.GetRoundsLeft()
	return numrounds:GetInt() - trn.Rounds.NumRoundsPassed
end

-------------------------
-- trn.Rounds.GetEndTime
-------------------------
-- Desc:		Gets the round time.
-- Returns:		Number, CurTime + round time.
function trn.Rounds.GetEndTime()
	return GetGlobalFloat("trn_roundend_time")
end

-------------------------------
-- trn.Rounds.GetRemainingTime
-------------------------------
-- Desc:		Gets the remaining round time.
-- Returns:		Number, time remaining.
function trn.Rounds.GetRemainingTime()
	return math.max(trn.Rounds.GetEndTime() - CurTime(), 0)
end

----------------------------------------
-- trn.Rounds.GetFormattedRemainingTime
----------------------------------------
-- Desc:		Just read the name of the fucking function, jeez.
-- Returns:		String, time formatted as "Minutes:Seconds".
function trn.Rounds.GetFormattedRemainingTime()
	local time = trn.Rounds.GetRemainingTime()

	return string.FormattedTime(time, "%02i:%02i")
end

/*
--------------------------------
-- trn.Rounds.GetFormattedState
--------------------------------
-- Desc:		Gets the current round as a string in the correct language.
-- Returns:		String, current round state.
local phrases = {
	[ROUND_WAITING] = "waiting",
	[ROUND_PREP] = "preperation",
	[ROUND_ACTIVE] = "active",
	[ROUND_POST] = "roundend"
}
function trn.Rounds.GetFormattedState()
	return trn.Languages.GetPhrase(phrases[trn.Rounds.GetState()])
end
*/

if CLIENT then
	net.Receive("trn.Rounds.StateChanged", function()
		trn.Rounds.State = net.ReadUInt(3)
		hook.Call("trn.Rounds.StateChanged", nil, trn.Rounds.State)
	end)

	net.Receive("trn.Rounds.RoundWin", function()
		local wintype = net.ReadUInt(3)
		trn.Rounds.NumRoundsPassed = trn.Rounds.NumRoundsPassed + 1

		if trn.Rounds.GetRoundsLeft() <= 0 then
			hook.Call("trn.Rounds.MapEnded", nil, wintype)
		end

		hook.Call("trn.Rounds.RoundEnded", nil, wintype)
	end)
end