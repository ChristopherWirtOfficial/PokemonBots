WALK_FRAMES = 16
TURN_FRAMES = 4
WAIT_FRAMES = 16
PRESS_FRAMES = 2


-- Number of times in a row a move can be retried
-- before moving on to a different move, to avoid deadlocking
MAX_MOVE_RETRIES = 7
LEVEL_RETRY_CUTOFF = 15

POKECENTER_PATH = {{"Left", 12}, 
			 {"Up", 9},
			 {"Right", 1}
		}



POKE_LEVEL_ADDR = 0x1CFE
STATE_ADDR = 0x143A
IN_ATTACK_MENU_ADDR = 0x00CE
IN_ATTACK_MENU_VAL = 0x44
SELECTED_MOVE_ADDR = 0x0FA9

NEED_TO_WALK_STATE = 14
BONKING_1_STATE = 86
BONKING_2_STATE = 79
ENCOUNTER_STATE = 251
OUT_OF_POKE_STATE = 209
WHITED_OUT_STATE = 210
WHITING_OUT_1_STATE = 213
WHITING_OUT_2_STATE = 215
JUST_WON = 252
DONE_WINNING = 253


PP_ADDR = {0x1CF6, 0x1CF7, 0x1CF8, 0x1CF9}
ENEMY_HP_ADDR = 0x1217

last_move_used = 1
move_retries = 0
fighting = 0
fights = 0
deaths = 0
death_counter_locked = true
last_enemy_hp = -1 
whiffs = 0


function doFrame()
	emu.frameadvance();
	--console.log(joypad.get())
end

function waitFrames(dur)
	for i=1,dur,1 do
		doFrame()
	end
end

function walkTile(dir,duration)
	for i=1,duration,1 do
		for i=1,WALK_FRAMES,1 do
			local dpad = {}
			dpad[dir] = true
			joypad.set(dpad)
			doFrame()
		end
	end
end

function walkFromCenter()
	if not death_counter_locked then
		deaths = deaths + 1
		console.log("Deaths: " .. deaths)
		gui.addmessage("Deaths: " .. deaths)
		gui.addmessage("")
	end
	for pathIndex = 1, #POKECENTER_PATH do
		pathPart = POKECENTER_PATH[pathIndex]
		walkTile(pathPart[1], pathPart[2])
	end
end


function press(button)
	for i=1,PRESS_FRAMES,1 do
		local dpad = {}
		dpad[button] = true
		joypad.set(dpad)
		doFrame()
	end
end

function turn(dir)
	--console.log("Turning " .. dir)
	local dpad = {}
	for i=1,TURN_FRAMES,1 do
		dpad[dir] = true
		joypad.set(dpad)
		doFrame()
	end
	waitFrames(TURN_FRAMES*2)
end

function bonk()
	turn("Down")
	turn("Left")
end

function checkLevel()
	local level = memory.readbyte(POKE_LEVEL_ADDR, "WRAM")
	if level > LEVEL_RETRY_CUTOFF then
		MAX_MOVE_RETRIES = 1
	end
end

function checkWhiff()
	local enemy_hp = memory.readbyte(ENEMY_HP_ADDR, "WRAM")
	if last_enemy_hp == -1 then
		last_enemy_hp = enemy_hp
		return
	end
	if enemy_hp == last_enemy_hp then
		whiffs = whiffs + 1
		console.log("Whiffs: " .. whiffs)
		gui.addmessage("Whiffs: " .. whiffs)
		gui.addmessage("")
	end
	last_enemy_hp = enemy_hp
end

function finished_fight()
	fights = fights + 1
	console.log("Fights: " .. fights)
	gui.addmessage("Fights: " .. fights)
	gui.addmessage("")
end

-- Anything that happens when out of combat happens here
function not_fighting()
	if fighting == 1 then
		finished_fight()
	end
	fighting = 0
	move_retries = 0
	last_enemy_hp = -1
end

function handleEncounter()
	death_counter_locked = false
	if fighting == 0 then
		fighting = 1
	end
	checkLevel()
	state = memory.readbyte(IN_ATTACK_MENU_ADDR, "WRAM")
	if state == IN_ATTACK_MENU_VAL then
		checkWhiff()
		-- Check PP values and keep track of number 
		--  of move retries back to back to switch moves
		local current_move = memory.readbyte(SELECTED_MOVE_ADDR, "WRAM")
		if (last_move_used == current_move and move_retries >= MAX_MOVE_RETRIES) then
			-- We need to adjust the move we're using because it's probably not a damage move
			console.log("Switiching from ineffective move")
			press("Down")
			waitFrames(2*WAIT_FRAMES)
		end
		current_move = memory.readbyte(SELECTED_MOVE_ADDR, "WRAM")
		if last_move_used ~= current_move then 
			move_retries = 0
		end
		local current_pp = memory.readbyte(PP_ADDR[current_move], "WRAM")
		if current_pp == 0 then
			console.log("Move #" .. current_move .. " is out of PP!")
			press("Down")
			waitFrames(2*WAIT_FRAMES)
		else
			last_move_used = current_move
			move_retries = move_retries + 1
			console.log("Last Move: " .. last_move_used)
			console.log("Move retries: " .. move_retries)
			press("A")
			waitFrames(WAIT_FRAMES)
		end			
	else
		press("A")
		waitFrames(WAIT_FRAMES)
	end
end

while true do
	local state = memory.readbyte(STATE_ADDR, "WRAM")
	if state == NEED_TO_WALK_STATE then -- In front of pokemon center
		walkFromCenter()
		waitFrames(WALK_FRAMES)
	elseif state == BONKING_1_STATE or state == BONKING_2_STATE or state == DONE_WINNING then -- Ready to bonk, sir
		not_fighting()
		bonk()
	elseif state == ENCOUNTER_STATE then
		handleEncounter()
	else
		press("A")
		waitFrames(WAIT_FRAMES)
	end
end