#include "Solver.h" 
#include "Command.h"
#include <iostream>
// FIFO that simulatos running memory of hardware(contains commands to be run) 
std::queue<Command> s_fifo ;
// Memory buffer that contains data to be used by commands

void Solver::ExecuteCmd( unit_t * mem ,const Command& cmd )  { 
    if (cmd.operation == Opcode_t::ADD) { 
        if (cmd.rtol) { 
            for (int i = cmd.count-1; i >= 0; --i) {
                mem[cmd.wrbackaddr+i] = mem[cmd.operand0+i] + mem[cmd.operand1+ i] ;
        } 
        } else { 
            for (int i = 0; i < cmd.count; i++) { 
                mem[cmd.wrbackaddr+ i] = mem[cmd.operand0+ i] + mem[cmd.operand1+ i] ;
            } 
        } 
    } else if (cmd.operation == Opcode_t::SUB) { 
        if (cmd.rtol) { 
            for (int i = cmd.count-1; i >= 0; i--){
                mem[cmd.wrbackaddr+ i] = mem[cmd.operand0+ i] - mem[cmd.operand1+ i] ;
            }
        } else { 

            for (int i = 0; i < cmd.count; i++) { 
                mem[cmd.wrbackaddr+ i] = mem[cmd.operand0+ i] - mem[cmd.operand1+ i] ;
            } 
        } 
    } else if (cmd.operation == Opcode_t::MMUL_2x) { // MMul2x (mat vec of 2x2) 
        // need to allocate mem for matmuls 
        unit_t vec[2] = {mem[cmd.operand1], mem[cmd.operand1+1]};
        mem[cmd.wrbackaddr]   = mem[cmd.operand0+1] * vec[0] + mem[cmd.operand0+2]*vec[1]; 
        mem[cmd.wrbackaddr+1] = mem[cmd.operand0]   * vec[0] + mem[cmd.operand0+1]*vec[1];
    } else { // MMul3x
        unit_t vec[3] = {mem[cmd.operand1], mem[cmd.operand1+1], mem[cmd.operand1+2]};
        mem[cmd.wrbackaddr]   = mem[cmd.operand0+2] * vec[0] + mem[cmd.operand0+3]*vec[1] + mem[cmd.operand0+4]*vec[2]; 
        mem[cmd.wrbackaddr+1] = mem[cmd.operand0+1] * vec[0] + mem[cmd.operand0+2]*vec[1] + mem[cmd.operand0+3]*vec[2];
        mem[cmd.wrbackaddr+2] = mem[cmd.operand0]   * vec[0] + mem[cmd.operand0+1]*vec[1] + mem[cmd.operand0+2]*vec[2];
    
    } 
} 
void Solver::ExecuteCmds( unit_t * mem ,const std::vector<Command>& cmds ) { 
    
    for (auto& cmd : cmds) { 
        ExecuteCmd(mem, cmd);  
    }
} 

