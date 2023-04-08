#include "Algo.h"
#include "Toeplitz.h"
#include "Operator.h"
#include <stdexcept>
DecompositionGraphBuilder::DecompositionGraphBuilder(Buffer& buffer, Node* root) :m_buffer(buffer){ 
    m_root = root ; 
    m_graph = new Graph() ;  
}
DecompositionGraphBuilder::~DecompositionGraphBuilder() { 
    delete m_graph ;  
    delete m_recomp_graph ;
}
void DecompositionGraphBuilder::BuildGraph() { 
    // Generate Decomposition graph for toeplitz and vec 
    // While generating decomp , build parallel Recomp graph and attach it to the decomp graph

    // std::stack
    // identify 
    
} 


void DecompositionGraphBuilder::SplitTwoWay(Node* node) { 
    // two way split 
    if (!node->HasAttribute("value_type")) { 
        throw std::runtime_error("Invalid node type") ;
    } 
    std::string type = node->GetAttribute("value_type") ;
    if (type == "toep") { 
        // t1+t0 used for P0,t1+t2 used for P1,t1 used for P2
        Toep2d* toep = static_cast<Toep2d*>(node->GetValue()) ;
        Toep2d* t0 = toep->operator()(0,toep->Size()/2, toep->Size()/2) ;
        Toep2d* t1 = toep->operator()(toep->Size()/2,0, toep->Size()/2) ;
        Toep2d* t2 = toep->operator()(0,0, toep->Size()/2) ;
        Toep2d* p2_t = t1; // used for t2  
        // create data nodes for toeps
        //DataNode
        // create op nodes for t1+t0 and t1+t2 
        OpNode<Toep2d, Toep2d>* p0_t = new OpNode<Toep2d, Toep2d>(Opcode_t::ADD) ; 
        OpNode<Toep2d, Toep2d>* p1_t = new OpNode<Toep2d, Toep2d>(Opcode_t::ADD) ; 
        
    } 
    else if (type == "vec") { 
        // v0 used for P0,v1 used for P1,v0-v1 used for P2
        Vec1d* vec= static_cast<Vec1d*>(node->GetValue()) ;
        Vec1d* v0 = vec->operator()(0, vec->Size()/2) ;
        Vec1d* v1 = vec->operator()(vec->Size()/2, vec->Size()) ;
        Vec1d* v2 = new Vec1d(m_buffer, vec->Size()/2) ; 
        // Create data nodes for vecs 
        // create op nodes for v0-v1
        
    } 
    else { 
        // error 
        throw std::runtime_error("Invalid node type") ;
    }
}
void DecompositionGraphBuilder::SplitThreeWay(Node* node) { 
    // three way split 
}
