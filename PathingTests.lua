PATH = {{33,8},
		{21,8},
		{21,3},
		{11,57},
		{11,53},
		{16,53},
		{16,37}
}

X_ADDR = 0x14E6
Y_ADDR = 0x14E7

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

path_index = 1

function doFrame()
	emu.frameadvance()
end

function waitFrames(count)
	for i=1,count,1 do
		doFrame()
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


function handleEncounter()
	state = memory.readbyte(IN_ATTACK_MENU_ADDR, "WRAM")
	if state == IN_ATTACK_MENU_VAL then
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


function walkToTile(dest_x,dest_y)
	local x = memory.readbyte(X_ADDR, "WRAM")
	local y = memory.readbyte(Y_ADDR, "WRAM")
	local dir = nil
	if x < dest_x then
		dir = "Right"
	elseif x > dest_x then
		dir = "Left"
	elseif y < dest_y then
		dir = "Down"
	elseif y > dest_y then
		dir = "Up"
	end
	if dir == nil then
		return true
	end
	for i=1,WALK_FRAMES,1 do
		local dpad = {}
		dpad[dir] = true
		joypad.set(dpad)
		doFrame()
	end
	return false
end

function walkPath()
	if path_index == #PATH + 1 then
		doFrame()
		return
	end
	x = PATH[path_index][1]
	y = PATH[path_index][2]
	if walkToTile(x,y) then
		path_index = path_index + 1
	end
end


while true do
	local state = memory.readbyte(STATE_ADDR, "WRAM")
	if state == ENCOUNTER_STATE then
		handleEncounter()
	else
		walkPath()
	end
end