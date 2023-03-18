#include "Product.h"
#include "Matrix.h"
#include "Vector.h"
#include "Command.h"
#include "Solver.h"
#include <stdlib.h>
#include <stdio.h>

int id_count;
int curr_size = VECTORSIZE;

struct product_node {
    product_node_t *p0, *p1, *p2, *p3, *p4, *p5;
    int parent_id;
    matrix_t *m;
    vector_t *v;
};

struct product{
    product_node_t *head;
};

product_t* product_create(matrix_t *m, vector_t *v){
    product_t * product = malloc(sizeof(struct product));
    product->head = product_node_create(0, m, v);
    id_count = 0;
    return product;
}

product_node_t* product_node_create(int parent_id, matrix_t *m, vector_t *v){
    product_node_t * node = malloc(sizeof(struct product_node));
    node->parent_id = parent_id;
    node->m = m;
    node->v = v;
    curr_size = vector_getLength(&v);

    product_decompose(&node);
    return node;
}

product_t* product_set_head(product_t **product, product_node_t **pn){
    (*product)->head = *pn;
    return *product;
}

void product_decompose(product_node_t **pn){
    uint16_t length = vector_getLength(&(*pn)->v);
    if(length % 2 == 0 && length >2){
        printf("\n \033[0;31m ##### Decomposition [%d] ##### \033[0m\n,", length);
        matrix_t ** m_decomp = matrix_2decompose(&(*pn)->m);
        vector_t ** v_decomp = vector_2decompose(&(*pn)->v);

        int vindex = VECTORSIZE + 2*VECTORSIZE/(curr_size) + vector_getDataStart(&v_decomp[0])/2;

        if(VECTORSIZE == curr_size) vindex = VECTORSIZE + vector_getDataStart(&v_decomp[0]);
        printf("\n \033[0;33m ##### vindex [%d] = %d + %d + %d  ##### \033[0m\n,", vindex, VECTORSIZE, 2*VECTORSIZE/curr_size,vector_getDataStart(&v_decomp[0])/2);

        command_create(0,id_count, (*pn)->parent_id, matrix_getDataCenter(&m_decomp[0]) + length/2 +1, matrix_getDataCenter(&m_decomp[1]),-1, matrix_getDataCenter(&m_decomp[0]), length/2);
        command_create(0,id_count +1, (*pn)->parent_id, matrix_getDataCenter(&m_decomp[2])  - length/2 -1, matrix_getDataCenter(&m_decomp[1]),-1, matrix_getDataCenter(&m_decomp[2]), length/2);
        command_create(1,id_count +2, (*pn)->parent_id, vector_getDataStart(&v_decomp[0]),vector_getDataStart(&v_decomp[1]),-1,vindex,length/2);
        id_count += 3;
        //Command 1 = m_decomp[0] + m_decomp[1]
        //Command 2 = m_decomp[1] + m_decomp[2]
        //Command 3 = v_decomp[0] + v_decomp[1]


        matrix_t * m0 = matrix_create(length/2,matrix_getDataCenter(&m_decomp[0]));
        (*pn)->p0 = product_node_create(id_count,m0, v_decomp[1]);
        //Command 4 = C1 . v_decomp[1] -> create new products

        vector_t * v0 = vector_create(length/2,vindex);
        (*pn)->p1 = product_node_create(id_count +1, m_decomp[1],v0);
        //Command 5 = m_decomp[1] . C3

        matrix_t * m1 = matrix_create(length/2,matrix_getDataCenter(&m_decomp[2]));
        (*pn)->p2 = product_node_create(id_count,m1, v_decomp[0]);
        //Command 6 = C2 . v_decomp[0]


        return;
    }
    if(length % 3 == 0){
        // matrix_t ** m_decomp = matrix_3decompose(&(*pn)->m);
        // vector_t ** v_decomp = vector_3decompose(&(*pn)->v);
        return;
    }
}


void product_node_print(product_node_t **pn, int * m_data, int * v_data){
    printf("parent_addr: %p\n", &pn);
    matrix_print(&(*pn)->m, m_data);
    //TODO: vector print

}