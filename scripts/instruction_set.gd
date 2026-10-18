extends Node
# 1  STEP     ....  ○○○●
# 2  TURN     ....  ○○●○
# 3  READ     ....  ○○●●
# 4  ADD      ....  ○●○○
# 5  COPY     ....  ○●○●
# 6  WRITE    ....  ○●●○
# 7  DEC      ....  ○●●●
# 8  SET      ....  ●○○○
# 9  REP      ....  ●○○●
# 10 COMPARE  ....  ●○●○
# 11 JUMP_IF_EQ...  ●○●●
# 12 JUMP_IF_LESS.  ●●○○
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
const SET_COUNTER  = 7
const SET  = 8
const REP  = 9
const CMP  = 10
const JEQ  = 11
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
	SET_COUNTER: "SET COUNTER ADDR",
	CMP: "COMPARE",
	JEQ: "JUMP IF EQUAL",
	JL: "JUMP IF LESS",
	JUMP: "JUMP",
	CALL: "CALL",
	RET: "RET",
	REP: "REPEAT"
}


const DESCRIPTIONS = {
	NOOP: "No operation. This does nothing. Argument is ignored.",
	STEP: "One step forward.\nNo argument.",
	TURN: "Turn left or right.\nArgument: 0000 - left, 0001 - right",
	JUMP: "Jump to program line.\nArgument: line number in binary",
	READ: "Read value from computer in front and store it in memory.\nArgument: target address of memory (0 - 7)",
	ADD: "Adds value in MEM to value in address 0 and store result to addres 0.\nArgument: MEM - address of memory (0 - 7)",
	SET: "Sets memory 0 to given VAL.\nArgument: VAL - binary number",
	SET_COUNTER: "Sets address of repeat counter.\n\nArgument: MEM - address of memory (0 - 7).\nThis memory address will be updated and checked by REPEAT.",
	COPY: "Copy value in address 0 to MEM.\nArgument: MEM - address of memory (0 - 7)",
	WRITE: "Write value in MEM to terminal in front of me.\nArgument: MEM - address of memory (0 - 7)",
	CMP: "Compares memory 0 and MEM.\nArgument: MEM - address of memory to compare.",
	JEQ: "If last compared numbers were equal, jump to MEM.\nArgument: MEM - address to jump.",
	JL: "If value on last compared address was smaller than value on mem 0, jump to MEM.\nArgument: MEM - address to jump.",
	CALL: "Calls a procedure.\n\nArgument: MEM - address where procedure starts.",
	RET: "Returns from procedure - to address after the CALL instruction.\nNo argument.",
	REP: "If value in mem <COUNTER> is bigger than.\n\nArgument: MEM - address to jump.\n\nExample:\n1: SET 0100  ; save 4 to #0\n2: STEP\n3: REPEAT 0010  ; decrease counter and if counter > 0 go to line 2\n\nRepeats STEP 4x, using MEM #0 as counter.",
}
