#include "Graph.h" 
#include "Algo.h"
#include "Solver.h"
#include <iostream>

void naive_matmul(unit_t* matrix, unit_t* vec, unit_t* result, int size) {  // row major order
    for (int i = 0 ; i < size; i++) { 
        for (int j = 0 ; j < size ; j++) { 
            for (int k = 0 ; k < size ; k++) { 
                result[i*size + j] += matrix[i*size + k] * vec[k*size + j] ;
            }
        } 
    }  
}  
// create

int main() { 
    Buffer buf(100);  
    Toep2d* toep = new Toep2d(&buf, 8 );// 4x4
    Vec1d* vec   = new Vec1d(&buf, 8) ; // 4x1
    DataNode* toep_node = new DataNode(toep);
    DataNode* vec_node = new DataNode(vec);
    ProductNode* node = new ProductNode(toep_node , vec_node ,  true);  
    std::cout << "Starting decomposition graph builder" << std::endl;
    DecompositionGraphBuilder builder(buf, node);  
    Graph* graph = builder.BuildGraph() ;  
    std::cout << "Finished decomposition graph builder" << std::endl;
    Graph* toep_graph = new Graph(static_cast<ProductNode*>(graph->GetRoot())->GetToepNode());
    Graph* vec_graph  = new Graph(static_cast<ProductNode*>(graph->GetRoot())->GetVecNode());
    //std::cout << "Printing toeplitz graph " << std::endl;
    //toep_graph->PrintGraph() ;
    //std::cout << "Printing vec graph " << std::endl;
    //vec_graph->PrintGraph() ; 
    // std::cout << "Printing recompostition graph " << std::endl;
    // graph->PrintGraphReverse() ;  
    
    return 0 ;
} 

