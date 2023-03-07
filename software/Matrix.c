#define _GNU_SOURCE
#include "Matrix.h"
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>


struct matrix{
    uint16_t size; //Amount of Columns (2 bytes)
    int index; //TODO: define exact data type for efficiency //first column bottom up - first row left to right (0 e d a b c 0)
};

matrix_t* matrix_create(int size, int index){
    matrix_t * matrix;
    matrix = malloc(sizeof(struct matrix));
    matrix->size = size;
    matrix->index = index;
    return matrix;
}

void matrix_free(matrix_t **matrix){
    free(*matrix);
    *matrix = NULL;
}

matrix_t* matrix_padStart(matrix_t **matrix, int amount){
    return *matrix;
}

matrix_t* matrix_padEnd(matrix_t **matrix, int amount){
    //(*matrix)->data = realloc(matrix,sizeof((*matrix)->data)+amount*sizeof(int));
    return *matrix;
}

int matrix_getDataStart(matrix_t **matrix){
    return (*matrix)->index;
}

matrix_t ** matrix_2decompose(matrix_t **matrix){
    matrix_t ** decomposed = malloc(3*sizeof(matrix_t *)); //array of ptrs to the decomposed matrices

    int new_size = (*matrix)->size /2 ;
    matrix_t * m0 = matrix_create(new_size, (*matrix)->index);
    decomposed[0] = m0;
    matrix_t * m1 = matrix_create(new_size, (*matrix)->index + new_size);
    decomposed[1] = m1; 
    matrix_t * m2 = matrix_create(new_size, (*matrix)->index + new_size*2);
    decomposed[2] = m2; 

    return decomposed;
}

matrix_t ** matrix_3decompose(matrix_t **matrix){
    matrix_t ** decomposed = malloc(5*sizeof(matrix_t *)); //array of ptrs to the decomposed matrices

    int new_size = (*matrix)->size /3 ;
    matrix_t * m0 = matrix_create(new_size, (*matrix)->index);
    decomposed[0] = m0; 

    matrix_t * m1 = matrix_create(new_size, (*matrix)->index + new_size);
    decomposed[1] = m1; 

    matrix_t * m2 = matrix_create(new_size, (*matrix)->index + new_size*2);
    decomposed[2] = m2;

    matrix_t * m3 = matrix_create(new_size, (*matrix)->index + new_size*3);
    decomposed[3] = m3; 

    matrix_t * m4 = matrix_create(new_size, (*matrix)->index + new_size*4);
    decomposed[4] = m4; 

    return decomposed;
}

void matrix_print(matrix_t **matrix, int * data){
    printf("[%d, %d]: ", (*matrix)->size, (*matrix)->size);

    int data_size = 2*((*matrix)->size) -1; //Size of the data vector
    for(int i = (*matrix)->index; i < (*matrix)->index + data_size; i++){
        printf("%d \t", data[i]);
    }
    printf("\n");

}