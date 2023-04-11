#pragma once 
#include "Buffer.h"
#include "Command.h"
#include <cstdint>
// Solver to ensure that computations generate by graph are equivalent to naive matrix multiplication 
using unit_t= int32_t ; 
class Solver{  
    static void ExecuteCmd( unit_t * mem ,const Command& cmd ) ;   
    static void ExecuteCmds( unit_t * mem ,const std::vector<Command>& cmds ) ;
} ; 
