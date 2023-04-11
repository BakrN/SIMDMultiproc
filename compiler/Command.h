#pragma once 
#include "Operator.h" 
#include "Graph.h"
struct Command {  
    int id ; 
    int dep ; 
    int operand0 ;  // operand0 address
    int operand1 ;  // operand1 address
    int wrbackaddr; 
    int count  ;
    Opcode_t operation ;  
    // Following two member are only used for testing matmul2x2 and matmul3x3
    Toep2d* toep ; 
    Vec1d* vec ;
} ; 


// only commands generator on T's and vectors
class DecomposerCommandGenerator{ 
    public: 
        DecomposerCommandGenerator() ; 
        DecomposerCommandGenerator(Node* node) ; 
        ~DecomposerCommandGenerator() ; 
        void Generate() ; 
    private: 
        std::vector<Command> m_commands ;  
        void FindAndEnqueueUsers(Node* node) ; 
        Node* m_root;  
};

// Generate hex file for hardware testing
class CommandSerializer {
} ; 
