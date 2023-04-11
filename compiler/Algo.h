#ifndef ALGO_H
#define ALGO_H

#include "Graph.h"
#include "Buffer.h"
#include "Operator.h"
#include <memory>
// Matrix mulitplier graph builder

class DecompositionGraphBuilder { 
    public: 
        DecompositionGraphBuilder(Buffer& buffer, Node* root ) ;   
        ~DecompositionGraphBuilder() ;  
        Graph* BuildGraph() ; 

    private: 
        void SplitTwoWay(ProductNode* node) ;
        void SplitThreeWay(Node* node) ;
        Node* m_root; 
        Buffer&  m_buffer;  
        Graph* m_graph;
        Graph* m_recomp_graph;
} ;


#endif // !ALGO_H
