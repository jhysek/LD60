const NOOP = 0 # no operation
const STEP = 1 # jump one cell forward
const TURN = 2 # turn left/right; arguments: 0001 - turn right, 0010 - turn left
const READ = 3 # read value in front of me, store it to memory; argument: memory address
const ADD  = 4 # picks item in front of me
const SET  = 5 
const COPY = 6  
const WRITE = 7

# TODO: conditions
const COMPARE = 8 # compare memory 0 with memory of given address and store result to memory 0 (0 = equal, 1 = smaller, 2 = greater)
const JUMP = 9    # jumps on line
const IF   = 10   # go to next line if memory 0 equals argument, otherwise skip next line

const NAMES = {
	NOOP: "NOOP",
	STEP: "STEP",
	TURN: "TURN",
	JUMP: "JUMP",
	READ: "READ",
	ADD: "ADD",
	SET: "SET",
	COPY: "COPY",
	WRITE: "WRITE"
}

const DESCRIPTIONS = {
	NOOP: "No operation. This does nothing. Arguments are ignored.",
	STEP: "One step forward.\nNo arguments.",
	TURN: "Turn left or right.\nArguments: 0010 - left, 0001 - right",
	JUMP: "Jump to program line.\nArgument: line number in binary",
	
	READ: "Read value from computer in front and store it in memory.\nArgument: target address of memory (0 - 15)",
	ADD: "Adds value in MEM to value in address 0 and store result to addres 0.\nArgument: MEM - address of memory (0 - 15)",
	SET: "Sets value to MEM.\nArgument: MEM - address of memory (0 - 15)",
	COPY: "Copy value in address 0 to MEM.\nArgument: MEM - address of memory (0 - 15)",
	WRITE: "Write value in MEM to terminal in front of me.\nArgument: MEM - address of memory (0 - 15)"
}
