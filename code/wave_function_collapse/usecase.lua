local sudoku = require("sudoku")
local level, answer = sudoku.generate(tonumber(arg[1]))

print("generate new sudoku:")
sudoku.print_grid(level)
print("generate new sudoku's answer:")
sudoku.print_grid(answer)

print("solve the sudoku:")
local solution = sudoku.solve(level)
sudoku.print_grid(solution)
