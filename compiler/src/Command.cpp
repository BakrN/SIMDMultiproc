#include "Command.h"
#include "Algo.h"
#include "Graph.h"
#include <unordered_map>
static int s_max_cmd_elements = 100 ; 
static int CMD_ID = 1 ; 
static int toep_offset = 0 ; 
static int vec_offset = 0  ; 
Command CreateCommand(OpNode* node , int cmd_id , int dep_id ) {
    int addr0 , addr1 , wrbackaddr , count; 
    bool rtol = false ;
    if (node->GetAttribute("value_type") == "toep") {  
        // both are toep 
        Toep2d* toep0 = static_cast<Toep2d*>(node->Inputs()[0]->GetValue()) ;
        Toep2d* toep1 = static_cast<Toep2d*>(node->Inputs()[1]->GetValue()) ; 
        Toep2d* result = static_cast<Toep2d*>(node->GetValue()) ;
        addr0 = toep0->GetColRef().GetAddr() + toep_offset; 
        addr1 = toep1->GetColRef().GetAddr() + toep_offset; 
        wrbackaddr = result->GetColRef().GetAddr() +toep_offset; 
        count = 2*toep0->Size()-1;  
        rtol = node->HasAttribute("rtol");
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
            Vec1d* result = static_cast<Vec1d*>(node->GetValue()) ;
            addr0 = toep->GetColRef().GetAddr() + toep_offset; 
            addr1 = vec->GetRef().GetAddr() +vec_offset; 
            wrbackaddr = result->GetRef().GetAddr() +vec_offset; 
            count = toep->Size(); // doesn't really matter in this case  
        } else { // both vec
            Vec1d* vec0 = static_cast<Vec1d*>(node->Inputs()[0]->GetValue()) ;
            Vec1d* vec1 = static_cast<Vec1d*>(node->Inputs()[1]->GetValue()) ; 
            Vec1d* result = static_cast<Vec1d*>(node->GetValue()) ;
            addr0 = vec0->GetRef().GetAddr()+vec_offset; 
            addr1 = vec1->GetRef().GetAddr()+vec_offset; 
            wrbackaddr = result->GetRef().GetAddr()+vec_offset; 
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
            rtol
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
// toep depends on vec 
void DecomposerCommandGenerator::FindAndEnqueueUsers(Node* node , std::unordered_map<Node* , int>& enqueued, int dep_id, GEN_MODE mode){ 

    Command cmd = CreateCommand(static_cast<OpNode*>(node) , CMD_ID, dep_id) ; 
    if (mode == GEN_MODE::TOEP) { 
        m_toep_commands.push_back(cmd) ;
    } else if (mode == GEN_MODE::VEC) { 
        m_vec_commands.push_back(cmd) ;
    }  else{
        m_recomp_commands.push_back(cmd) ;
    }
    enqueued[node] = CMD_ID; 
    int ID = CMD_ID ;  
    CMD_ID++ ;  
    std::queue<Node*> dep_cmds; 
    std::queue<Node*> search_nodes;  
    search_nodes.push(node) ;

    while(!search_nodes.empty() ) { 
        Node* current = search_nodes.front() ;
        search_nodes.pop() ; 
        for ( auto& user : current ->Users() ) {
            if ( user->GetAttribute("node_type") == "op") { 
                if (mode != GEN_MODE::VEC) { 
                    if (static_cast<OpNode*>(user)->GetOpcode() == Opcode_t::MMUL_2x || static_cast<OpNode*>(user)->GetOpcode() == Opcode_t::MMUL_3x) { 
                        continue ; 
                    }
                }
                dep_cmds.push(user) ;
            }  else { 
                search_nodes.push(user) ;
            } 
        }
    } 
    // call previous function on all command in dep_cmds
    while (!dep_cmds.empty()) { 
        Node* dep_cmd = dep_cmds.front() ;
        dep_cmds.pop(); 
        if (enqueued.find(dep_cmd) == enqueued.end()) { 
            //  if vec with size <= 2 and %2 ==0 or size <= 3 and %3 == 0 then dep cmd is toeplitz 
            //  if matmul then dep cmd is vec  
            //  if recomp 
            FindAndEnqueueUsers(dep_cmd , enqueued, ID, mode) ; // prev
            // FindAndEnqueueUsers(dep_cmd , enqueued, ID, exclude_mamtul=true) ; // prev
        }
    }
}


// assumes 1 to 1 dependency relationships   (work on dep later
void DecomposerCommandGenerator::Generate(bool toep, bool vec, bool recomp) { 
    // last 2x2/3x3 mult depends on last vec decomposition depends on toeplitz decomposition
    Graph* recomp_graph = new Graph(m_root); 
    Graph* toep_graph   = new Graph(static_cast<ProductNode*>(m_root)->GetToepNode()); 
    Graph* vec_graph    = new Graph(static_cast<ProductNode*>(m_root)->GetVecNode());
    std::unordered_map<Node* , int > enqueued;  // node to command id (very inefficient but whatever fix later ) 
                                                // decomposition 

    if (toep){ 
        Toep2d* mat = static_cast<Toep2d*>(toep_graph->GetRoot()->GetValue()) ; 
        toep_offset = -mat->GetColRef().GetBuffer()->GetStart(); 
        vec_offset = mat->GetColRef().GetBuffer()->GetFree() + toep_offset;
    for ( auto it = toep_graph->begin() ; it != toep_graph->end() ; ++it) { 

        if ( (*it).GetAttribute("node_type") == "op" && (*it).GetAttribute("value_type") == "toep" ) {
            // create command 
            Node* node = &(*it) ;
            if (enqueued.find(node) != enqueued.end()) { 
                continue ; 
            }
            FindAndEnqueueUsers(node , enqueued ,0, GEN_MODE::TOEP) ;

        }
    }
    } 
    //// vec command generation 
    if (vec){ 
    enqueued.clear(); 
    for ( auto it = vec_graph->begin() ; it != vec_graph->end() ; ++it) { 

        if ( (*it).GetAttribute("node_type") == "op") {
            // create command 
            Node* node = &(*it) ;
            if (enqueued.find(node) != enqueued.end()) { 
                continue ; 
            }
            FindAndEnqueueUsers(node , enqueued ,0,  GEN_MODE::VEC) ;

        }
    }
    }
    //////// recomposition  
    if (recomp) {
   enqueued.clear(); 
   for ( auto it = recomp_graph->rbegin() ; it != recomp_graph->rend() ; ++it) { 
       // 
       if ( (*it).GetAttribute("node_type") == "op" && (static_cast<OpNode&>((*it)).GetOpcode() == Opcode_t::SUB || static_cast<OpNode&>((*it)).GetOpcode() == Opcode_t::ADD)) {
           // create command  
           Node* node = &(*it) ;
           if (enqueued.find(node) != enqueued.end()) { 
               continue ; 
           }
           //FindAndEnqueueUsers(node , enqueued ,0 ,  GEN_MODE::RECOMPOSE) ;
            m_recomp_commands.emplace_back(CreateCommand(static_cast<OpNode*>(node) , CMD_ID, 0)); 

       }
    } 
    }
    //delete recomp_graph ; 
    //delete toep_graph  ; 
    //delete vec_graph; 
} 

std::ostream& operator<<(std::ostream& os , const Command& cmd ) { 
        std::string op = (cmd.operation == Opcode_t::ADD) ? "ADD" : (cmd.operation == Opcode_t::SUB) ? "SUB" : (cmd.operation == Opcode_t::MMUL_2x) ? "MMUL_2x" : "MMUL_3x" ;
        os << "id: " << cmd.id << " dep: " << cmd.dep << " operand0: " << cmd.operand0 << " operand1: " << cmd.operand1 << " wrbackaddr: " << cmd.wrbackaddr << " count: " << cmd.count << " operation: " << op << " rtol: " << cmd.rtol << std::endl;
        return os;
} ;
std::vector<Command>& DecomposerCommandGenerator::GetCommands() {
    // return m_commands;
}
std::vector<Command>& DecomposerCommandGenerator::GetToepCommands() {
    return m_toep_commands;
}
std::vector<Command>& DecomposerCommandGenerator::GetVecCommands() {
    return m_vec_commands;
}
std::vector<Command>& DecomposerCommandGenerator::GetRecompCommands(){
    return m_recomp_commands;
}
