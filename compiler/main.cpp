#include "Graph.h" 
#include "Algo.h"

int main() { 
    Buffer buf(100);
    Toep2d* toep = new Toep2d(buf, 4 );//4x4
    Vec1d* vec = new Vec1d(buf, 4);
    DataNode* toep_node = new DataNode(toep);
    DataNode* vec_node = new DataNode(vec_node);
 
    ProductNode* node = new ProductNode(toep_node , vec_node ); 
    //DecompositionGraphBuilder builder(buf, node);  
    //builder.BuildGraph() ;
    return 0 ;
} 

