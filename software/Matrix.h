#ifndef _MATRIX_H_
#define _MATRIX_H_

typedef struct matrix matrix_t;

matrix_t* matrix_create(int x, int y, void ** data);

void matrix_free(matrix_t **matrix);

matrix_t* matrix_padStart(matrix_t **matrix, int amount);

matrix_t* matrix_padEnd(matrix_t **matrix, int amount);

int * matrix_getData(matrix_t **matrix);

void * matrix_2decompose(matrix_t **matrix);

void * matrix_3decompose(matrix_t **matrix);

void matrix_print(matrix_t **matrix);



#endif //_MATRIX_H_