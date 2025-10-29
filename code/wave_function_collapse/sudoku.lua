-- Sodoku solver using Wave Function Collapse algorithm

-- 11x11 contains 9x9 Sodoku puzzle with boundary cells
local grid = {}
local entropy_cells = {}
local records = {}

-- 1 - 9
local function get_ceil_col(index)
	return (index - 1) % 11
end

-- 1 - 9
local function get_ceil_row(index)
	return math.ceil(index / 11) - 1
end

-- 1 - 121
local function get_ceil_index(row, col)
	return row * 11 + col + 1
end

-- @cell_index: index of the cell in the grid (1-based)
local function get_sub_grid(cell_index)
	local row = get_ceil_row(cell_index)
	local col = get_ceil_col(cell_index)
	assert(row >= 1 and row <= 10 and col >= 1 and col <= 10, "Invalid cell index:", cell_index)
	return (math.ceil(row / 3) - 1) * 3 + math.ceil(col / 3)
end

local function is_only_value(cell_index, value)
	local entropy_cell = entropy_cells[cell_index]
	assert(entropy_cell, "Entropy cell not found:", cell_index)
	return #entropy_cell == 1 and entropy_cell[1] == value
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
			str = str .. t[get_ceil_index(i, j)]
			if j ~= 9 then
				str = str .. " "
			end
		end
		print(str)
	end
end

local function print_sudoku(t)
	for i = 1, 9 do
		local str = ""
		for j = 1, 9 do
			str = str .. t[(i - 1) * 9 + j]
			if j ~= 9 then
				str = str .. " "
			end
		end
		print(str)
	end
end

local function contains_item(t, item)
	for _, v in ipairs(t) do
		if v == item then
			return true
		end
	end
	return false
end

local function insert_unique_item(t, item)
	if not contains_item(t, item) then
		table.insert(t, item)
	end
end

local function remove_item(t, item)
	for i, v in ipairs(t) do
		if v == item then
			table.remove(t, i)
			return true
		end
	end
	return false
end

