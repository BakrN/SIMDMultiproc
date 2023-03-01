#include "Product.h"
#include "Matrix.h"
#include "Vector.h"
#include <stdlib.h>
#include <stdio.h>


struct product_node {
    product_node_t *parent, *p0, *p1, *p2;
    matrix_t *m;
    vector_t *v;
};

struct product{
    product_node_t *head;
};

product_t* product_create(matrix_t *m, vector_t *v){
    product_t * product = malloc(sizeof(struct product));
    product->head = product_node_create(NULL, m, v);
    return product;
}

product_node_t* product_node_create(product_node_t **parent, matrix_t *m, vector_t *v){
    product_node_t * node = malloc(sizeof(struct product_node));
    if(parent != NULL) node->parent = *parent;
    node->m = m;
    node->v = v;
    return node;
}

product_t* product_set_head(product_t **product, product_node_t **pn){
    (*product)->head = *pn;
    return *product;
}

void product_decompose(product_node_t **pn){
    
}


void product_node_print(product_node_t **pn){
    printf("parent_addr: %p\n", &pn);
    matrix_print(&(*pn)->m);
    //TODO: vector print

}