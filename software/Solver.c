#include "Solver.h"
#include "Command.h"
#include <stdio.h>

int testToeplitz[MATRIXSIZE] = {0,1,2,3,4,5,6};

int tbuffer[] = {0,0,1,2,3,4,5,6,0};

int testVector[VECTORSIZE] = {2,2,2,2};

int vbuffer[VECTORSIZE] = {};


void solver_receive(command_t ** c){
    int * starts = command_getCenters(c);
    int store = command_getStore(c); //center of toeplitz data or start of vector data
    // if(opco == -1){
    //     storeLocation = tbuffer;
    //     store = 0; //TODO: set to correct buffer position
    // } else if (store == -2){
    //     storeLocation = vbuffer;
    //     dataLocation = testVector;
    //     store = 0; //TODO: set to correct buffer position
    // }
    int storeSize = command_getStoreSize(c);

    if(command_getOpcode(c) == 0){ //T addition

        for (int i = -storeSize-1; i < storeSize; i++){
            tbuffer[store + i] = tbuffer[starts[0] + i] + tbuffer[starts[1] + i];
        }

    }
    if(command_getOpcode(c) == 1){ //V addition

    }
    if(command_getOpcode(c) == 2){ //TV multiplication

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
    for(int i = 0; i < TBUFFERSIZE; i++){
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