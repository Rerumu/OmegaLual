local Image;
local Rex, Rey;
local Cluster;
local State;

local MegaLuls = {};
local Gridsz = 24; -- Grid size, customizable

--[[
	Regarding the change of style in `enum.lua` and `cluster.lua`,
	I simply didn't put much effort into making them consistent with
	the main code, and just made them as sort of side libraries.
]]

-- Runtime settings
local DEBUG_CURSOR = true; -- keybind @c
local DEBUG_NODES = true; -- keybind @n
local SHOW_LULS = true; -- keybind @l
-- To reset board press "r"

local function GetXY(x, y)
	return math.floor(x / Rex),
			math.floor(y / Rey);
end

local function RenderCanvas()
	local Clus = Cluster:divide(); -- Get cluster list
	MegaLuls = {};
	-- Loop calculates the cluster edges
	for _, Cls in ipairs(Clus) do
		local Edges = {};
		local Lims = {
			MinX = Gridsz;
			MinY = Gridsz;
			MaxX = 0;
			MaxY = 0;
		};
		for _, Nd in ipairs(Cls) do
			local Sides = Cluster:sides(Nd);
			Nd.edge = false;
			if (Sides[1].state and Sides[3].state)
			== (Sides[2].state and Sides[4].state) then -- Check if empty sides on both X and Y
				if not (Sides[1].state and Sides[3].state) then -- Check if not all sides are taken
					local Edg = {
						x = Nd.x + 0.5, -- Offset to middle
						y = Nd.y + 0.5
					};
					Lims.MinX = math.min(Lims.MinX, Nd.x);
					Lims.MinY = math.min(Lims.MinY, Nd.y);
					Lims.MaxX = math.max(Lims.MaxX, Nd.x);
					Lims.MaxY = math.max(Lims.MaxY, Nd.y);
					for _, Side in pairs(Sides) do
						if (not Side.state) then -- Loop over empty sides and move middle accordingly
							Edg.x = Edg.x - (Nd.x - Side.x) / 2;
							Edg.y = Edg.y - (Nd.y - Side.y) / 2;
						end
					end -- This loop ensures a proper edge
					Nd.edge = true;
					table.insert(Edges, {
						Edg.x, Edg.y, Nd.x, Nd.y -- Keep original position data
					});
				end
			end
		end
		if (#Edges > 2) then
			Lims.MaxX = Lims.MaxX - Lims.MinX; -- Get non-offset max
			Lims.MaxY = Lims.MaxY - Lims.MinY;
			for _, Edge in pairs(Edges) do
				Edge[1] = Edge[1] * Rex; -- Normalize the coordinates
				Edge[2] = Edge[2] * Rey;
				Edge[3] = (Edge[3] - Lims.MinX) / Lims.MaxX; -- Calculate UV mapping using the difference in...
				Edge[4] = (Edge[4] - Lims.MinY) / Lims.MaxY; -- ... the edge position divided by its largest extent
			end
			table.insert(MegaLuls, love.graphics.newMesh(Edges, 'fan', 'static')); -- Make the Mesh
		end
	end
end

function love.load()
	assert(love.window.setMode(600, 600), 'Failed to set window size'); -- Make sure we have the right size
	local Max = love.graphics.getWidth();
	local May = love.graphics.getHeight();

	love.window.setTitle('Omegalul Painter');
	Image = love.graphics.newImage('omegalol.png'); -- Load stuff
	Rex, Rey = Max / Gridsz, May / Gridsz;
	Cluster = require('cluster').new();
	State = 'Waiting';
end

function love.keypressed(Key) -- Debug and clear stuff
	if (Key == 'c') then
		DEBUG_CURSOR = not DEBUG_CURSOR;
	elseif (Key == 'n') then
		DEBUG_NODES = not DEBUG_NODES;
	elseif (Key == 'l') then
		SHOW_LULS = not SHOW_LULS;
	elseif (Key == 'r') then -- reset board
		for _, Clus in pairs(Cluster.nodes) do
			for _, Nd in pairs(Clus) do
				Nd.state = false;
			end
		end
		State = 'Waiting';
	end
end

function love.update()
	local MX, MY = GetXY(love.mouse.getPosition()); -- Get clamped position

	if love.mouse.isDown(1, 2) then -- Set/unset current
		local Prev = Cluster:get(MX, MY).state;
		if love.mouse.isDown(1) then
			Cluster:set(MX, MY, true);
		elseif love.mouse.isDown(2) then
			Cluster:set(MX, MY, false);
		end
		if (Cluster:get(MX, MY).state ~= Prev) then
			State = 'Waiting';
		end
	end

	if (State == 'Waiting') then
		RenderCanvas();
		State = 'Drawn';
	end
end

function love.draw()
	local Dr = 0;
	for _, Ry in pairs(Cluster.nodes) do -- Render debug nodes
		for _, Nd in pairs(Ry) do
			if Nd.state then
				if DEBUG_NODES then
					if Nd.edge then
						love.graphics.setColor(0.5, 0.2, 0.2);
					else
						love.graphics.setColor(0.2, 0.2, 0.5);
					end;

					love.graphics.rectangle('fill', Nd.x * Rex, Nd.y * Rey, Rex, Rey);
				end
				Dr = Dr + 1;
			end
		end
	end

	love.graphics.setColor(1, 1, 1);
	if SHOW_LULS then
		for _, Mesh in pairs(MegaLuls) do -- Render meshes
			Mesh:setTexture(Image);
			love.graphics.draw(Mesh);
		end
	end

	if DEBUG_CURSOR then
		local Xpos, Ypos = love.mouse.getPosition(); -- Show debug info at cursor
		love.graphics.printf(string.format('%i nodes, %i fps', Dr, love.timer.getFPS()),
			Xpos,
			Ypos,
			love.graphics.getWidth() - Xpos
		);
	end
end
