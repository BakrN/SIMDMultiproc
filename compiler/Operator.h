#pragma once 
// For the operator we'll need,to be able to accept multiple different input types (whether they're toep, vec , vec toep
#include "Buffer.h"
#include "Toeplitz.h" 
#include "Vec.h"
#include "Graph.h" 
#include <type_traits>
#include <assert.h>

// Will need to add a new node for double dependency 
class ProductNode : public Node { 
    public: 
        ProductNode(Node* toep, Node* vec ,bool overwrite =false) ; 
        ~ProductNode() ;  
        void* GetValue() override ; 
        Node* GetToepNode() ; 
        Node* GetVecNode()  ;  
    private: 
        Node* m_toep ; 
        Node* m_vec ;
        Vec1d* m_result ;
} ; 
enum class Opcode_t {
    ADD, 
    SUB, 
    MMUL_2x, // 2x2Mul 
    MMUL_3x  // 3x3 Mul
} ; 

class OpNode : public Node{ 
    public: 
        // if mul toep and vec then -> or both vec 
        // using res_type = std::conditional_t<(std::is_same<T, Vec1d>::value && std::is_same<U,Vec1d>::value)||(std::is_same<T, U>::value), Vec1d, Toep2d> ; 
        OpNode(Opcode_t op) ; 
        ~OpNode() ;
        void* GetValue() override ;
        void SetOperands(Node* operand0 , Node* operand1) ;  
        void SetOperands(Node* operand0 , Node* operand1, const BufferRef& ref) ;
        
    private:
        Opcode_t m_opcode ; 
        void*  m_result ;  
}; 
// Either new data or a reference to existing data (partitioning)
class DataNode : public Node {
    public: 
        DataNode() ;
        template<typename T>
        DataNode(T* data) ; 
        ~DataNode() ; 
        void* GetValue() override ;
    private: 
        void* m_data ; 
} ;


template<typename T>
DataNode::DataNode(T* data) : m_data(data) {
    std::string vtype = (typeid(T) == typeid(Toep2d)) ? "toep" : "vec" ;
    this->AddAttribute("value_type", vtype) ;  
    this->AddAttribute("node_type", "data" ) ; 
} 


