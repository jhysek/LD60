# 1  STEP     ....  ○○○●
# 2  TURN     ....  ○○●○
# 3  READ     ....  ○○●●
# 4  ADD      ....  ○●○○
# 5  COPY     ....  ○●○●
# 6  WRITE    ....  ○●●○
# 7  SET      ....  ○●●●
# 8  COMPARE   ...  ●○○○
# 9  JUMP_IF_EQ ..  ●○○●
# 10 JUMP_NOT_EQ .. ●○●○
# 11 JUMP_IF_GE ... ●○●●
# 12 JUMP_IF_LESS . ●●○○
# 13 JUMP      .... ●●○●
# 14 CALL      .... ●●●○
# 15 RET       .... ●●●●


const NOOP = 0 # no operation
const STEP = 1 # jump one cell forward
const TURN = 2 # turn left/right; arguments: 0001 - turn right, 0010 - turn left
const READ = 3 # read value in front of me, store it to memory; argument: memory address
const ADD  = 4 # picks item in front of me
const COPY = 5 
const WRITE = 6
const SET  = 7
const CMP  = 8
const JEQ  = 9
const JNE  = 10
const JGE  = 11
const JL   = 12 
const JUMP = 13
const CALL = 14
const RET = 15

const NAMES = {
	NOOP: "NOOP",
	STEP: "STEP",
	TURN: "TURN",
	READ: "READ",
	ADD: "ADD",
	COPY: "COPY",
	WRITE: "WRITE",
	SET: "SET",
	CMP: "COMPARE",
	JEQ: "JUMP IF EQUAL",
	JNE: "JUMP IF NOT EQUAL",
	JGE: "JUMP IF GREATER OR EQUAL",
	JL: "JUMP IF LESS",
	JUMP: "JUMP",
	CALL: "CALL",
	RET: "RET"
}
	


const DESCRIPTIONS = {
	NOOP: "No operation. This does nothing. Arguments are ignored.",
	STEP: "One step forward.\nNo arguments.",
	TURN: "Turn left or right.\nArguments: 0010 - left, 0001 - right",
	JUMP: "Jump to program line.\nArgument: line number in binary",
	READ: "Read value from computer in front and store it in memory.\nArgument: target address of memory (0 - 7)",
	ADD: "Adds value in MEM to value in address 0 and store result to addres 0.\nArgument: MEM - address of memory (0 - 7)",
	SET: "Sets memory 0 to given VAL.\nArgument: VAL - binary number",
	COPY: "Copy value in address 0 to MEM.\nArgument: MEM - address of memory (0 - 7)",
	WRITE: "Write value in MEM to terminal in front of me.\nArgument: MEM - address of memory (0 - 7)",
	CMP: "Compares memory 0 and MEM.\nArguments: MEM - address of memory to compare.",
	JEQ: "If last compared numbers were equal, jump to MEM.\n Arguments: MEM - address to jump.",
	JNE: "If last compared numbers were NOT equal, jump to MEM.\n Arguments: MEM - address to jump.",
	JGE: "If value on last compared address was greater or equal to value on mem 0, jump to MEM.\n Arguments: MEM - address to jump.",
	JL: "If value on last compared address was smaller than value on mem 0, jump to MEM.\n Arguments: MEM - address to jump.",
	CALL: "Calls a procedure. Arguments:\n MEM - address where procedure starts.",
	RET: "Returns from procedure - to address after the CALL instruction.\n No argumens."
}
