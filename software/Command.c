#include "Command.h"
#include "Solver.h"
#include <stdlib.h>

int id_count;

struct command{
    uint8_t opcode; //0 addition, 1 subract, 2 multiply
    int id;
    int parent_id;
    int * elements;
    int store; // -2 vbuffer, -1 tbuffer, 0 ... index of overwrite in matrixdata
    uint16_t storeSize;
};

void command_create(command_t ** c, uint8_t opcode, int parent_id, int e0, int e1, int e2, int store, uint16_t storeSize){
    *c = malloc(sizeof(struct command));
    (*c)->store = store;
    (*c)->opcode = opcode;
    (*c)->storeSize = storeSize;
    id_count ++;
    (*c)->id = id_count;
    (*c)->parent_id = parent_id;
    if(e2 != -1){ 
        (*c)->elements = malloc(sizeof(int)*3);
        (*c)->elements[0] = e0;
        (*c)->elements[1] = e1;
        (*c)->elements[2] = e2;
    }else {
        (*c)->elements = malloc(sizeof(int)*2);
        (*c)->elements[0] = e0;
        (*c)->elements[1] = e1;
    }
    command_send(c);
}

void command_send(command_t ** command){
    solver_receive(command);
}

int command_getId(command_t ** command){
    return (*command)->id;
}

uint8_t command_getOpcode(command_t ** command){
    return (*command)->opcode;
}

int command_getParentId(command_t ** command){
    return (*command)->parent_id;
}

int * command_getStarts(command_t ** command){
    return (*command)->elements;
}

int command_getStore(command_t ** command){
    return (*command)->store;
}

uint16_t command_getStoreSize(command_t ** command){
    return (*command)->storeSize;
}
