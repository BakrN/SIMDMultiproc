#include "Solver.h"
#include "Command.h"
#include <stdio.h>

#define MATRIXSIZE 7
#define VECTORSIZE 4

int testToeplitz[MATRIXSIZE] = {0,1,2,3,4,5,6};

int tbuffer[MATRIXSIZE] = {0,0,0,0,0,0,0};

int testVector[VECTORSIZE] = {2,2,2,2};

int vbuffer[VECTORSIZE] = {0,0,0,0};


void solver_receive(command_t ** c){
    int * starts = command_getStarts(c);
    int store = command_getStore(c); // -2 vbuffer, -1 tbuffer, 0 ... index of overwrite in matrixdata
    int * storeLocation;
    int * dataLocation = testToeplitz;
    if(store == -1){
        storeLocation = tbuffer;
        store = 0; //TODO: set to correct buffer position
    } else if (store == -2){
        storeLocation = vbuffer;
        dataLocation = testVector;
        store = 0; //TODO: set to correct buffer position
    } else {
        storeLocation = testToeplitz;
    }
    int size = command_getStoreSize(c);

    if(command_getOpcode(c) == 0){ //addition operation
        for (int i = 0; i < size; i++){
            storeLocation[store + i] = dataLocation[starts[0] + i] + dataLocation[starts[1] + i];
        }

    }
    if(command_getOpcode(c) == 1){ //subtract operation

    }
    if(command_getOpcode(c) == 2){ //multiplication operation

    }
    solver_print();
}


void solver_print(){
    printf("## Solver print ##");

    printf("\n Toeplitz:\t ");
    for(int i = 0; i < MATRIXSIZE; i++){
        printf("%d \t", testToeplitz[i]);
    }
    printf("\n TBuffer:\t ");
    for(int i = 0; i < MATRIXSIZE; i++){
        printf("%d \t", tbuffer[i]);
    }
    printf("\n Vector:\t ");
    for(int i = 0; i < VECTORSIZE; i++){
        printf("%d \t", testVector[i]);
    }
    printf("\n VBuffer:\t ");
    for(int i = 0; i < VECTORSIZE; i++){
        printf("%d \t", vbuffer[i]);
    }
    printf("\n\n");
}