#include "Solver.h"
#include "Command.h"
#include <stdio.h>

int testToeplitz[MATRIXSIZE] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14};

int tbuffer[] = {0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,0,0,0,0,0,0};

int testVector[VECTORSIZE] = {1,2,3,4,5,6,7,8};

int vbuffer[VBUFFERSIZE] = {1,2,3,4,5,6,7,8};

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

        if(starts[0]<starts[1]){
            for (int i = -storeSize+1; i < storeSize; i++){
                printf("[%d]: ", store + i);
                printf("%d +\t %d\n", tbuffer[starts[0] + i],tbuffer[starts[1] + i]);
                tbuffer[store + i] = tbuffer[starts[0] + i] + tbuffer[starts[1] + i];
            }
        } else {
            for (int i = storeSize -1; i > -storeSize; i--){
                printf("[%d]: ", store + i);
                printf("%d +\t %d\n", tbuffer[starts[0] + i],tbuffer[starts[1] + i]);
                tbuffer[store + i] = tbuffer[starts[0] + i] + tbuffer[starts[1] + i];
            }
        }
    }
    if(command_getOpcode(c) == 1){ //V addition
        for (int i = 0; i < storeSize; i++)
        {
            printf("[%d]: ",store + i);
            printf("%d +\t %d\n", vbuffer[starts[0] + i],vbuffer[starts[1] + i]);
            vbuffer[store + i] = vbuffer[starts[0] + i] + vbuffer[starts[1] +i]; 

        }
        
    }
    if(command_getOpcode(c) == 2){ //TV multiplication
        int total[2] = {0};
        for (int i = -storeSize +1; i <= 0; i++){
            printf("[%d]: ", store + i + storeSize -1);
            for (int index = 0; index < storeSize; index++){
                printf("%d * %d \t", tbuffer[starts[0] + i + index],vbuffer[starts[1] + index]);
                total[i+storeSize -1] += tbuffer[starts[0] + i + index] * vbuffer[starts[1] + index];

            }
            printf("\n");    
        }
        for (int i = 0; i < storeSize; i++)
        {
            vbuffer[starts[1] + i] = total[i];
        }
        
    }
    if(command_getOpcode(c) == 3){ //V subtraction
        for (int i = 0; i < storeSize; i++)
        {
            printf("[%d]: ",store + i);
            printf("%d -\t %d\n", vbuffer[starts[0] + i],vbuffer[starts[1] + i]);
            vbuffer[store + i] = vbuffer[starts[0] + i] - vbuffer[starts[1] +i]; 

        }
        
    }

    printf("\n");

    solver_print();
}

void solver_naive(){
    printf("\033[32m NAIVE test: [ \t");
    for (int i = 1; i < VECTORSIZE +1; i++)
    {
        int result = 0;
        for (int j = 0; j < VECTORSIZE; j++)
        {
            result += testToeplitz[VECTORSIZE - i + j]*testVector[j];
        }
        printf("%d \t", result);
        
    }
    printf("] \033[0m \n");
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
    for(int i = 0; i < VBUFFERSIZE; i++){
        printf("%d \t", vbuffer[i]);
    }
    printf("\n\n");
}