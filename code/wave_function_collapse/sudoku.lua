-- Sodoku solver using Wave Function Collapse algorithm
local M = {}

local function get_cell_col(idx, sq)
	return (idx - 1) % sq + 1
end

local function get_cell_row(idx, sq)
	return math.floor((idx - 1) / sq) + 1
end

local function get_cell_idx(row, col, sq)
	return (row - 1) * sq + col
end

local function in_which_sub_grid(cell_idx)
	local row = get_cell_row(cell_idx, 11) - 1
	local col = get_cell_col(cell_idx, 11) - 1
	assert(row >= 1 and row <= 10 and col >= 1 and col <= 10, "Invalid cell index:", cell_idx)
	return math.ceil(row / 3), math.ceil(col / 3)
end

local function is_only_value(entropy_cell, value)
	return #entropy_cell == 1 and entropy_cell[1] == value
end

function M.print_grid(t)
	local p = {}
	local sq = math.floor(math.sqrt(#t))
	for i = 1, sq do
		local str = ""
		for j = 1, sq do
			str = str .. string.format("%2d", t[get_cell_idx(i, j, sq)])
		end
		table.insert(p, str)
	end
	print(table.concat(p, "\n"))
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

local function find_min_entropy_cell(m)
	local guard_grid = m.guard_grid
	local entropy_cells = m.entropy_cells

	local min_entropy = 10
	local cell_idxs = {}
	for i = 1, 121 do
		if guard_grid[i] == 0 then
			if #entropy_cells[i] < min_entropy then
				min_entropy = #entropy_cells[i]
				table.insert(cell_idxs, i)
			elseif #entropy_cells[i] == min_entropy then
				table.insert(cell_idxs, i)
			end
		end
	end
	if #cell_idxs == 0 then
		return 0
	else
		return cell_idxs[math.random(1, #cell_idxs)]
	end
end

local function get_affected_cells(idx)
	local cells = {}
	local col = get_cell_col(idx, 11)
	local row = get_cell_row(idx, 11)
	for i = 2, 10 do
		local row_idx = get_cell_idx(row, i, 11)
		if row_idx ~= idx then
			insert_unique_item(cells, row_idx)
		end
		local col_idx = get_cell_idx(i, col, 11)
		if col_idx ~= idx then
			insert_unique_item(cells, col_idx)
		end
	end
	local r, c = in_which_sub_grid(idx)
	local start_row = (r - 1) * 3
	local start_col = (c - 1) * 3
	for i = 1, 3 do
		for j = 1, 3 do
			local ceil_idx = get_cell_idx(start_row + i + 1, start_col + j + 1, 11)
			if ceil_idx ~= idx then
				insert_unique_item(cells, ceil_idx)
			end
		end
	end
	return cells
end

--[[ local function detect_valid()
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
end ]]
-- detect_valid()

local function make_value(m, cell_idx, entropy_value, remove_cells)
	local records = m.records
	local guard_grid = m.guard_grid
	local entropy_cells = m.entropy_cells
	local record = {}
	record.cell = cell_idx
	record.value = entropy_value
	record.entropys = entropy_cells[cell_idx]
	record.remove_cells = remove_cells
	table.insert(records, record)

	guard_grid[cell_idx] = entropy_value
	entropy_cells[cell_idx] = {}
end

local function undo_make(m)
	local guard_grid = m.guard_grid
	local entropy_cells = m.entropy_cells
	local records = m.records
	local last_record = table.remove(records)
	local cell_idx = last_record.cell
	local value = last_record.value
	local entropys = last_record.entropys

	guard_grid[cell_idx] = 0
	entropy_cells[cell_idx] = entropys

	for _, cell in ipairs(last_record.remove_cells) do
		table.insert(entropy_cells[cell], value)
	end
end

local function do_solve(m)
	local guard_grid = m.guard_grid
	local entropy_cells = m.entropy_cells

	local cell_idx = find_min_entropy_cell(m)
	if cell_idx == 0 then
		return true
	end

	assert(guard_grid[cell_idx] == 0, "Invalid cell index:", cell_idx)

	local vaild_move = false
	local entropy = entropy_cells[cell_idx]
	for _, entropy_value in ipairs(entropy) do
		local affected_cells = get_affected_cells(cell_idx)
		-- print(table.unpack(affected_cells))
		for _, affected_cell in ipairs(affected_cells) do
			if is_only_value(entropy_cells[affected_cell], entropy_value) then
				goto continue_loop
			end
		end

		local remove_cells = {}
		for _, affected_cell in ipairs(affected_cells) do
			if remove_item(entropy_cells[affected_cell], entropy_value) then
				table.insert(remove_cells, affected_cell)
			end
		end
		make_value(m, cell_idx, entropy_value, remove_cells)
		if do_solve(m) then
			vaild_move = true
			break
		end
		undo_make(m)

		::continue_loop::
	end
	return vaild_move
end

local function init_guard_grid(input_grid)
	local m = {}
	local guard_grid = {}
	local entropy_cells = {}
	m.guard_grid = guard_grid
	m.entropy_cells = entropy_cells
	m.records = {}

	local sq = 9 + 2
	for i = 1, sq do
		for j = 1, sq do
			local idx = get_cell_idx(i, j, sq)
			if i == 1 or i == sq or j == 1 or j == sq then
				guard_grid[idx] = -1
			else
				entropy_cells[idx] = {}
				local ii = get_cell_idx(i - 1, j - 1, 9)
				local value = input_grid[ii]
				if value == nil or value == 0 then
					guard_grid[idx] = 0
					for e = 1, 9 do
						table.insert(entropy_cells[idx], e)
					end
				else
					guard_grid[idx] = value
				end
			end
		end
	end

	-- remove entropy values
	for i = 2, 10 do
		for j = 2, 10 do
			local ci = get_cell_idx(i, j, 11)
			if guard_grid[ci] > 0 then
				local entropy_value = guard_grid[ci]
				local affected_cells = get_affected_cells(ci)
				for _, affected_cell in ipairs(affected_cells) do
					if guard_grid[affected_cell] == 0 then
						if is_only_value(entropy_cells[affected_cell], entropy_value) then
							return nil
						end
						remove_item(entropy_cells[affected_cell], entropy_value)
					end
				end
			end
		end
	end

	return m
end

function M.solve(s_grid)
	-- Initialize the grid with empty values
	local input_grid = s_grid or {}
	local m = init_guard_grid(input_grid)
	if not m then
		print("Invalid input grid.")
		return {}
	end

	while not do_solve(m) do
	end

	local output_grid = {}
	for i = 2, 10 do
		for j = 2, 10 do
			local idx = get_cell_idx(i, j, 11)
			table.insert(output_grid, m.guard_grid[idx])
		end
	end
	return output_grid
end

function M.generate(diff)
	diff = diff or 0.6
	if diff < 0.01 or diff > 0.99 then
		print("Invalid difficulty.")
		return nil, nil
	end

	local answer = M.solve()
	local output = {}
	for i = 1, 81 do
		if math.random() < diff then
			output[i] = 0
		else
			output[i] = answer[i]
		end
	end
	return output, answer
end

return M
