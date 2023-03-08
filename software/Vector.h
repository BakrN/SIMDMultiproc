#ifndef _VECTOR_H_
#define _VECTOR_H_

#include <stdint.h>

typedef struct vector vector_t;

vector_t* vector_create(__uint16_t length, int index);

void vector_free(vector_t **vector);

vector_t* vector_padStart(vector_t **vector, int amount);

vector_t* vector_padEnd(vector_t **vector, int amount);

int vector_getDataStart(vector_t **vector);

uint16_t vector_getLength(vector_t **vector);

vector_t ** vector_2decompose(vector_t **vector);

vector_t ** vector_3decompose(vector_t **vector);

void vector_print(vector_t **vector, int * data);

#endif //_VECTOR_H_