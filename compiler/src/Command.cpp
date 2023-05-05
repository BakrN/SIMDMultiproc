#include "Command.h"
#include "Algo.h"
#include "Graph.h"
#include "config.h" 
#include <unordered_map>
#include <math.h> 


static int CMD_ID = 1 ; 

static int toep_offset = 0 ; 
static int vec_offset = 0  ;  

void AddCommands(std::vector<Command>& list, OpNode* node , int cmd_id , int dep_id ) {
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
            count = (node->GetOpcode()==Opcode_t::MMUL_2x) ? 2 : 3 ; // doesn't really matter in this case  
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
    if (!(node->GetOpcode() == Opcode_t::MMUL_2x || node->GetOpcode() == Opcode_t::MMUL_3x) && count > MAX_OP_COUNT) { 
        // split it  
        int num_cmds = ceil((float)count / (float)MAX_OP_COUNT) ;
        int num_elements = ceil((float)count / (float)num_cmds) ; 

        for (int i = 0 ; i < num_cmds ; i++) { 
            int cmd_count = (i == num_cmds-1) ? count - i*num_elements : num_elements ; 
            bool _rtol = (i == num_cmds-1) ? rtol : false ;
            Command cmd( { 
                    cmd_id ,
                    dep_id ,
                    addr0 + i*num_elements ,
                    addr1 + i*num_elements ,
                    wrbackaddr + i*num_elements ,
                    cmd_count ,
                    node->GetOpcode() ,
                    _rtol
                    })  ; 
            list.emplace_back(cmd) ;
        }
    } 
    else{ 
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
        list.emplace_back(cmd) ;
    } 
} 


DecomposerCommandGenerator::DecomposerCommandGenerator() {  

}
DecomposerCommandGenerator::DecomposerCommandGenerator(Node* node) { 
    m_root = node;
} 
DecomposerCommandGenerator::~DecomposerCommandGenerator() {  

} 
// Split commands according to config 
// toep depends on vec 

Node* FindOpRoot(Node* node, std::unordered_map<Node*, int>& enqueued) { 
    // traverse backwards until we find first node of type op 
    // if we find a node that is not op, return nullptr 
    Node* root = nullptr;   // traverse backwards until we find first node of type op 
    std::queue<Node*> search_nodes;
    search_nodes.push(node) ; 
    while (!search_nodes.empty()) { 
        Node* current = search_nodes.front() ; 
        search_nodes.pop() ;
        for (auto& input : current->Inputs()) { 
            if (input->GetAttribute("node_type") == "op" && enqueued.find(input) == enqueued.end()) { 
                std::cout << "Found root " << std::endl; 
                search_nodes.push(input) ;  

                root = input; 
            } else { 
                std::cout << "Didn't Found root " << std::endl; 
                search_nodes.push(input) ;
            } 
        }
    } 
    return root ;
}   
void DecomposerCommandGenerator::FindAndEnqueueUsers(Node* node , std::unordered_map<Node* , int>& enqueued, int cmd_id , int dep_id, GEN_MODE mode) { 
    if (cmd_id == dep_id) { 
        cmd_id = std::max( (dep_id+1) % ID_BITS, MIN_CMD_ID) ;
    } 
    if (mode == GEN_MODE::TOEP) { 
        AddCommands(m_toep_commands,static_cast<OpNode*>(node), cmd_id, dep_id); 
    } else if (mode == GEN_MODE::VEC) { 
        AddCommands(m_vec_commands,static_cast<OpNode*>(node), cmd_id, dep_id); 
    }  else{
        AddCommands(m_recomp_commands,static_cast<OpNode*>(node), cmd_id, dep_id); 
    }
    enqueued[node] = cmd_id; 
    int ID = cmd_id;  
    CMD_ID = std::max((cmd_id+1) % (1 << ID_BITS),MIN_CMD_ID);  
    std::queue<Node*> dep_cmds; 
    std::queue<Node*> search_nodes;  
    search_nodes.push(node) ;

    while(!search_nodes.empty() ) { 
        Node* current = search_nodes.front() ;
        search_nodes.pop() ; 
        for ( auto& user : current->Users() ) {
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
            //// Find op inputs of dep_cmd other than node 
            //if (mode == GEN_MODE::RECOMPOSE) {
            //    FindAndEnqueueInputs(dep_cmd,enqueued, ID, mode); 
            //} 
            FindAndEnqueueUsers(dep_cmd , enqueued, CMD_ID,ID, mode) ; // prev
        } else { 
            // another node has already enqueued this node so should create command with same cmd id as parent node 
        } 

    }
} 

