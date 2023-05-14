#include "Operator.h" 
#include <type_traits>
#include <iostream> 
#include <limits.h>
ProductNode::ProductNode(Node* toep, Node* vec ,bool overwrite) : m_toep(toep), m_vec(vec) {
    this->AddAttribute("node_type", "product") ; 
    this->AddAttribute("value_type", "vec") ;  
    toep->SetParent(this); 
    vec->SetParent(this); 
    m_result = new Vec1d(*static_cast<Vec1d*>(vec->GetValue())); 
    //if(overwrite) { 
    //    //std::cout << "Address of ptr: " << static_cast<Vec1d*>(vec->GetValue()) << std::endl ;
    //    m_result = new Vec1d(*(static_cast<Vec1d*>(vec->GetValue())));  

    //} else { 
    //    m_result = new Vec1d(static_cast<Vec1d*>(vec->GetValue())->GetRef().GetBuffer(), static_cast<Vec1d*>(vec->GetValue())->Size()) ;
    //}
}  

void ProductNode::SetVecNode(Node* vec) { 
    if(m_result) { 
        delete m_result ;
    } 
    m_vec->SetParent(nullptr) ;
    vec->SetParent(this); 
    m_vec = vec ; 
    m_result = new Vec1d(*static_cast<Vec1d*>(vec->GetValue())) ; 
}
ProductNode::~ProductNode() { 
};  
void ProductNode::GetResultFromInputs() { 
    // IMPORTANT 
    // ASSUMES contiguous inputs on the same BufferRef (no checks for now
    if (m_result) { 

        delete m_result ; 
    }
    // get min index  , get max size
    int min_index  = INT_MAX; 
    int total_size = 0 ; 
    Buffer* buf = nullptr; 
    for (auto& node : this->Inputs()){ 
        Vec1d* vec = static_cast<Vec1d*>(node->GetValue()) ;
        min_index = std::min(vec->GetRef().GetAddr(), min_index) ;
        total_size += vec->Size() ; 
        buf = vec->GetRef().GetBuffer() ;
    } 
    m_result = new Vec1d(BufferRef(buf, min_index, total_size)) ;


} 


void* ProductNode::GetValue() { 
    return m_result ;
}

Node* ProductNode::GetToepNode() { 
    return m_toep ; 
}
Node* ProductNode::GetVecNode() { 
    return m_vec ; 
}

OpNode::OpNode(Opcode_t op) { 
    m_opcode = op ; 
    this->AddAttribute("node_type", "op") ; 
}
OpNode::~OpNode() { 
    if(this->GetAttribute("value_type") == "toep")
        delete static_cast<Toep2d*>(m_result) ;  
    else if(this->GetAttribute("value_type") == "vec")
        delete static_cast<Vec1d*>(m_result) ; 
}
Opcode_t OpNode::GetOpcode() { 
    return m_opcode ; 
}
void OpNode::SetOperands(Node* operand0 , Node* operand1, const BufferRef& ref) { 
    this->AddInput(operand0) ;
    this->AddInput(operand1) ;
    std::string op0type = operand0->GetAttribute("value_type") ; 
    std::string op1type = operand1->GetAttribute("value_type") ;  
    assert(op0type == "vec" || op0type=="toep") ;
    assert(op1type == "vec" || op1type=="toep") ;
    if (op0type == "toep" && op1type == "toep") { 
        // create new toep 
        Toep2d* toep = static_cast<Toep2d*>(operand0->GetValue()) ;

        m_result = static_cast<void*>(new Toep2d(std::remove_const_t<BufferRef&>(ref), toep->Size()));    
        this->AddAttribute("value_type", "toep") ;
    } 
    else { 
        // create new vec 
        m_result = static_cast<void*>(new Vec1d(ref));    
        this->AddAttribute("value_type", "vec") ;
    }
    operand0->AddUser(this); 
    operand1->AddUser(this); 
} 

void OpNode::SetOperands(Node* operand0 , Node* operand1)  {  
    this->AddInput(operand0) ;
    this->AddInput(operand1) ;
    std::string op0type = operand0->GetAttribute("value_type") ; 
    std::string op1type = operand1->GetAttribute("value_type") ;  
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
        this->AddAttribute("value_type", "vec") ;
        if (op0type=="toep") { 
            Vec1d* vec = static_cast<Vec1d*>(operand1->GetValue()) ;
            m_result = static_cast<void*>(new Vec1d(vec->GetRef().GetBuffer(), vec->Size()));
        } else {
            Vec1d* vec = static_cast<Vec1d*>(operand0->GetValue()) ;
            m_result = static_cast<void*>(new Vec1d(vec->GetRef().GetBuffer(), vec->Size()));
        } 
    } 
    operand0->AddUser(this) ;
    operand1->AddUser(this) ; 
} 

void* OpNode::GetValue() { 
    return m_result ; 
}

DataNode::DataNode() : m_data(nullptr) {
    this->AddAttribute("node_type", "data") ;
} 
DataNode::~DataNode() { 
    if (this->GetAttribute("value_type") == "vec") 
        delete (Vec1d*)m_data ;
    else
        delete (Toep2d*)m_data ;
}
void* DataNode::GetValue() { 
    return m_data ; 
}
