trn.Rounds = trn.Rounds or {}

util.AddNetworkString("trn.Rounds.StateChanged")
util.AddNetworkString("trn.Rounds.RoundWin")

-- Create round related convars.
local preventwin = CreateConVar("trn_dev_preventwin", "0", nil, "Set to 1 to prevent the rounds from ending.")
local preventstart = CreateConVar("trn_dev_preventstart", "0", nil, "Set to 1 to prevent the round from starting.")
local posttime = CreateConVar("trn_post_time", "30", FCVAR_ARCHIVE, "Time in seconds after a round has ended till the game goes into prep. Set to 0 to skip post round time.")
local initialpreptime = CreateConVar("trn_prep_time_initial", "60", FCVAR_ARCHIVE, "Time in seconds after the first round has entered preperation time till the round actually starts. Set to 0 to skip prep round time.")
local preptime = CreateConVar("trn_prep_time", "30", FCVAR_ARCHIVE, "Time in seconds after the round has entered preperation time till the round actually starts. Set to 0 to skip prep round time.")
local minimum_players = CreateConVar("trn_minimum_players", "2", FCVAR_ARCHIVE, "This many players is required for a round to start.")

cvars.AddChangeCallback("trn_dev_preventwin", function(_, _, newval)
	if newval == "0" and trn.Rounds.IsActive() then
		trn.Rounds.CheckForRoundEnd()
	end
end)
cvars.AddChangeCallback("trn_dev_preventstart", function(_, _, newval)
	if newval == "0" and not trn.Rounds.IsActive() then
		if trn.Rounds.ShouldStart() then
			trn.Rounds.EnterPrep()
			if timer.Exists("trn.Rounds.WaitForStart") then
				timer.Remove("trn.Rounds.WaitForStart")
			end
		end
	end
end)

///////////////////////////
// Round State Functions.
///////////////////////////
-----------------------
-- trn.Rounds.SetState
-----------------------
-- Desc:		Changes the current round state.
-- Arg One:		ROUND_ enum to set the round state to.
function trn.Rounds.SetState(state)
	trn.Rounds.State = state

	net.Start("trn.Rounds.StateChanged")
		net.WriteUInt(state, 3)
	net.Broadcast()

	hook.Call("trn.Rounds.StateChanged", nil, state)
	print("Round state changed to: ".. trn.Rounds.TypeToPrint(state))
end

---------------------------
-- trn.Rounds.WaitForStart
---------------------------
-- Desc:		When called makes a timer that checks every second to see if the round should start.
function trn.Rounds.WaitForStart()
	if timer.Exists("trn.Rounds.WaitForStart") then
		timer.Remove("trn.Rounds.WaitForStart")
	end

	timer.Create("trn.Rounds.WaitForStart", 1, 0, function()
		if trn.Rounds.ShouldStart() then
			trn.Rounds.EnterPrep()
			timer.Remove("trn.Rounds.WaitForStart")
		end
	end)
end

--------------------------
-- trn.Rounds.ShouldStart
--------------------------
-- Desc:		CHecks to see if its a good time to start the round.
-- Returns:		Boolean, should the round start.
function trn.Rounds.ShouldStart()
	return hook.Call("trn.Rounds.ShouldStart") or false
end

--------------------
-- trn.Rounds.Start
--------------------
-- Desc:		Starts the round.
function trn.Rounds.Start()
	if not trn.Rounds.ShouldStart() then
		trn.Rounds.Waiting()
		trn.Rounds.WaitForStart()
		return
	end

	trn.Rounds.ClearTimers()
	trn.Rounds.SetState(ROUND_ACTIVE)
	trn.Rounds.SetEndTime(CurTime() + GetConVar("trn_roundtime_seconds"):GetFloat())
	timer.Create("trn.Rounds.CheckForTimeRunOut", 1, 0, function()
		if (trn.Rounds.GetRemainingTime() <= 0) and (trn.Rounds.IsActive() and not GetConVar("trn_dev_preventwin"):GetBool()) then
			trn.Rounds.End(WIN_TIME)
		end
	end)

	hook.Call("trn.Rounds.RoundStarted")
end

------------------------
-- trn.Rounds.ShouldEnd
------------------------
-- Desc:		Decides if the round should end or not.
-- Returns:		WIN_ enum if there should be a win, false otherwise.
function trn.Rounds.ShouldEnd()
	return hook.Call("trn.Rounds.ShouldEnd") or false
end

------------------
-- trn.Rounds.End
------------------
-- Desc:		Ends the current round with the given WIN_ enum type.
-- Arg One:		WIN_ enum, the type of round win. If left nil will use WIN_NONE.
function trn.Rounds.End(wintype)
	wintype = wintype or WIN_NONE
	trn.Rounds.NumRoundsPassed = trn.Rounds.NumRoundsPassed + 1

	timer.Remove("trn.Rounds.CheckForTimeRunOut")

	hook.Call("trn.Rounds.RoundEnded", nil, wintype)

	net.Start("trn.Rounds.RoundWin")
		net.WriteUInt(wintype, 3)
	net.Broadcast()

	if trn.Rounds.GetRoundsLeft() <= 0 then
		hook.Call("trn.Rounds.MapEnded", nil, wintype)
	end

	if posttime:GetInt() <= 0 then
		trn.Rounds.EnterPrep()
	else
		trn.Rounds.EnterPost()
	end