void DecomposerCommandGenerator::FindAndEnqueueInputs(Node* node, std::unordered_map<Node* , int>& enqueued , int cmd_id, GEN_MODE mode )  { 
            std::vector<OpNode*> input_operations;  
            std::queue<Node*> search_nodes; 
            for (auto& input : node->Inputs()) { 
                search_nodes.push(input) ;
            } 
            while (!search_nodes.empty()) {  
                Node* input = search_nodes.front() ;
                search_nodes.pop() ;
                if (input->GetAttribute("node_type") == "op" ) { 
                    if(enqueued.find(input) == enqueued.end()) {
                        input_operations.push_back(static_cast<OpNode*>(input)) ; 
                        //  find and enqueu inputs 

                    } 
                } else {
                    for (auto& in: input->Inputs()) { 
                        search_nodes.push(in) ;
                    }
                } 
            } 
            for (auto& input : input_operations) { 

                if (mode == GEN_MODE::TOEP) { 
                        //AddCommands(m_toep_commands,input, cmd_id, dep_id); 
                    } else if (mode == GEN_MODE::VEC) { 
                        //AddCommands(m_vec_commands,input, cmd_id, dep_id); 
                    }  else{
                        //AddCommands(m_recomp_commands,input, cmd_id, dep_id); 
                    }
                    //enqueued[input] = ID ;
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
                //Node* root = FindOpRoot(node, enqueued); 
                //node = root ? root : node ;
                FindAndEnqueueUsers(node , enqueued ,CMD_ID ,0, GEN_MODE::TOEP) ;

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
                //Node* root = FindOpRoot(node, enqueued); 
                //node = root ? root : node ;
                FindAndEnqueueUsers(node , enqueued ,CMD_ID  , 0,  GEN_MODE::VEC) ;

            }
        }
    }
    //////// recomposition  
    int level = -1 ; 
    int dep_id = 1 ; 
    if (recomp) {
        enqueued.clear(); 
        for ( auto it = recomp_graph->rbegin() ; it != recomp_graph->rend() ; ++it) { 
            // create command  
            if ( (*it).GetAttribute("node_type") == "op") { 
                Node* node = &(*it) ;
                if (enqueued.find(node) != enqueued.end()) { 
                    continue ; 
                } 
                Vec1d* vec = static_cast<Vec1d*>(node->GetValue()) ;
                if (level < (int)vec->Size()) { 
                    dep_id = (level==-1) ? 0 : CMD_ID ; 
                    level = (int)vec->Size() ; 
                    CMD_ID = std::max(MIN_CMD_ID, (CMD_ID+1)%(1 << ID_BITS)) ; 
                }
                //FindAndEnqueueUsers(node , enqueued ,CMD_ID, 0 ,  GEN_MODE::RECOMPOSE) ;
                AddCommands(m_recomp_commands,static_cast<OpNode*>(node), CMD_ID, dep_id); 
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

void Serializer::SerializeCommand(std::vector<Command>& commands, std::string filename, bool append) { 
    std::ios_base::openmode mode; 
    
    if (append) {  
       mode = std::ios::out | std::ios::app ; 
    } else { 
       mode = std::ios::out; 
    } 


    std::ofstream file(filename, mode);
    if (!file.is_open()) {
        std::cout << "Error opening file " << filename << std::endl;
        return;
    }  

    for (auto& cmd : commands) { 
        std::bitset<ID_BITS> id(cmd.id);
        std::bitset<ID_BITS> dep(cmd.dep);
        std::bitset<ADDR_BITS> operand0(cmd.operand0);
        std::bitset<ADDR_BITS> operand1(cmd.operand1);
        std::bitset<ADDR_BITS> wrbackaddr(cmd.wrbackaddr);
        std::bitset<COUNT_BITS> count(cmd.count);
        std::bitset<OPCODE_BITS> opcode(cmd.operation); 
        std::string cmd_str = id.to_string() + dep.to_string() +opcode.to_string()+ operand0.to_string() + operand1.to_string() +  count.to_string() + wrbackaddr.to_string()  ;
        file.write(cmd_str.c_str(), cmd_str.length());
        file.write("\n", 1);
    }
    file.close();
}
