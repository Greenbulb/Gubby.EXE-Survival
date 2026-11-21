freeslot("MT_BOTPLAYER")
local MT_BOTPLAYER = MT_BOTPLAYER
mobjinfo[MT_BOTPLAYER] = { -- Exact copy of MT_PLAYER
	doomednum = -1,
	spawnstate = S_PLAY_STND, -- 11
	spawnhealth = 1,
	seestate = S_PLAY_WALK, -- 13
	seesound = 0,
	reactiontime = 0,
	attacksound = sfx_thok, -- 19
	painstate = S_PLAY_PAIN, -- 17
	painchance = 2,
	painsound = 0,
	meleestate = S_NULL, -- 0
	missilestate = S_PLAY_ROLL, -- 21
	deathstate = S_PLAY_DEAD, -- 19
	xdeathstate = S_PLAY_DRWN, -- 20
	deathsound = 0,
	speed = 1,
	radius = 16*FRACUNIT,
	height = 48*FRACUNIT,
	dispoffset = 0,
	mass = 1000,
	damage = 2,
	activesound = 0,
	flags = MF_SOLID|MF_SHOOTABLE, -- 6
	raisestate = S_NULL -- 0
}
-- MF_SOLID causes issues

-- Array of tables, each table includes a bot mobj and other info about it (essentially a player_t for the bots) used in other scripts to find them like players
-- All of that is a TODO but Shut up OK?
-- This isn't in global.lua because i want to (somewhat) keep this shit separate from other parts of ze2
ZE2.Bots = {}
addHook("NetVars", function(net)
	ZE2.Bots = net($)
end)

COM_AddCommand("spawnbot", function(player, skin, team, toself)
	if not (player.realmo and player.realmo.valid) then return end
	local mo = player.realmo
	
	local skint
	team = tonumber($)
	
	if not skin then
		skin = "sonic"
		skint = skins[skin]
	else
		skint = skins[skin]
	end
	
	if not (skint and skint.valid) then return end
	
	local sx, sy, sz, sa -- Spawn(X/Y/Z/Angle)
	if toself then
		sx, sy, sz, sa = mo.x, mo.y, mo.z, mo.angle/ANG1
	else
		local spawns = {}
		for mapthing in mapthings.iterate do
			if not (mapthing and mapthing.valid) then continue end
			
			--print(#mapthing)
			if mapthing.type >= 1 and mapthing.type <= 33 then -- player starts 1-32 plus match starts
				table.insert(spawns, mapthing)
			end
		end
		local chosenspawn = spawns[P_RandomRange(1, #spawns)]
		sx, sy, sz, sa = chosenspawn.x, chosenspawn.y, chosenspawn.z, chosenspawn.angle
	end
	
	local bot = P_SpawnMobj(sx, sy, sz, MT_BOTPLAYER)
	if bot and bot.valid then
		bot.angle = sa * ANG1
		bot.skin = skin
		bot.color = skint.prefcolor
		if team then
			bot.team = team
		else
			bot.team = mo.team
		end
		bot.bot = true
		-- somehow setting this completely fucks it up
		--bot.radius = skint.radius
		--bot.height = skint.height
	end
end, COM_ADMIN)

local function botCollideWithPlayer(bot, movingmobj)
	if not (movingmobj and movingmobj.valid) then return end
	
	if movingmobj.player and movingmobj.player.valid -- Disable collisions between real players...
	or movingmobj.type == MT_BOTPLAYER -- ...or between other bots
	then
		return false
	end
end
addHook("MobjCollide", botCollideWithPlayer, MT_BOTPLAYER)

-- very barebones bullshit, just to get it rolling
-- should pretty much just copy current bot behaviour
local function botThinker(bot)
	/*local closestplayer
	for player in players.iterate do
		if not (player and player.valid and player.realmo and player.realmo.valid) then continue end
		if player.spectator then continue end
		
		if closestplayer == nil then
			closestplayer = player
		else
			
		end
	end*/
	if not (bot and bot.valid) then return end
	local skint = bot.team == 1 and ZE2.SurvivorConfig[bot.skin] or bot.team == 2 and ZE2.ZombieConfig["normal"] or skins[bot.skin] -- TODO: make zombieconfig proper
	
	P_LookForPlayers(bot, 0, true, false) -- no tracer for now
	if bot.target and bot.target.valid then
		bot.angle = R_PointToAngle2(bot.x, bot.y, bot.target.x, bot.target.y)
		P_Move(bot, skint.normalspeed) -- TDPrimal
	end
end
addHook("MobjThinker", botThinker, MT_BOTPLAYER)