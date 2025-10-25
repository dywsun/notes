-- Sodoku solver using Wave Function Collapse algorithm

-- 11x11 contains 9x9 Sodoku puzzle with boundary cells
local grid = {}
local entropy_cells = {}

-- 1 - 9
local function get_cell_col(index)
	return (index - 1) % 11
end

-- 1 - 9
local function get_cell_row(index)
	return math.ceil(index / 11) - 1
end

-- 1 - 121
local function get_cell_index(row, col)
	return row * 11 + col + 1
end

-- @cell_index: index of the cell in the grid (1-based)
local function get_sub_grid(cell_index)
	local row = get_cell_row(cell_index)
	local col = get_cell_col(cell_index)
	assert(row >= 1 and row <= 10 and col >= 1 and col <= 10, "Invalid cell index:", cell_index)
	return (math.ceil(row / 3) - 1) * 3 + math.ceil(col / 3)
end

local function remove_possible_value(cell_index, value)
	local entropy_cell = entropy_cells[cell_index]
	assert(entropy_cell, "Entropy cell not found:", cell_index)
	for i, v in ipairs(entropy_cell) do
		if v == value then
			table.remove(entropy_cell, i)
			break
		end
	end
	if #entropy_cell == 0 and grid[cell_index] == 0 then
		return false
	else
		return true
	end
end

local function print_grid_all(t)
	for i = 1, 11 do
		local str = ""
		for j = 1, 11 do
			str = str .. string.format("%2d", t[(i - 1) * 11 + j])
			if j ~= 11 then
				str = str .. " "
			end
		end
		print(str)
	end
end

local function print_grid(t)
	for i = 1, 9 do
		local str = ""
		for j = 1, 9 do
			str = str .. t[get_cell_index(i, j)]
			if j ~= 9 then
				str = str .. " "
			end
		end
		print(str)
	end
end

local function find_min_entropy_cell()
	local min_entropy = 10
	local cell_indexs = {}
	for i = 1, 121 do
		if grid[i] == 0 then
			if #entropy_cells[i] < min_entropy then
				min_entropy = #entropy_cells[i]
				table.insert(cell_indexs, i)
			elseif #entropy_cells[i] == min_entropy then
				table.insert(cell_indexs, i)
			end
		end
	end
	-- print(table.unpack(cell_indexs))
	if #cell_indexs == 0 then
		return 0
	else
		return cell_indexs[math.random(1, #cell_indexs)]
	end
end

local function refresh_entropy_cells(idx, value)
	local col = get_cell_col(idx)
	local row = get_cell_row(idx)
	for i = 1, 9 do
		if not remove_possible_value(get_cell_index(row, i), value) then
			return false
		end
		if not remove_possible_value(get_cell_index(i, col), value) then
			return false
		end
	end
	local sub_grid_idx = get_sub_grid(idx)
	local start_row = (math.ceil(sub_grid_idx / 3) - 1) * 3
	local start_col = ((sub_grid_idx - 1) % 3) * 3
	for i = 1, 3 do
		for j = 1, 3 do
			local cell_idx = get_cell_index(start_row + i, start_col + j)
			if cell_idx ~= idx then
				if not remove_possible_value(cell_idx, value) then
					return false
				end
				break
			end
		end
	end
	return true
end

local function detect_valid()
	-- sub grids
	for row = 1, 9 do
		for col = 1, 9 do
			local idx = get_cell_index(row, col)
			local sub_grid_idx = get_sub_grid(idx)
			print(string.format("idx=%d, sub_grid_idx=%d", idx, sub_grid_idx))
			local start_row = (math.ceil(sub_grid_idx / 3) - 1) * 3
			local start_col = ((sub_grid_idx - 1) % 3) * 3
			print("sub grid start:", sub_grid_idx, start_row, start_col)
			for i = 1, 3 do
				for j = 1, 3 do
					local cell_idx = get_cell_index(start_row + i, start_col + j)
					print(string.format("cell idx (%d,%d)=%d", i, j, cell_idx))
				end
			end
		end
	end
end
-- detect_valid()

local function sodoku_solver()
	-- Initialize the grid with empty values
	grid = {}
	entropy_cells = {}

	for i = 1, 121 do
		local row = math.floor((i - 1) / 11)
		local col = (i - 1) % 11
		if row == 0 or row == 10 or col == 0 or col == 10 then
			grid[i] = -1
		else
			grid[i] = 0
			entropy_cells[i] = {}
			for c = 1, 9 do
				table.insert(entropy_cells[i], c)
			end
		end
	end

	while true do
		local cell_index = find_min_entropy_cell()
		if cell_index == 0 then
			return true
		end

		if grid[cell_index] == 0 then
			local entropy = entropy_cells[cell_index]
			local idx = math.random(1, #entropy)
			grid[cell_index] = entropy[idx]
			remove_possible_value(cell_index, entropy[idx])
			-- entropy_cells[cell_index] = {}
		end

		if not refresh_entropy_cells(cell_index, grid[cell_index]) then
			return false
		end
	end
end

while not sodoku_solver() do
end

print_grid(grid)
