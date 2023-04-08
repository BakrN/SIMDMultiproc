#pragma once 
// For the operator we'll need,to be able to accept multiple different input types (whether they're toep, vec , vec toep
#include "Buffer.h"
#include "Toeplitz.h" 
#include "Vec.h"
#include "Graph.h" 
#include <type_traits>
#include <assert.h>

// Bi directional node that encapsulates two different nodes. Only one of which is activated if in forward or backrwards mode.
class BiNode: public Node {
    public: 
        BiNode(Node* node1, Node* node2) : m_node1(node1), m_node2(node2) {} 
        ~BiNode() { 
            delete m_node1 ; 
            delete m_node2 ; 
        }
        void* GetValue() override { 
            return m_node1->GetValue() ; 
        }
        void SetForward(bool forward) {  // sets mode
            m_forward = forward ; 
        }
        bool IsForward() { 
            return m_forward ; 
        }
        Node* GetNode1() { 
            return m_node1 ; 
        }
        Node* GetNode2() { 
            return m_node2 ; 
        }  
        void* GetValue() override { 
            return m_forward ? m_node1->GetValue() : m_node2->GetValue() ; 
        } 
        
    private: 
        Node* m_node1 ; 
        Node* m_node2 ; 
        bool m_forward ;
};      
// contains corresponding pairs of toeplitz and vec nodes 
class MatVecNode : public Node { 
    public: 
        MatVecNode(Node* toep, Node* vec) : m_toep(toep), m_vec(vec) {} 
        ~MatVecNode() { 
            delete m_toep ; 
            delete m_vec ; 
        }
        void* GetValue() override { 
            return m_toep->GetValue() ; 
        }
        Node* GetToep() { 
            return m_toep ; 
        }
        Node* GetVec() { 
            return m_vec ; 
        }
    private: 
        Node* m_toep ; 
        Node* m_vec ;
} ; 
// Either new data or a reference to existing data (partitioning)
class DataNode : public Node {
    public: 
        DataNode() : m_data(nullptr) {} 
        template <typename T> 
        DataNode(T* data) : m_data(data) {
            std::string vtype = (typeid(T) == typeid(Toep2d)) ? "toep" : "vec" ;
            this->AddAttribute("value_type", vtype) ;  
            this->AddAttribute("node_type", "data" ) ; 
        } 
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

class OpNode : public Node{ 
    public: 
        // if mul toep and vec then -> or both vec 
        // using res_type = std::conditional_t<(std::is_same<T, Vec1d>::value && std::is_same<U,Vec1d>::value)||(std::is_same<T, U>::value), Vec1d, Toep2d> ; 
        OpNode(Opcode_t op) ; 
        ~OpNode() ;
        void SetOperands(Node* operand0 , Node* operand1=nullptr) ;
        void Forward(BufferRef& buf) ;// without new ref
        void* GetValue() override ;
    private:
        Opcode_t m_opcode ; 
        void*  m_result ;  
}; 
void OpNode::Forward(BufferRef& buf) {

    // create new toep or vec and assign 

}
OpNode::~OpNode() {
    free m_result; 
}
OpNode::OpNode(Opcode_t op) : m_opcode(op){ 
    this->AddAttribute("node_type", "op") ; 
}

void OpNode::SetOperands(Node* operand0 , Node* operand1)  {  
    this->AddInput(operand0) ;
    this->AddInput(operand1) ;
    std::string op0type = operand0->GetAttribute("value_type") ; 
    std::string op1type = operand0->GetAttribute("value_type") ;  
    assert(op0type == "vec" || op0type=="toep") ;
    assert(op1type == "vec" || op1type=="toep") ;
    if (op0type == "toep" && op1type == "toep") { 
        // create new toep 
        Toep2d* toep = static_cast<Toep2d*>(operand0->GetValue()) ;
        m_result = static_cast<void*>(new Toep2d(toep->GetColRef().GetBuffer(), toep->Size()));   
        this->AddAttribute("value_type", "toep") ;
    } 
    else if (op0type == "vec" && op1type == "vec") { 
        // create new vec 
        Vec1d* vec= static_cast<Vec1d*>(operand0->GetValue()) ;
        m_result = static_cast<void*>(new Vec1d(vec->GetRef().GetBuffer(), vec->Size()));    
        this->AddAttribute("value_type", "vec") ;
    } 
    else {  
        // TODO: mat mul case
        int size= 0 ; 
        Buffer* buf = nullptr;
        if (op0type=="toep") { 
            Toep2d* toep = static_cast<Toep2d*>(operand0->GetValue()) ;
            size = toep->Size() ; 
            buf = &toep->GetColRef().GetBuffer() ; 
        } 
        else { 
            Vec1d* vec = static_cast<Vec1d*>(operand0->GetValue()) ;
            size = vec->Size() ; 
            buf = &vec->GetRef().GetBuffer() ;  
        } 
        this->AddAttribute("value_type", "vec") ;
        m_result = static_cast<void*>(new Vec1d(*buf, size)) ;
    } 
    operand0->AddUser(this) ;
    operand1->AddUser(this) ; 
} 

void* OpNode::GetValue() { 
    return m_result ; 
}
