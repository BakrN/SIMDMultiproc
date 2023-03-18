#ifndef _COMMAND_H_
#define _COMMAND_H_

#include "Matrix.h"
#include "Vector.h"

typedef struct command command_t;

void command_create(uint8_t opcode,int id, int parent_id, int e0, int e1, int e2, int store, uint16_t storeSize);

void command_send(command_t ** command);

int command_getId(command_t ** command);

uint8_t command_getOpcode(command_t ** command);

int command_getParentId(command_t ** command);

int * command_getCenters(command_t ** command);

int command_getStore(command_t ** command);

uint16_t command_getStoreSize(command_t ** command);

void command_print(command_t ** command);





#endif //_COMMAND_H_