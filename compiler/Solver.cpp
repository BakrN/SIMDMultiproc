#include "Solver.h" 
#include "Command.h"

// FIFO that simulatos running memory of hardware(contains commands to be run) 
std::queue<Command> s_fifo ;
// Memory buffer that contains data to be used by commands

void Solver::ExecuteCmd( unit_t * mem ,const Command& cmd )  { 
    if (cmd.operation == Opcode_t::ADD) { 
        for (int i = 0; i < cmd.count; i++) { 
            mem[cmd.wrbackaddr+ i] = mem[cmd.operand0+ i] + mem[cmd.operand1+ i] ;
        } 
    } else if (cmd.operation == Opcode_t::SUB) { 
        for (int i = 0; i < cmd.count; i++) { 
            mem[cmd.wrbackaddr+ i] = mem[cmd.operand0+ i] - mem[cmd.operand1+ i] ;
        } 
    } else if (cmd.operation == Opcode_t::MMUL_2x) { // MMul2x
                                                     // matrix multiplication of 2x2 matrix
        mem[cmd.wrbackaddr]   = mem[cmd.operand0+1] * mem[cmd.operand1] + mem[cmd.operand0+2] * mem[cmd.operand1+1] ;
        mem[cmd.wrbackaddr+1] = mem[cmd.operand0] * mem[cmd.operand1] + mem[cmd.operand0+1] * mem[cmd.operand1+1] ;
    } else { // MMul3x
        mem[cmd.wrbackaddr]   = mem[cmd.operand0+2] * mem[cmd.operand1] + mem[cmd.operand0+3] * mem[cmd.operand1+1] + mem[cmd.operand0+4]*mem[cmd.operand1+2] ; 
        mem[cmd.wrbackaddr+1] = mem[cmd.operand0+1] * mem[cmd.operand1] + mem[cmd.operand0+2] * mem[cmd.operand1+1] + mem[cmd.operand0+3]*mem[cmd.operand1+2] ;
        mem[cmd.wrbackaddr+2] = mem[cmd.operand0] * mem[cmd.operand1] + mem[cmd.operand0+1] * mem[cmd.operand1+1] + mem[cmd.operand0+2]*mem[cmd.operand1+2] ;
        
    } 
} 
void Solver::ExecuteCmds( unit_t * mem ,const std::vector<Command>& cmds ) { 
    for (auto& cmd : cmds) { 
        ExecuteCmd(mem, cmd);  
    }
} 

