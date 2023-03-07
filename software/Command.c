#include "Command.h"
#include <stdlib.h>

int id_count;

struct command{
    uint8_t opcode; //0 addition, 1 subract, 2 multiply
    int id;
    command_t ** parent;
    int * elements;
};

void command_create(command_t ** c, uint8_t opcode, command_t ** parent, int e0, int e1, int e2){
    (*c)->opcode = opcode;
    id_count ++;
    (*c)->id = id_count;
    (*c)->parent = parent;
    if(e2 != -1){ 
        (*c)->elements = malloc(sizeof(void *)*3);
        (*c)->elements[0] = e0;
        (*c)->elements[1] = e1;
        (*c)->elements[2] = e2;
    }else {
        (*c)->elements = malloc(sizeof(void *)*2);
        (*c)->elements[0] = e0;
        (*c)->elements[1] = e1;
    }
}

int command_getId(command_t ** command){
    return (*command)->id;
}

