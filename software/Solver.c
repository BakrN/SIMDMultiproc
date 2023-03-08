#include "Solver.h"
#include "Command.h"
#include <stdio.h>

#define MATRIXSIZE 7
#define VECTORSIZE 4

int testToeplitz[MATRIXSIZE] = {0,1,2,3,4,5,6};

int testVector[VECTORSIZE] = {2,2,2,2};

int buffer[MATRIXSIZE] = {0,0,0,0,0,0,0};

void solver_receive(command_t ** c){
    int * starts = command_getStarts(c);
    int store = command_getStore(c);
    int * storeLocation;
    if(command_getStore(c) == -1){
        storeLocation = buffer;
        store = 0; //TODO: set to correct buffer position
    } else {
        storeLocation = testToeplitz;
    }
    int size = command_getStoreSize(c);

    if(command_getOpcode(c) == 0){ //addition operation
        for (int i = 0; i < size; i++){
            storeLocation[store + i] = testToeplitz[starts[0] + i] + testToeplitz[starts[1] + i];
        }

    }
    if(command_getOpcode(c) == 1){ //subtract operation

    }
    if(command_getOpcode(c) == 2){ //multiplication operation

    }
    solver_print();
}


void solver_print(){
    printf("## Solver print ## \n");

    printf("\n Toeplitz: ");
    for(int i = 0; i < MATRIXSIZE; i++){
        printf("%d \t", testToeplitz[i]);
    }
    printf("\n Vector: ");
    for(int i = 0; i < VECTORSIZE; i++){
        printf("%d \t", testVector[i]);
    }
    printf("\n Buffer:");
    for(int i = 0; i < MATRIXSIZE; i++){
        printf("%d \t", testToeplitz[i]);
    }
    printf("#####\n");
}