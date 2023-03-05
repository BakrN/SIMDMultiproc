#include "Command.h"
#include <stdbool.h>
#include <stdlib.h>


struct command{
    bool flag; //0 is addition, 1 is Multiply
    void ** elements;
};

void command_create(command_t ** c,bool flag, void ** e0, void ** e1, void ** e2){
    (*c)->flag = flag;
    if(e2 != NULL){ 
        (*c)->elements = malloc(sizeof(void *)*3);
        (*c)->elements[0] = e0;
        (*c)->elements[1] = e1;
        (*c)->elements[2] = e2;
    }
}
