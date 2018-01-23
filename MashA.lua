max = 0
min = 9999
last = 0
last_payout = 0
paying_out = 0
attempts = -1
wins = 0

payouts = {
	[6]   = 0,
	[8]   = 0,
	[10]  = 0,
	[15]  = 0,
	[50]  = 0,
	[300] = 0
}

values = {
	[0] = 6,
	[1] = 8,
	[2] = 10,
	[3] = 15,
	[4] = 50,
	[5] = 300
}

colors = {
	[0] = 0xFFDD2255,
	[1] = 0xFFA000A0,
	[2] = 0xFF3344AA,
	[3] = 0xFF44BBDD,
	[4] = 0xFF30AA88,
	[5] = 0xFF00BB14
}




COINS  = 0x1855
PAYOUT = 0x0711

TEXT_COLOR = 0xFF000000

BAR_WIDTH = 14
BAR_MAX_HEIGHT = 20
BAR_V_PADDING = 7
BAR_H_PADDING = 3

TEXT_H_PADDING = 2
TEXT_V_PADDING = -3

GRAPH_START_X = 5
GRAPH_START_Y = 103
GRAPH_WIDTH = 148
GRAPH_HEIGHT = BAR_MAX_HEIGHT + BAR_V_PADDING*2 + 1
GRAPH_LEFT_PADDING = (GRAPH_WIDTH - 6*(BAR_H_PADDING+BAR_WIDTH)) / 2 + 16

GRAPH_BG = 0xFFA0A0A0


function draw_bar(index, height)
	x = GRAPH_LEFT_PADDING + (BAR_WIDTH + BAR_H_PADDING) * index + BAR_H_PADDING + GRAPH_START_X
	start_y = (BAR_MAX_HEIGHT + BAR_V_PADDING) - height + GRAPH_START_Y
	color = colors[index]
	gui.drawRectangle(x, start_y, BAR_WIDTH, height, color, color)
	gui.pixelText(x+TEXT_H_PADDING,start_y - BAR_V_PADDING, payouts[values[index]], TEXT_COLOR, GRAPH_BG)
	gui.pixelText(x,GRAPH_START_Y + GRAPH_HEIGHT + (2*TEXT_V_PADDING), values[index], TEXT_COLOR, GRAPH_BG)
	
end

function draw_graphs()
	gui.drawRectangle(GRAPH_START_X,GRAPH_START_Y,GRAPH_WIDTH,GRAPH_HEIGHT,GRAPH_BG,GRAPH_BG)
	local winrate = 0
	if attempts > 0
	then
		winrate = math.floor(wins / attempts * 100)
	end
	if winrate < 10
	then
		winrate = " " .. winrate
	end
	gui.pixelText(GRAPH_START_X + BAR_H_PADDING, 2 + GRAPH_START_Y - TEXT_V_PADDING,"Rate:" .. winrate .. "%")
	gui.pixelText(GRAPH_START_X + BAR_H_PADDING, 2 + GRAPH_START_Y - 4*TEXT_V_PADDING,"Wins:  " .. wins)
	if attempts >= 0
	then
		gui.pixelText(GRAPH_START_X + BAR_H_PADDING, 2 + GRAPH_START_Y - 7*TEXT_V_PADDING,"Tries: " .. attempts)
	end

	local low = 999999
	local high = 0	
	for i = 0,5,1
	do
		val = payouts[values[i]]
		if val < low
		then
			low = val
		end
		if val > high
		then
			high = val
		end
	end
	if (high - low) == 0
	then
		high = high + 1
	end
	local norm_factor = BAR_MAX_HEIGHT / (high - low)
	for i = 0,5,1
	do
		height = math.floor(payouts[values[i]] * norm_factor)
		if height == 0
		then
			height = 1
		end
		draw_bar(i, height)
	end
end



while true do
	draw_graphs()
	joypad.set({A = false})
	emu.frameadvance();
	joypad.set({A = true})
	draw_graphs()
	emu.frameadvance();
	local current = memory.read_u16_be(COINS,"WRAM")
	if current > high then
		high = current
	end
	if current < low then
		low = current
	end
	local pay_val = memory.read_u16_be(PAYOUT,"WRAM")
	if pay_val ~= 0 then
		if paying_out == 0 then
			paying_out = 1
			wins = wins + 1
			payouts[pay_val] = payouts[pay_val] + 1
			console.log("Paying out: " .. pay_val .. " coins - " .. payouts[pay_val] .. " times")
		end
	else
	--Not paying out, so do other logic here if you want to make that assumption
		if current == (last - 3) then
			attempts = attempts + 1
			winrate = (wins * 100) / attempts
			--console.log("Success rate: " .. winrate .. "(" .. wins .. "/" .. attempts .. ")")
		end
		last = current
		paying_out = 0
	end
end
