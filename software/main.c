#define _GNU_SOURCE

#include <stdio.h>
#include "Matrix.h"
#include "Product.h"

int main(){
    printf("%s", "## Matrix test ##\n");
    int testData[7] = {0,1,2,3,4,5,6};
    int * startPtr = &testData[0];
    matrix_t * m = matrix_create(4,4,&startPtr);
    matrix_print(&m);

    matrix_t ** m_decomp = (matrix_t **) matrix_2decompose(&m);
    matrix_print(&m_decomp[0]); 
    matrix_print(&m_decomp[1]); 
    matrix_print(&m_decomp[2]); 

    int testData2[17] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
    int * startPtr2 = &testData2[0];
    matrix_t * m2 = matrix_create(9,9,&startPtr2);
    matrix_print(&m2);

    matrix_t ** m_decomp2 = (matrix_t **) matrix_3decompose(&m2);
    matrix_print(&m_decomp2[0]); 
    matrix_print(&m_decomp2[1]); 
    matrix_print(&m_decomp2[2]);
    matrix_print(&m_decomp2[3]); 
    matrix_print(&m_decomp2[4]);


    // printf("%s", "## Product test ##\n");
    // product_t * product = product_create(m,NULL);
    // product_node_t * pn = product_node_create(NULL, m, NULL);
    // product_set_head(&product, &pn);
    // product_node_print(&pn);

    printf("End of Main\n");
    return 0;
}