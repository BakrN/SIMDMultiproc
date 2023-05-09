#include "Solver.h" 
#include "Command.h" 
#include "config.h"
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
    } else { // MMul2x (mat vec of 2x2) 
        // need to allocate mem for matmuls 
        int size = (cmd.operation==Opcode_t::MMUL_2x) ? BASE_MMUL_2x_SIZE : BASE_MMUL_3x_SIZE;
        unit_t vec[size];  
        for (int i = 0 ; i <size; i++) { 
            vec[i] = mem[cmd.operand1+i];  
            mem[cmd.wrbackaddr+i] = 0;
        }
        // mat mul section 
        for ( int row = 0 ; row < size; row++) { 
            for (int col = 0 ; col < size; col++) { 
                mem[cmd.wrbackaddr+row] += mem[ (size)-1 - row + col + cmd.operand0] * vec[col];  
            } 
        }
    } 
} 
void Solver::ExecuteCmds( unit_t * mem ,const std::vector<Command>& cmds ) { 
    
    for (auto& cmd : cmds) { 
        ExecuteCmd(mem, cmd);  
    }
} 

