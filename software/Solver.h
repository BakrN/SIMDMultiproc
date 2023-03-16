#ifndef _SOLVER_H_
#define _SOLVER_H_

#include "Command.h"

#define VECTORSIZE 4
#define MATRIXSIZE (VECTORSIZE*2 -1)
#define TBUFFERSIZE 9 //TODO: Use correct formula for buffer size
#define VBUFFERSIZE 9
#define MATRIXCENTER (TBUFFERSIZE-1)/2

void solver_receive(command_t ** c);

void solver_print();


#endif //_SOLVER_H_