#ifndef ALGO_H
#define ALGO_H

#include "Graph.h"
#include "Buffer.h"
#include "Operator.h"
#include "config.h"
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
