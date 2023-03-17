#include "Command.h"
#include "Solver.h"
#include <stdlib.h>
#include <stdio.h>

struct command{
    uint8_t opcode; //T 0 addition, 1 V addition, 2 multiply
    int id;
    int parent_id;
    int * elements;
    int store; //0 ... index of overwrite in buffer
    uint16_t storeSize;
};

void command_create(uint8_t opcode,int id, int parent_id, int e0, int e1, int e2, int store, uint16_t storeSize){
    command_t * c = malloc(sizeof(struct command));
    c->store = store;
    c->opcode = opcode;
    c->storeSize = storeSize;
    c->id = id;
    c->parent_id = parent_id;
    if(e2 != -1){ 
        c->elements = malloc(sizeof(int)*3);
        c->elements[0] = e0;
        c->elements[1] = e1;
        c->elements[2] = e2;
    }else {
        c->elements = malloc(sizeof(int)*2);
        c->elements[0] = e0;
        c->elements[1] = e1;
    }
    command_print(&c);
    command_send(&c);
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

int * command_getCenters(command_t ** command){
    return (*command)->elements;
}

int command_getStore(command_t ** command){
    return (*command)->store;
}

uint16_t command_getStoreSize(command_t ** command){
    return (*command)->storeSize;
}

void command_print(command_t ** command){
    printf("\n Command:\t ");
    printf("opcode{%d} id{%d} pid{%d} centers{%d, %d} store{%d} size{%d} \n\n", command_getOpcode(command),command_getId(command), command_getParentId(command),command_getCenters(command)[0],command_getCenters(command)[1], command_getStore(command),command_getStoreSize(command));
}

