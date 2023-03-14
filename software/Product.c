#include "Product.h"
#include "Matrix.h"
#include "Vector.h"
#include "Command.h"
#include <stdlib.h>
#include <stdio.h>


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
    return product;
}

product_node_t* product_node_create(int parent_id, matrix_t *m, vector_t *v){
    product_node_t * node = malloc(sizeof(struct product_node));
    node->parent_id = parent_id;
    node->m = m;
    node->v = v;
    product_decompose(&node);
    return node;
}

product_t* product_set_head(product_t **product, product_node_t **pn){
    (*product)->head = *pn;
    return *product;
}

void product_decompose(product_node_t **pn){
    uint16_t length = vector_getLength(&(*pn)->v);
    if(length % 2 == 0){
        matrix_t ** m_decomp = matrix_2decompose(&(*pn)->m);
        // vector_t ** v_decomp = vector_2decompose(&(*pn)->v);
        command_create(0, (*pn)->parent_id, matrix_getDataCenter(&m_decomp[0])  + length +1, matrix_getDataCenter(&m_decomp[1]),-1, matrix_getDataCenter(&m_decomp[0]), length/2);
        command_create(0, (*pn)->parent_id, matrix_getDataCenter(&m_decomp[2])  - length -1, matrix_getDataCenter(&m_decomp[1]),-1, matrix_getDataCenter(&m_decomp[2]), length/2);
        // command_create(1, (*pn)->parent_id, vector_getDataStart(&v_decomp[0]), vector_getDataStart(&v_decomp[1]),-1,0,length/2);
        //Command 1 = m_decomp[0] + m_decomp[1]
        //Command 2 = m_decomp[1] + m_decomp[2]
        //Command 3 = v_decomp[0] + v_decomp[1]


        //Command 4 = C1 . v_decomp[1] -> create new products
        //Command 5 = m_decomp[1] . C3
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