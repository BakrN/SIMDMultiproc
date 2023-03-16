#ifndef _MATRIX_H_
#define _MATRIX_H_

typedef struct matrix matrix_t;

matrix_t* matrix_create(int size, int index);

void matrix_free(matrix_t **matrix);

matrix_t* matrix_padStart(matrix_t **matrix, int amount);

matrix_t* matrix_padEnd(matrix_t **matrix, int amount);

int matrix_getDataCenter(matrix_t **matrix);

matrix_t ** matrix_2decompose(matrix_t **matrix);

matrix_t ** matrix_3decompose(matrix_t **matrix);

void matrix_print(matrix_t **matrix, int * data);



#endif //_MATRIX_H_