local cluster = {};
local meta = {
	__index = cluster;
	__metatable = 'pxlcls';
};

function cluster.new() -- Create new cluster
	return setmetatable({
		nodes = {};
	}, meta);
end

function cluster:getlist(idx, nocache) -- Get list at position
	local list = self.nodes[idx];
	if not list then
		list = {};
		if not nocache then
			self.nodes[idx] = list;
		end
	end
	return list;
end

function cluster:get(x, y, nocache) -- Get node at coordinate
	local l = self:getlist(y, nocache);
	local r = l[x];
	if not r then
		r = {
			state = false;
			x = x;
			y = y;
		}
		if not nocache then
			l[x] = r;
		end
	end
	return r;
end

function cluster:set(x, y, state) -- Set node state at coordinate
	self:get(x, y).state = state;
end

function cluster:sides(node) -- Get the sides of a node
	return {
		self:get(node.x + 1, node.y, true), -- right
		self:get(node.x, node.y + 1, true), -- below
		self:get(node.x - 1, node.y, true), -- left
		self:get(node.x, node.y - 1, true), -- above
	};
end

function cluster:expand(node, ign) -- Recursively get list of active connected nodes
	local ret = {node};
	local sides = self:sides(node);
	ign[node] = true;
	for _, side in ipairs(sides) do
		if side.state and not ign[side] then
			for _, x in ipairs(self:expand(side, ign)) do
				table.insert(ret, x);
			end
		end
	end
	return ret;
end

function cluster:divide() -- Get all connected clusters
	local cls = {};
	local ign = {};
	for _, list in pairs(self.nodes) do
		for _, nd in pairs(list) do
			if nd.state and not ign[nd] then
				table.insert(cls, self:expand(nd, ign));
			end
		end
	end
	return cls;
end

return cluster;