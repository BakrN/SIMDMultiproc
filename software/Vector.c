#include <stdint.h>
#include "Vector.h"
#include <stdlib.h>
#include <stdio.h>


struct vector{
    uint16_t length;
    int index;
};


vector_t* vector_create(__uint16_t length, int index){
    vector_t * vector;
    vector = malloc(sizeof(struct vector));
    vector->length = length;
    vector->index = index;
    return vector;
}

void vector_free(vector_t **vector){
    free(*vector);
    *vector = NULL;
}

vector_t* vector_padStart(vector_t **vector, int amount){
    return *vector;
}

vector_t* vector_padEnd(vector_t **vector, int amount){
    return *vector;
}

int vector_getDataStart(vector_t **vector){
    return (*vector)->index;
}

uint16_t vector_getLength(vector_t **vector){
    return (*vector)->length;
}


vector_t ** vector_2decompose(vector_t **vector){
    vector_t ** decomposed = malloc(2*sizeof(vector_t *)); //array of ptrs to the decomposed matrices

    int new_size = (*vector)->length /2 ;
    vector_t * m0 = vector_create(new_size, (*vector)->index + new_size);
    decomposed[0] = m0;
    vector_t * m1 = vector_create(new_size, (*vector)->index + new_size*2);
    decomposed[1] = m1; 
    // vector_print(&m1);

    return decomposed;
}

vector_t ** vector_3decompose(vector_t **vector){
        vector_t ** decomposed = malloc(2*sizeof(vector_t *)); //array of ptrs to the decomposed matrices

    int new_size = (*vector)->length /3 ;
    vector_t * m0 = vector_create(new_size, (*vector)->index + new_size);
    decomposed[0] = m0;
    vector_t * m1 = vector_create(new_size, (*vector)->index + new_size*2);
    decomposed[1] = m1; 
    vector_t * m2 = vector_create(new_size, (*vector)->index + new_size*2);
    decomposed[2] = m2;

    return decomposed;
}

void vector_print(vector_t **vector, int * data){
        printf("[%d]: ", (*vector)->length);

    int data_size = (*vector)->length; //Size of the data vector
    for(int i = (*vector)->index; i <(*vector)->index + data_size; i++){
        printf("%d \t", data[i]);
    }
    printf("\n");
}