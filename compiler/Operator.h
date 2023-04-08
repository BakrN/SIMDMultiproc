#pragma once 
// For the operator we'll need,to be able to accept multiple different input types (whether they're toep, vec , vec toep
#include "Buffer.h"
#include "Toeplitz.h" 
#include "Vec.h"
#include "Graph.h" 
#include <type_traits>
#include <assert.h>

class DataNode : public Node {
    public: 
        DataNode() : m_data(nullptr) {} 
        DataNode(void* data) : m_data(data) {} 
        ~DataNode() { 
            free m_data ; 
        }
        void* GetValue() override { 
            return m_data ; 
        }
    private: 
        void* m_data ; 
} ;

enum class Opcode_t {
    ADD, 
    SUB, 
    MMUL // mat mul 
} ; 

template<typename T, typename U> 
class OpNode : protected Node{ 
    public: 
        // if mul toep and vec then -> or both vec 
        using res_type = std::conditional_t<(std::is_same<T, Vec1d>::value && std::is_same<U,Vec1d>::value)||(std::is_same<T, U>::value), Vec1d, Toep2d> ; 
        OpNode(Opcode_t op) ; 
        ~OpNode() ;
        template<typename T, typename U>
        void SetOperands(Node* operand0 , Node* operand1) ;
        void Forward(BufferRef& buf) ;// without new ref
        void* GetValue() override ;
    private:
        Opcode_t m_opcode ; 
        void*  m_result ;  
}; 
template <typename T, typename U>  
void OpNode<T,U>::Forward(BufferRef& buf) {
    m_result = new res_type() ;  
    // create new toep or vec and assign 

}
template<typename T, typename U>
OpNode<T,U>::~OpNode() {
    free m_result; 
}
template<typename T, typename U>
OpNode<T,U>::OpNode(Opcode_t op) : m_opcode(op){ 
    this->SetAttribute("node_type", "op") ; 
}


template<typename T, typename U>
void OpNode<T,U>::SetOperands(Node* operand0 , Node* operand1)  {  
    this->AddInput(operand0) ;
    this->AddInput(operand1) ;
    operand0->AddUser(this) ;
    operand1->AddUser(this) ;
}
template<typename T, typename U>
void* OpNode<T,U>::GetValue() { 
    return m_result ; 
}
