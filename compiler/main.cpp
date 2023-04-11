#include "Graph.h" 
#include "Algo.h"
#include "Solver.h"
#include <iostream>

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
    graph->PrintGraph() ;
    


    
    return 0 ;
} 

