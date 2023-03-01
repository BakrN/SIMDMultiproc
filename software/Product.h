#include "Matrix.h"
#include "Vector.h"

typedef struct product_node product_node_t;

typedef struct product product_t;

product_t* product_create(matrix_t *m, vector_t *v);

product_node_t* product_node_create(product_node_t **parent, matrix_t *m, vector_t *v);

product_t* product_set_head(product_t **product, product_node_t **pn);

void product_decompose(product_node_t **pn);

void product_node_print(product_node_t **pn);