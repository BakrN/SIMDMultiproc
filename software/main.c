#define _GNU_SOURCE

#include <stdio.h>
#include "Matrix.h"
#include "Product.h"
#include "Solver.h"
#include <math.h>

int main(){
    matrix_t * m = matrix_create(8, MATRIXCENTER);
    vector_t * v = vector_create(8, 0);

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
    product_node_t * head = product_create(m, v);
    product_node_t * treeFlat[40] = {NULL};
    
    treeFlat[0] = head;

    int nextFree = 1;
    int index = 0;

    while (treeFlat[index] != NULL){
        product_decompose(&treeFlat[index]);
        treeFlat[nextFree] = treeFlat[index]->p0;
        treeFlat[nextFree +1] = treeFlat[index]->p1;
        treeFlat[nextFree +2] = treeFlat[index]->p2;

        //decompose and assign to next 3 places
        nextFree += 3;
        index++;
    }
    index--;

    printf("\n \033[0;33m ##### Recomposing  ##### \033[0m\n");


    while (index >= 0){
        product_recompose(&treeFlat[index]);
        index--;
    }

    
    solver_naive();

    printf("End of Main\n");
    return 0;
}