#ifndef _COMMAND_H_
#define _COMMAND_H_

#include "Matrix.h"
#include "Vector.h"

typedef struct command command_t;

void command_create(bool flag, void ** e0, void ** e1, void ** e2);

void command_send(command_t ** command);



#endif //_COMMAND_H_