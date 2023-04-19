#pragma once 
#include "Operator.h" 
#include "Graph.h"

// Recomp -> matmul -> vec -> toep
enum class GEN_MODE{ 
    RECOMPOSE, 
    TOEP, 
    VEC
} ; 
struct Command {  
    int id ; 
    int dep ; 
    int operand0 ;  // operand0 address
    int operand1 ;  // operand1 address
    int wrbackaddr; 
    int count  ;
    Opcode_t operation ;  
    // test bit 
    bool rtol; // right ot left
} ; 
std::ostream& operator<<(std::ostream& os , const Command& cmd ); 

// only commands generator on T's and vectors
class DecomposerCommandGenerator{ 
    public: 
        DecomposerCommandGenerator() ; 
        DecomposerCommandGenerator(Node* node) ; 
        ~DecomposerCommandGenerator() ; 
        void Generate(bool toep=true, bool vec=true, bool recomp=true) ;  
        std::vector<Command>& GetCommands() ;
        std::vector<Command>& GetToepCommands() ; 
        std::vector<Command>& GetVecCommands() ; 
        std::vector<Command>& GetRecompCommands() ; 
    private: 
        std::vector<Command> m_toep_commands ;  
        std::vector<Command> m_vec_commands ;
        std::vector<Command> m_recomp_commands;  

        void FindAndEnqueueUsers(Node* node, std::unordered_map<Node* , int>& enqueued , int dep_id , GEN_MODE mode ) ;  
        Node* m_root;   
};

// Generate hex file for hardware testing
class CommandSerializer {
} ; 
