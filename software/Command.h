#ifndef _COMMAND_H_
#define _COMMAND_H_

#include "Matrix.h"
#include "Vector.h"

typedef struct command command_t;

void command_create(command_t ** c, uint8_t opcode, command_t ** parent, int e0, int e1, int e2);

void command_send(command_t ** command);

int command_getId(command_t ** command);

uint8_t command_getOpcode(command_t ** command);

command_t ** command_getParent(command_t ** command);

int * command_getStarts(command_t ** command);



#endif //_COMMAND_H_