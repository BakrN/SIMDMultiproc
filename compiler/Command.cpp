#include "Command.h"
#include "Graph.h"
static int s_max_cmd_elements = 100 ; 


DecomposerCommandGenerator::DecomposerCommandGenerator() {  
    
}
DecomposerCommandGenerator::DecomposerCommandGenerator(Node* node) { 
    m_root = node;
} 
DecomposerCommandGenerator::~DecomposerCommandGenerator() {  

}
void DecomposerCommandGenerator::Generate() { 
    // last 2x2/3x3 mult depends on last vec decomposition depends on toeplitz decomposition
    Graph* recomp_graph = new Graph(m_root); 
    Graph* toep_graph   = new Graph(static_cast<ProductNode*>(m_root)->GetToepNode()); 
    Graph* vec_graph    = new Graph(static_cast<ProductNode*>(m_root)->GetVecNode());
    std::unordered_map<Node* , int > enqueued;  // node to command id
    // decomposition
    // Toeplitz Iterator 
    // decompostion 
    // toep command generation   
    int cmd_id = 0 ; 
    for ( auto it = toep_graph->begin() ; it != toep_graph->end() ; ++it) { 
        if ( (*it).GetAttribute("node_type") == "op") { 
                OpNode& op = static_cast<OpNode&>(*it) ;
                enqueued[&op] = cmd_id; 
                cmd_id++;

                if (op.GetOpcode() == Opcode_t::ADD) {
                } else if (op.GetOpcode() == Opcode_t::SUB){ 

                } else {  
                    // mat mul 
                } 
            }
            // generate command 
            // push to command list 
    }
    // vec command generation 
    for ( auto it = vec_graph->begin() ; it != vec_graph->end() ; ++it) { 

    }
    // recomposition  
    for ( auto it = recomp_graph->rbegin() ; it != recomp_graph->rend() ; ++it) { 
    
    }
    delete recomp_graph ; 
    delete toep_graph  ; 
    delete vec_graph; 
} 