end

-------------------------------
-- trn.Rounds.CheckForRoundEnd
-------------------------------
-- Desc:		Checks to see if the round should end and ends it if it should.
function trn.Rounds.CheckForRoundEnd()
	local win = trn.Rounds.ShouldEnd()
	if win then
		trn.Rounds.End(win)
	end
end

------------------------
-- trn.Rounds.EnterPrep
------------------------
-- Desc:		Puts the round into preperation mode.
function trn.Rounds.EnterPrep()
	trn.Rounds.SetState(ROUND_PREP)
	hook.Call("trn.Rounds.EnteredPrep")

	local delay = 0
	if not trn.Rounds.NumRoundsPassed or trn.Rounds.NumRoundsPassed == 0 then
		delay = initialpreptime:GetInt()
	else
		delay = preptime:GetInt()
	end

	if delay <= 0 then
		trn.Rounds.Start()
	else
		trn.Rounds.SetEndTime(CurTime() + delay)

		timer.Create("trn.Rounds.PrepTime", delay, 1, function()
			trn.Rounds.Start()
		end)
	end
end

------------------------
-- trn.Rounds.EnterPost
------------------------
-- Desc:		Puts the round into round post mode.
function trn.Rounds.EnterPost()
	trn.Rounds.SetState(ROUND_POST)
	hook.Call("trn.Rounds.EnteredPost")
	local delay = posttime:GetInt()

	if delay <= 0 then
		trn.Rounds.EnterPrep()
	else
		trn.Rounds.SetEndTime(CurTime() + delay)

		timer.Create("trn.Rounds.PostTime", delay, 1, function()
			if trn.Rounds.ShouldStart() then
				trn.Rounds.EnterPrep()
			else
				trn.Rounds.Waiting()
				trn.Rounds.WaitForStart()
			end
		end)
	end
end

--------------------------
-- trn.Rounds.CheckForWin
--------------------------
-- Desc:		Checks if there should be a win and if there should be, end the round.
function trn.Rounds.CheckForWin()
	local wintype = trn.Rounds.ShouldEnd()
	if wintype then
		trn.Rounds.End(wintype)
	end
end

----------------------
-- trn.Rounds.Waiting
----------------------
-- Desc:		Puts the game into the waiting round state.
function trn.Rounds.Waiting()
	trn.Rounds.ClearTimers()
	trn.Rounds.SetEndTime(0)
	trn.Rounds.SetState(ROUND_WAITING)
end

---------------------------
-- trn.Rounds.RestartRound
---------------------------
-- Desc:		Restarts the current round.
function trn.Rounds.RestartRound()
	trn.Rounds.ClearTimers()
	trn.Rounds.EnterPrep()
end

-------------------------------------
-- ConCommand:		trn_roundrestart
-------------------------------------
-- Desc:		Restarts the current round.
concommand.Add("trn_roundrestart", function(ply)
	if not IsValid(ply) or ply:IsSuperAdmin() then
		trn.Rounds.RestartRound()
	else
		print("You do not have permission to run this command.")
	end
end)


//////////////////////////
// Round Time Functions.
//////////////////////////
-------------------------
-- trn.Rounds.SetEndTime
-------------------------
-- Desc:		Sets a global float to the given time.
-- Arg One:		Number, the round end time. Make sure this is greater than CurTime.
function trn.Rounds.SetEndTime(seconds)
	SetGlobalFloat("trn_roundend_time", seconds)
end

----------------------
-- trn.Rounds.AddTime
----------------------
-- Desc:		Adds time to the current round end time.
-- Arg One:		Number, added to end time.
function trn.Rounds.AddTime(seconds)
	trn.Rounds.SetEndTime(trn.Rounds.GetEndTime() + seconds)
end

-------------------------
-- trn.Rounds.RemoveTime
-------------------------
-- Desc:		Remove time from the current round end time.
-- Arg One:		Number, removed from the end time.
function trn.Rounds.RemoveTime(seconds)
	trn.Rounds.AddTime(-seconds)
end


/////////////////
// Misc. Stuff.
/////////////////
--------------------------
-- trn.Rounds.TypeToPrint
--------------------------
-- Desc:		Given a ROUND_ enum will print a string of the round type.
-- Arg One:		ROUND_ enum, which round to get a string of.
-- Returns:		String, current round type.
local roundtypes = {
	[ROUND_WAITING] = "WAITING",
	[ROUND_PREP] = "PREP",
	[ROUND_ACTIVE] = "ACTIVE",
	[ROUND_POST] = "POST"
}
function trn.Rounds.TypeToPrint(state)
	return roundtypes[state] or "UNKNOWN (".. state ..")"
end

--------------------------
-- trn.Rounds.ClearTimers
--------------------------
-- Desc:		Removes the prep, post, and time run out timers.
function trn.Rounds.ClearTimers()
	if timer.Exists("trn.Rounds.PrepTime") then
		timer.Remove("trn.Rounds.PrepTime")
	end
	if timer.Exists("trn.Rounds.PostTime") then
		timer.Remove("trn.Rounds.PostTime")
	end
	if timer.Exists("trn.Rounds.CheckForTimeRunOut") then
		timer.Remove("trn.Rounds.CheckForTimeRunOut")
	end
end
