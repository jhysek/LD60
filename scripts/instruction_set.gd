const NOOP = 0 # no operation
const STEP = 1 # jump one cell forward
const TURN = 2 # turn left/right; arguments: 0001 - turn right, 0010 - turn left
const READ = 3 # read value in front of me, store it to memory; argument: memory address
const PICK = 4 # picks item in front of me
const DROP = 5 # drops item on given neighbor; arguments 0000 - front, 0001 - right, 0010 - back, 0011 - left

const ADD  = 6    # sums value in memory on given address with memory 0 and store it to memory 0
const MUL  = 7    # multiply value in memory on given address with memory 0 and store it to memory 0
const COMPARE = 8 # compare memory 0 with memory of given address and store result to memory 0 (0 = equal, 1 = smaller, 2 = greater)
const JUMP = 9    # jumps on line
const IF   = 10   # go to next line if memory 0 equals argument, otherwise skip next line
