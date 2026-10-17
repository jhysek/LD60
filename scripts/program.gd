extends Control

var max_rows = 32
var program = []

func initialize_empty_program(_max_rows):
	max_rows = _max_rows
	for y in max_rows:
		program.append([false, false, false, false, null, false, false, false, false, false])
	print(program) 

func punch_at(column, row):
	if column == 4:
		print("ERROR: attempt to punch at column 4, ignoring...")
		return
		 
	assert(column >= 0 && column <= 9, "Program.punch_at: INVALID COLUMN " + str(column))
	assert(row >= 0 && row < program.size(), "Program.punch_at: INVALID ROW " + str(row))
	
	print("PUNCH " + str(column) + " x " + str(row))
	program[row][column] = !program[row][column]
		
func value_at(column, row):
	assert(column >= 0 && column <= 9, "Program.punch_at: INVALID COLUMN " + str(column))
	assert(row >= 0 && row < program.size(), "Program.punch_at: INVALID ROW " + str(row))
	
	return program[row][column]
	
func get_line(row):
	assert(row >= 0 && row < program.size(), "Program.punch_at: INVALID ROW " + str(row))
	return program[row]
	
