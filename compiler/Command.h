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
} ; 

// generates command according to decomposition algorithm
class CommandGenerator{  
    public: 
        CommandGenerator() ; 
        CommandGenerator(Graph* graph) {m_graph = graph;} ; 
        virtual ~CommandGenerator() ; 
        virtual void Generate() ; 
        void AttachGraph(Graph* graph) {m_graph = graph;} ;
    private: 
        Graph* m_graph; 
}; 


// only commands generator on T's and vectors
class DecomposerCommandGenerator : public CommandGenerator{ 
    public: 
        DecomposerCommandGenerator() ; 
        DecomposerCommandGenerator(Node* node) ; 
        ~DecomposerCommandGenerator() ; 
        void Generate() override ; 
    private: 
        std::vector<Command> m_commands ; 
        Node* m_root;  
};

// Only commands on P vectos 
class CommandSerializer {
} ; 
