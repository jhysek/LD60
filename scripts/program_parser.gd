extends Object
class_name ProgramParser

func parse_line(program_line):
	var instruction_part = program_line.slice(0, 4)
	var argument_part = program_line.slice(5)

	return {
		instruction = binary_to_decimal(instruction_part),
		argument = binary_to_decimal(argument_part)
	}

func binary_to_decimal(binary_array):
	print("BUNARY TO DECIMAl")
	var result = 0
	var base = 1
	var reversed_array = binary_array.duplicate()
	reversed_array.reverse()
	
	print("REV ARRAY SIZE: ", reversed_array.size())
	# we want the least significant bit first - that's why reversing
	for bit in reversed_array:
		if bit:
			result += base 
		base = base * 2
	return result