local function find_min_entropy_cell()
	local min_entropy = 10
	local ceil_indexs = {}
	for i = 1, 121 do
		if grid[i] == 0 then
			if #entropy_cells[i] < min_entropy then
				min_entropy = #entropy_cells[i]
				table.insert(ceil_indexs, i)
			elseif #entropy_cells[i] == min_entropy then
				table.insert(ceil_indexs, i)
			end
		end
	end
	-- print(table.unpack(cell_indexs))
	if #ceil_indexs == 0 then
		return 0
	else
		return ceil_indexs[math.random(1, #ceil_indexs)]
	end
end

local function get_affected_ceils(idx, value)
	local ceils = {}
	local col = get_ceil_col(idx)
	local row = get_ceil_row(idx)
	for i = 1, 9 do
		local row_idx = get_ceil_index(row, i)
		if row_idx ~= idx then
			insert_unique_item(ceils, row_idx)
		end
		local col_idx = get_ceil_index(i, col)
		if col_idx ~= idx then
			insert_unique_item(ceils, col_idx)
		end
	end
	local sub_grid_idx = get_sub_grid(idx)
	local start_row = (math.ceil(sub_grid_idx / 3) - 1) * 3
	local start_col = ((sub_grid_idx - 1) % 3) * 3
	for i = 1, 3 do
		for j = 1, 3 do
			local ceil_idx = get_ceil_index(start_row + i, start_col + j)
			if ceil_idx ~= idx then
				insert_unique_item(ceils, ceil_idx)
			end
		end
	end
	return ceils
end

local function detect_valid()
	-- sub grids
	for row = 1, 9 do
		for col = 1, 9 do
			local idx = get_ceil_index(row, col)
			local sub_grid_idx = get_sub_grid(idx)
			print(string.format("idx=%d, sub_grid_idx=%d", idx, sub_grid_idx))
			local start_row = (math.ceil(sub_grid_idx / 3) - 1) * 3
			local start_col = ((sub_grid_idx - 1) % 3) * 3
			print("sub grid start:", sub_grid_idx, start_row, start_col)
			for i = 1, 3 do
				for j = 1, 3 do
					local cell_idx = get_ceil_index(start_row + i, start_col + j)
					print(string.format("cell idx (%d,%d)=%d", i, j, cell_idx))
				end
			end
		end
	end
end
-- detect_valid()

local function make_value(ceil_index, entropy_value, remove_ceils)
	local record = {}
	record.ceil = ceil_index
	record.value = entropy_value
	record.entropys = entropy_cells[ceil_index]
	record.remove_ceils = remove_ceils
	table.insert(records, record)

	grid[ceil_index] = entropy_value
	entropy_cells[ceil_index] = {}
end

local function undo_make()
	local last_record = table.remove(records)
	local ceil_index = last_record.ceil
	local value = last_record.value
	local entropys = last_record.entropys

	grid[ceil_index] = 0
	entropy_cells[ceil_index] = entropys

	for _, ceil in ipairs(last_record.remove_ceils) do
		table.insert(entropy_cells[ceil], value)
	end
end

local function do_solve()
	local ceil_index = find_min_entropy_cell()
	if ceil_index == 0 then
		return true
	end

	assert(grid[ceil_index] == 0, "Invalid cell index:", ceil_index)

	local vaild_move = false
	local entropy = entropy_cells[ceil_index]
	for _, entropy_value in ipairs(entropy) do
		local affected_ceils = get_affected_ceils(ceil_index, entropy_value)
		-- print(table.unpack(affected_ceils))
		for _, affected_ceil in ipairs(affected_ceils) do
			if is_only_value(affected_ceil, entropy_value) then
				goto continue_loop
			end
		end

		local remove_ceils = {}
		for _, affected_ceil in ipairs(affected_ceils) do
			if remove_item(entropy_cells[affected_ceil], entropy_value) then
				table.insert(remove_ceils, affected_ceil)
			end
		end
		make_value(ceil_index, entropy_value, remove_ceils)
		if do_solve() then
			vaild_move = true
			break
		end
		undo_make()

		::continue_loop::
	end
	return vaild_move
end

local function init_grid(input_grid)
	for i = 1, 121 do
		local row = math.floor((i - 1) / 11)
		local col = (i - 1) % 11
		if row == 0 or row == 10 or col == 0 or col == 10 then
			grid[i] = -1
		else
			entropy_cells[i] = {}
			local r = get_ceil_row(i)
			local c = get_ceil_col(i)
			local idx = (r - 1) * 9 + c
			if input_grid[idx] == nil or input_grid[idx] == 0 then
				grid[i] = 0
				for e = 1, 9 do
					table.insert(entropy_cells[i], e)
				end
			else
				grid[i] = input_grid[idx]
			end
		end
	end

	-- remove entropy values
	for i = 1, 9 do
		for j = 1, 9 do
			local ceil_idx = get_ceil_index(i, j)
			if grid[ceil_idx] > 0 then
				local entropy_value = grid[ceil_idx]
				local affected_ceils = get_affected_ceils(ceil_idx, grid[ceil_idx])
				for _, affected_ceil in ipairs(affected_ceils) do
					if grid[affected_ceil] == 0 then
						if is_only_value(affected_ceil, entropy_value) then
							return false
						end
						remove_item(entropy_cells[affected_ceil], entropy_value)
					end
				end
			end
		end
	end

	return true
end

local function sodoku_solver(s_grid)
	-- Initialize the grid with empty values
	grid = {}
	entropy_cells = {}
	records = {}

	local input_grid = s_grid or {}
	if not init_grid(input_grid) then
		print("Invalid input grid.")
		return {}
	end

	while not do_solve() do
	end

	local output_grid = {}
	for i = 1, 121 do
		local row = math.floor((i - 1) / 11)
		local col = (i - 1) % 11
		if row == 0 or row == 10 or col == 0 or col == 10 then
		else
			table.insert(output_grid, grid[i])
		end
	end

	return output_grid
end

local function generate_sudoku()
	local answer = sodoku_solver()
	local output = {}
	for i = 1, 121 do
		if math.random() < 0.7 then
			output[i] = 0
		else
			output[i] = answer[i]
		end
	end
	return output, answer
end

local level, answer = generate_sudoku()

print("generate new sudoku:")
print_sudoku(level)
print("generate new sudoku's answer:")
print_sudoku(answer)

print("solve the sudoku:")
local solution = sodoku_solver(level)
print_sudoku(solution)
