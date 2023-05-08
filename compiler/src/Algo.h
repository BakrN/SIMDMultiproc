#ifndef ALGO_H
#define ALGO_H
#define BASE_MMUL_2x_SIZE 2 // lowest point where we actuall do the multiplication (could try out with different values  later)  
#define BASE_MMUL_3x_SIZE 3
#include "Graph.h"
#include "Buffer.h"
#include "Operator.h"
#include <memory>
// Matrix mulitplier graph builder

class DecompositionGraphBuilder { 
    public: 
        DecompositionGraphBuilder( ProductNode* node) ;   
        ~DecompositionGraphBuilder() ;  
        Graph* BuildGraph() ; 

    private: 
        void SplitTwoWay(ProductNode* node) ;
        void SplitThreeWay(ProductNode* node) ;
        ProductNode* m_root; 
        Graph* m_graph;
        Graph* m_recomp_graph;
} ;


#endif // !ALGO_H
