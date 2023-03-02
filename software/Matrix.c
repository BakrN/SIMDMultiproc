#define _GNU_SOURCE
#include "Matrix.h"
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>


struct matrix{
    uint16_t x; //Amount of Columns (2 bytes)
    uint16_t y; //Amount of Rows (2 bytes)
    int *data; //TODO: define exact data type for efficiency //first column bottom up - first row left to right (0 e d a b c 0)
};

matrix_t* matrix_create(int x, int y, int ** data){
    matrix_t * matrix;
    matrix = malloc(sizeof(struct matrix));
    matrix->x = x;
    matrix->y = y;
    matrix->data = *data;
    return matrix;
}

void matrix_free(matrix_t **matrix){
    free((*matrix)->data);
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

int * matrix_getData(matrix_t **matrix){
    return (*matrix)->data;
}

matrix_t ** matrix_2decompose(matrix_t **matrix){
    if((*matrix)->x != (*matrix)->y){
        return NULL;
    }
    matrix_t ** decomposed = malloc(3*sizeof(matrix_t *)); //array of ptrs to the decomposed matrices

    int new_size = (*matrix)->x /2 ;
    matrix_t * m0 = matrix_create(new_size, new_size,&(*matrix)->data);
    decomposed[0] = m0;
    int * jump = &(*matrix)->data[new_size];
    matrix_t * m1 = matrix_create(new_size, new_size,&jump);
    decomposed[1] = m1; 
    // matrix_print(&m1);
    int * jump2 = &(*matrix)->data[2*new_size];
    matrix_t * m2 = matrix_create(new_size, new_size,&jump2);
    decomposed[2] = m2; 
    // matrix_print(&m2);

    return decomposed;
}

matrix_t ** matrix_3decompose(matrix_t **matrix){
    if((*matrix)->x != (*matrix)->y){
        return NULL;
    }
    matrix_t ** decomposed = malloc(5*sizeof(matrix_t *)); //array of ptrs to the decomposed matrices

    int new_size = (*matrix)->x /3 ;
    matrix_t * m0 = matrix_create(new_size, new_size,&(*matrix)->data);
    decomposed[0] = m0; 
    int * jump = &(*matrix)->data[new_size];
    matrix_t * m1 = matrix_create(new_size, new_size,&jump);
    decomposed[1] = m1; 
    // matrix_print(&m1);
    int * jump2 = &(*matrix)->data[2*new_size];
    matrix_t * m2 = matrix_create(new_size, new_size,&jump2);
    decomposed[2] = m2;
    int * jump3 = &(*matrix)->data[3*new_size];
    matrix_t * m3 = matrix_create(new_size, new_size,&jump3);
    decomposed[3] = m3; 
    int * jump4 = &(*matrix)->data[4*new_size];
    matrix_t * m4 = matrix_create(new_size, new_size,&jump4);
    decomposed[4] = m4; 
    // matrix_print(&m2);

    return decomposed;
}

void matrix_print(matrix_t **matrix){
    printf("[%d, %d]: ", (*matrix)->x, (*matrix)->y);

    int data_size = (*matrix)->x + (*matrix)->y -1; //Size of the data vector
    for(int i = 0; i < data_size; i++){
        printf("%d \t", (*matrix)->data[i]);
    }
    printf("\n");

}