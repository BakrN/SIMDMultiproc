#define _GNU_SOURCE

#include <stdio.h>
#include "Matrix.h"
#include "Product.h"

int main(){
    printf("%s", "## Matrix test ##\n");
    int testData[7] = {0,1,2,3,4,5,6};
    void * dataptr = &testData;
    matrix_t * m = matrix_create(4,4,dataptr);
    matrix_print(&m);
    matrix_t ** m_decomp = (matrix_t**) matrix_2decompose(&m);
    matrix_print(&*m_decomp); 


    // printf("%s", "## Product test ##\n");
    // product_t * product = product_create(m,NULL);
    // product_node_t * pn = product_node_create(NULL, m, NULL);
    // product_set_head(&product, &pn);
    // product_node_print(&pn);

    printf("End of Main\n");
    return 0;
}