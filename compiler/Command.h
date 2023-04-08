#pragma once 
#include "Operator.h" 
#include "Graph.h"
struct Command {  
    int m_id ; 
    int m_dep ; 
    int m_operand0 ;  // operand0 address
    int m_operand1 ;  // operand1 address
    int m_wrbackaddr; 
    Opcode_t m_operation ; 
} ; 
// generates command according to decomposition algorithm
class CommandGenerator{  
    public: 
        CommandGenerator() ; 
        CommandGenerator(Graph* graph) {m_graph = graph;} ; 
        virtual ~CommandGenerator() ; 
        virtual void Generate() ; 
        void AttachGraph(Graph* graph) {m_graph = graph;} ;
        Graph* m_graph; 
}; 


// only commands generator on T's and vectors
class DecomposerCommandGenerator : public CommandGenerator{ 
    public: 
        DecomposerCommandGenerator() ; 
        DecomposerCommandGenerator(Graph* graph) ; 
        ~DecomposerCommandGenerator() ; 
        void Generate() override ; 
    private: 
        std::vector<Command> m_commands ; 
        Graph* m_graph; 
};

// Only commands on P vectos 
class CommandSerializer {
} ; 
