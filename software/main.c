#define _GNU_SOURCE

#include <stdio.h>
#include "Matrix.h"
#include "Product.h"
#include "Solver.h"

int main(){
    matrix_t * m = matrix_create(4, MATRIXCENTER);
    vector_t * v = vector_create(4, 0);

    // matrix_t ** m_decomp = (matrix_t **) matrix_2decompose(&m);
    // matrix_print(&m_decomp[0],testData); 
    // matrix_print(&m_decomp[1],testData); 
    // matrix_print(&m_decomp[2],testData); 

    // int testData2[17] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
    // matrix_t * m2 = matrix_create(9, 0);
    // matrix_print(&m2,testData2);

    // matrix_t ** m_decomp2 = (matrix_t **) matrix_3decompose(&m2);
    // matrix_print(&m_decomp2[0],testData2); 
    // matrix_print(&m_decomp2[1],testData2); 
    // matrix_print(&m_decomp2[2],testData2);
    // matrix_print(&m_decomp2[3],testData2); 
    // matrix_print(&m_decomp2[4],testData2);


    printf("%s", "## Product test ##\n");
    product_create(m, v);

    printf("End of Main\n");
    return 0;
}