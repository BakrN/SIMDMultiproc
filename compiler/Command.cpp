#include "Command.h"
#include "Graph.h"
static int s_max_cmd_elements = 100 ; 

Command CreateCommand(OpNode* node , int cmd_id , int dep_id ) {
    int addr0 , addr1 , wrbackaddr , count; 
    Toep2d* MAT= nullptr ;
    Vec1d*  VEC= nullptr ; 
    if (node->GetAttribute("value_type") == "toep") {  
        // both are toep 
        Toep2d* toep0 = static_cast<Toep2d*>(node->Inputs()[0]->GetValue()) ;
        Toep2d* toep1 = static_cast<Toep2d*>(node->Inputs()[1]->GetValue()) ; 
        Toep2d* result = static_cast<Toep2d*>(node->GetValue()) ;
        addr0 = toep0->GetColRef().GetAddr(); 
        addr1 = toep1->GetColRef().GetAddr(); 
        wrbackaddr = result->GetColRef().GetAddr(); 
        count = 2*toep0->Size()-1; 
    }  else if (node->GetAttribute("value_type") == "vec") {  
        if (node->GetOpcode() == Opcode_t::MMUL_2x || node->GetOpcode() == Opcode_t::MMUL_3x) { 
            // one is toep, one is vec  
            //
            Toep2d* toep;
            Vec1d* vec;    
            if (node->Inputs()[0]->GetAttribute("value_type") == "toep") {
                toep = static_cast<Toep2d*>(node->Inputs()[0]->GetValue()) ;
                vec = static_cast<Vec1d*>(node->Inputs()[1]->GetValue()) ; 
            } else {
                toep = static_cast<Toep2d*>(node->Inputs()[1]->GetValue()) ;
                vec = static_cast<Vec1d*>(node->Inputs()[0]->GetValue()) ; 
            } 
            MAT = toep ; 
            VEC = vec ;
            Vec1d* result = static_cast<Vec1d*>(node->GetValue()) ;
            addr0 = toep->GetColRef().GetAddr(); 
            addr1 = vec->GetRef().GetAddr(); 
            wrbackaddr = result->GetRef().GetAddr(); 
            count = toep->Size(); // doesn't really matter in this case  
        } else { // both vec
            Vec1d* vec0 = static_cast<Vec1d*>(node->Inputs()[0]->GetValue()) ;
            Vec1d* vec1 = static_cast<Vec1d*>(node->Inputs()[1]->GetValue()) ; 
            Vec1d* result = static_cast<Vec1d*>(node->GetValue()) ;
            addr0 = vec0->GetRef().GetAddr(); 
            addr1 = vec1->GetRef().GetAddr(); 
            wrbackaddr = result->GetRef().GetAddr(); 
            count = vec0->Size();
        } 
    } 
    Command cmd( { 
        cmd_id ,
        dep_id ,
        addr0 ,
        addr1 ,
        wrbackaddr ,
        count ,
        node->GetOpcode() ,
        MAT,
        VEC
            })  ; 
    return cmd;
} 

DecomposerCommandGenerator::DecomposerCommandGenerator() {  
    
}
DecomposerCommandGenerator::DecomposerCommandGenerator(Node* node) { 
    m_root = node;
} 
DecomposerCommandGenerator::~DecomposerCommandGenerator() {  

}

// assumes 1 to 1 dependency relationships  
void DecomposerCommandGenerator::Generate() { 
    // last 2x2/3x3 mult depends on last vec decomposition depends on toeplitz decomposition
    Graph* recomp_graph = new Graph(m_root); 
    Graph* toep_graph   = new Graph(static_cast<ProductNode*>(m_root)->GetToepNode()); 
    Graph* vec_graph    = new Graph(static_cast<ProductNode*>(m_root)->GetVecNode());
    std::unordered_map<Node* , int > enqueued;  // node to command id
    // decomposition 

    int cmd_id = 0 ;    
    int dep_id = 0 ; 
    for ( auto it = toep_graph->begin() ; it != toep_graph->end() ; ++it) { 
        if ( (*it).GetAttribute("node_type") == "op") {
            // create command 
            Node* node = &(*it) ;
            Command cmd = CreateCommand(static_cast<OpNode*>(node) , cmd_id , dep_id) ; 
            m_commands.push_back(cmd) ; 
            enqueued[&(*it)] = cmd_id ; 
            dep_id = cmd_id ; 
            cmd_id++ ;  
            std::queue<Node*> dep_cmds; 
            std::queue<Node*> search_nodes; 
            bool first_search = true ;
            while(!search_nodes.empty() && first_search) { 
                first_search = false ;
                for ( auto& user : node->Users() ) {
                    if ( user->GetAttribute("node_type") == "op") { 
                        dep_cmds.push(user) ;
                    }  else { 
                        search_nodes.push(user) ;
                    } 
                }
            } 
            // call previous function on all command in dep_cmds
            Node* dep_cmd = dep_cmds.front() ;
            dep_cmds.pop(); 
            FindAndEnqueueUsers(dep_cmds.front()) ; 

        }
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


