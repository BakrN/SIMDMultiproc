#include <stdint.h>
#include "Vector.h"
#include <stdlib.h>
#include <stdio.h>


struct vector{
    uint16_t length;
    int *data;
};


vector_t* vector_create(__uint16_t length, int ** data){
    vector_t * vector;
    vector = malloc(sizeof(struct vector));
    vector->length = length;
    vector->data = *data;
    return vector;
}

void vector_free(vector_t **vector){
    free((*vector)->data);
    free(*vector);
    *vector = NULL;
}

vector_t* vector_padStart(vector_t **vector, int amount){
    return *vector;
}

vector_t* vector_padEnd(vector_t **vector, int amount){
    return *vector;
}

int * vector_getData(vector_t **vector){
    return (*vector)->data;
}

uint16_t * vector_getLength(vector_t **vector){
    return (*vector)->length;
}


vector_t ** vector_2decompose(vector_t **vector){
    vector_t ** decomposed = malloc(2*sizeof(vector_t *)); //array of ptrs to the decomposed matrices

    int new_size = (*vector)->length /2 ;
    vector_t * m0 = vector_create(new_size, &(*vector)->data);
    decomposed[0] = m0;
    int * jump = &(*vector)->data[new_size];
    vector_t * m1 = vector_create(new_size, &jump);
    decomposed[1] = m1; 
    // vector_print(&m1);

    return decomposed;
}

vector_t ** vector_3decompose(vector_t **vector){
        vector_t ** decomposed = malloc(2*sizeof(vector_t *)); //array of ptrs to the decomposed matrices

    int new_size = (*vector)->length /3 ;
    vector_t * m0 = vector_create(new_size, &(*vector)->data);
    decomposed[0] = m0;
    int * jump = &(*vector)->data[new_size];
    vector_t * m1 = vector_create(new_size, &jump);
    decomposed[1] = m1; 
    int * jump2 = &(*vector)->data[2*new_size];
    vector_t * m2 = vector_create(new_size, &jump2);
    decomposed[2] = m2;

    return decomposed;
}

void vector_print(vector_t **vector){
        printf("[%d]: ", (*vector)->length);

    int data_size = (*vector)->length; //Size of the data vector
    for(int i = 0; i < data_size; i++){
        printf("%d \t", (*vector)->data[i]);
    }
    printf("\n");
}