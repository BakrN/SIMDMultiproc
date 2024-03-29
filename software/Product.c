#include "Product.h"
#include "Matrix.h"
#include "Vector.h"
#include "Command.h"
#include "Solver.h"
#include <stdlib.h>
#include <stdio.h>

int id_count;


product_node_t* product_create(matrix_t *m, vector_t *v){
    product_t * product = malloc(sizeof(struct product));
    product->head = product_node_create(0, m, v);
    id_count = 0;
    return product->head;
}

product_node_t* product_node_create(int parent_id, matrix_t *m, vector_t *v){
    product_node_t * node = malloc(sizeof(struct product_node));
    node->parent_id = parent_id;
    node->m = m;
    node->v = v;
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

        int vindex = VECTORSIZE + 2*VECTORSIZE/(length) + vector_getDataStart(&v_decomp[0])/2;
        int tindex = VECTORSIZE/length;

        if(VECTORSIZE == length){
            vindex = VECTORSIZE + vector_getDataStart(&v_decomp[0]);
            tindex = 0;
        }
        printf("\n \033[0;33m ##### vindex [%d] = %d + %d + %d  ##### \033[0m\n,", vindex, VECTORSIZE, 2*VECTORSIZE/length,vector_getDataStart(&v_decomp[0])/2);

        command_create(0,id_count +1, (*pn)->parent_id, matrix_getDataCenter(&m_decomp[0]) - tindex + length/2 +1, matrix_getDataCenter(&m_decomp[1]),-1, matrix_getDataCenter(&m_decomp[0]), length/2);
        command_create(0,id_count +2, (*pn)->parent_id, matrix_getDataCenter(&m_decomp[2]) + tindex - length/2 -1, matrix_getDataCenter(&m_decomp[1]),-1, matrix_getDataCenter(&m_decomp[2]), length/2);
        command_create(3,id_count +3, (*pn)->parent_id, vector_getDataStart(&v_decomp[0]),vector_getDataStart(&v_decomp[1]),-1,vindex,length/2);
        //Command 1 = m_decomp[0] + m_decomp[1] -> T2 + T1
        //Command 2 = m_decomp[2] + m_decomp[1] -> T1 + T0
        //Command 3 = v_decomp[0] - v_decomp[1] -> V0 - V1


        matrix_t * m0 = matrix_create(length/2,matrix_getDataCenter(&m_decomp[2]));
        (*pn)->p0 = product_node_create(id_count +2,m0, v_decomp[1]);
        //Command 4 = C2 . v_decomp[1] -> P0

        matrix_t * m1 = matrix_create(length/2,matrix_getDataCenter(&m_decomp[0]));
        (*pn)->p1 = product_node_create(id_count +1,m1, v_decomp[0]);
        //Command 6 = C1 . v_decomp[0] -> P1

        vector_t * v0 = vector_create(length/2,vindex);
        (*pn)->p2 = product_node_create(id_count +3, m_decomp[1],v0);
        //Command 5 = m_decomp[1] . C3 -> P2

        id_count += 3;

        return;
    }
    if(length % 3 == 0){
        // matrix_t ** m_decomp = matrix_3decompose(&(*pn)->m);
        // vector_t ** v_decomp = vector_3decompose(&(*pn)->v);
        return;
    }
}

void product_recompose(product_node_t **pn){
    if ((*pn)->p0 != NULL && (*pn)->p1 != NULL && (*pn)->p2 != NULL){
        command_create(1,id_count +1,(*pn)->parent_id,vector_getDataStart(&(*pn)->p0->v),vector_getDataStart(&(*pn)->p2->v),-1,vector_getDataStart(&(*pn)->p0->v),vector_getLength(&(*pn)->p0->v));
        //Command 2 = P0 + P2
        command_create(3,id_count +2,(*pn)->parent_id,vector_getDataStart(&(*pn)->p1->v),vector_getDataStart(&(*pn)->p2->v),-1,vector_getDataStart(&(*pn)->p1->v),vector_getLength(&(*pn)->p1->v));
        //Command 3 = P1 - P2
        id_count += 2;

    } else {
        //Command 1 = m.v (store in vector location)
        command_create(2,id_count + 1,(*pn)->parent_id,matrix_getDataCenter(&(*pn)->m),vector_getDataStart(&(*pn)->v),-1,vector_getDataStart(&(*pn)->v),vector_getLength(&(*pn)->v));
        id_count += 1;

    }
    
}



void product_node_print(product_node_t **pn, int * m_data, int * v_data){
    printf("parent_addr: %p\n", &pn);
    matrix_print(&(*pn)->m, m_data);
    //TODO: vector print

}