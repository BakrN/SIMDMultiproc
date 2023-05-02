#pragma once 
#include "Operator.h" 
#include "Graph.h"
#include <fstream> 
#include <bitset> 

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

void CommandToBinary(char* buffer , Command& cmd) ;  

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

        void FindAndEnqueueUsers(Node* node, std::unordered_map<Node* , int>& enqueued , int cmd_id, int dep_id , GEN_MODE mode ) ;  
        void FindAndEnqueueInputs(Node* node, std::unordered_map<Node* , int>& enqueued , int cmd_id, GEN_MODE mode ) ;  
        Node* m_root;   
};

// Generate hex file for hardware testing
class Serializer { 
    public: 
        static void SerializeCommand(std::vector<Command>& commands , std::string filename , bool append=false) ; 
        template <typename T> 
        static void SerializeMem(T* mem ,  int count , std::string filename) { 
            std::ofstream file (filename, std::ios::out) ; 

            for (int i = 0 ; i < count ; i ++ ) {
                std::bitset<32> val(mem[i]);
                file.write(val.to_string().c_str(), val.to_string().length()) ;  
                file.write("\n", 1) ; 
            }
            file.close() ; 
        } ; 

} ; 
