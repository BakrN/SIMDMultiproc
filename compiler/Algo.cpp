#include "Algo.h"
#include "Toeplitz.h"
#include "Operator.h"
#include <stdexcept>
DecompositionGraphBuilder::DecompositionGraphBuilder(Buffer& buffer, Node* root) :m_buffer(buffer){ 
    m_root = root ; 
    m_graph = new Graph(root) ;  
}
DecompositionGraphBuilder::~DecompositionGraphBuilder() { 
    delete m_graph ;  
}
Graph* DecompositionGraphBuilder::BuildGraph() { 
    // Generate Decomposition graph for toeplitz and vec 
    // While generating decomp , build parallel Recomp graph 

    // std::stack
    // identify 
    // Matmul unit<F12> 
    // 2x2 nodes
    std::queue<Node*> q ;
    q.push(m_root) ;
    while(!q.empty()) { 
        Node* node = q.front() ;
        q.pop() ;
        if(node->GetAttribute("node_type") == "product") { 
            ProductNode* pnode = static_cast<ProductNode*>(node) ;
            if(pnode->GetToepNode() != nullptr && pnode->GetVecNode() != nullptr) { 
                // check if we reached size 2 
                Toep2d* toep = static_cast<Toep2d*>(pnode->GetToepNode()->GetValue()); 
                if (toep->Size() > 2) { 
                    // split node 
                    SplitTwoWay(pnode) ;
                } else { 
                    OpNode* op = new OpNode(Opcode_t::MMUL_2x) ;
                    Vec1d* vec = static_cast<Vec1d*>(pnode->GetVecNode()->GetValue()) ;
                    BufferRef ref = BufferRef(vec->GetRef().GetBuffer(), vec->GetRef().GetAddr(), vec->GetRef().GetSize()) ;
                    op->SetOperands(pnode->GetToepNode(), pnode->GetVecNode(), ref) ;
                } 
            }
        }

        for(auto input: node->Inputs()) { 
            q.push(input) ;
        }
    }
    
    return m_graph; 
} 


void DecompositionGraphBuilder::SplitTwoWay(ProductNode* node) { 

    // two way split 
    /* y0 = t1*v0 + t0*v1 = p0 + p2
     * y1 = t2*v0 + t1*v1 = p1 - p2 
     * p0 = (t0+t1)(v1) 
     * p1 = (t1+t2)(v0) 
     * p2 = t1 	(v0-v1)
     */
    std::string type = node->GetAttribute("value_type") ;
    // toeplitz decomposition
    // t1+t0 used for P0,t1+t2 used for P1,t1 used for P2
    Toep2d* toep = static_cast<Toep2d*>(node->GetToepNode()->GetValue()) ;
    Toep2d* t0 = toep->operator()(0,toep->Size()/2, toep->Size()/2) ; // error here
    Toep2d* t2 = toep->operator()(toep->Size()/2,0, toep->Size()/2) ;
    Toep2d* t1 = toep->operator()(0,0, toep->Size()/2) ;
    // create data nodes for toeps
    DataNode* dn_t0 = new DataNode(t0) ; 
    DataNode* dn_t1 = new DataNode(t1) ; 
    DataNode* p2_t  = new DataNode(t2) ; 
    // create op nodes for t1+t0 and t1+t2 
    OpNode* p0_t = new OpNode(Opcode_t::ADD) ; 
    OpNode* p1_t = new OpNode(Opcode_t::ADD) ; 
    p0_t->SetOperands(dn_t0, dn_t1) ;
    p1_t->SetOperands(dn_t1, p2_t) ;  
    // add inputs to toep
    p0_t->AddInput(node->GetToepNode()) ;
    p1_t->AddInput(node->GetToepNode()) ;
    p2_t->AddInput(node->GetToepNode()) ;
    // add users to node 

    node->GetToepNode()->AddUser(p0_t) ;
    node->GetToepNode()->AddUser(p1_t) ;
    node->GetToepNode()->AddUser(p2_t) ; 
    // Vector decomposition
    // v0 used for P0,v1 used for P1,v0-v1 used for P2
    Vec1d* vec= static_cast<Vec1d*>(node->GetVecNode()->GetValue()) ;
    std::cout << "getting vec0" << std::endl;
    Vec1d* v0 = vec->operator()(0, vec->Size()/2) ;
    Vec1d* v1 = vec->operator()(vec->Size()/2, vec->Size()/2) ;
    std::cout << "Finished Getting vec1" << std::endl;
    // Create data nodes for vecs  
    DataNode* p0_v = new DataNode(v0) ;
    DataNode* p1_v = new DataNode(v1) ;
    // create op nodes for v0-v1
    OpNode* p2_v = new OpNode(Opcode_t::SUB) ;
    p2_v->SetOperands(p0_v, p1_v) ;
    // add inputs to vec
    p0_v->AddInput(node->GetVecNode()) ;
    p1_v->AddInput(node->GetVecNode()) ;
    // add users to nodes
    node->GetVecNode()->AddUser(p0_v) ;
    node->GetVecNode()->AddUser(p1_v) ;
    ProductNode* p0 = new ProductNode(p0_t ,p0_v,true)   ;
    ProductNode* p1 = new ProductNode(p1_t ,p1_v,true)   ;
    ProductNode* p2 = new ProductNode(p1_t ,p2_v,true)  ; 
    // Reduce p0 , p1 ,p2 to get original node 
    OpNode* reduce0 = new OpNode(Opcode_t::ADD) ;
    OpNode* reduce1 = new OpNode(Opcode_t::SUB) ;
    BufferRef ref_0 = BufferRef(vec->GetRef().GetBuffer(), vec->GetRef().GetAddr(), vec->GetRef().GetSize()/2) ;
    BufferRef ref_1 = BufferRef(vec->GetRef().GetBuffer(), vec->GetRef().GetAddr()+vec->GetRef().GetSize()/2, vec->GetRef().GetSize()/2) ;
    reduce0->SetOperands(p0, p2, ref_0) ;
    reduce1->SetOperands(p1, p2, ref_1) ;
    node->AddInput(reduce0) ;
    node->AddInput(reduce1) ;

    reduce0->AddUser(node) ;
    reduce1->AddUser(node) ; 
}
void DecompositionGraphBuilder::SplitThreeWay(Node* node) { 
    // three way split  
    // recursively split the nodes
    /*Y0 = t2*v0 + t1*v1 + t0*v2 = p0 + p3 + p4 
     *y1 = t3*v0 + t2*v1 + t1*v2 = p1 + p3 + p5
     *y2 = t4*v0 + t3*v1 + t2*v2 = p2 + p4 + p5 
     *p0 = (t0 - t1 - t2)(v2)
     *p1 = (t2 - t1 - t3)(v1) 
     *p2 = (t4 - t3 - t2)(v0) 
     *p3 = t1(v1+v2) 
     *p4 = t2(v0+v2) 
     *p5 = t3(v0+v1) 
     */
    if (!node->HasAttribute("value_type")) { 
        throw std::runtime_error("Invalid node type") ;
    } 
    std::string type = node->GetAttribute("value_type") ;
    if (type == "toep") { 
        // t1+t0 used for P0,t1+t2 used for P1,t1 used for P2
        Toep2d* toep = static_cast<Toep2d*>(node->GetValue()) ;
        Toep2d* t0 = toep->operator()(0,2*toep->Size()/3, toep->Size()/3) ;
        Toep2d* t1 = toep->operator()(0,toep->Size()/3, toep->Size()/3) ;
        Toep2d* t2 = toep->operator()(0,0, toep->Size()/3) ;
        Toep2d* t3 = toep->operator()(toep->Size()/3,0, toep->Size()/3) ; 
        Toep2d* t4 = toep->operator()(2*toep->Size()/3,0, toep->Size()/3) ;
        // create data nodes for toeps
        DataNode* dn_t0 = new DataNode(t0) ; 
        DataNode* dn_t1 = new DataNode(t1) ; 
        DataNode* dn_t2 = new DataNode(t2) ; 
        DataNode* dn_t3 = new DataNode(t3) ; 
        DataNode* dn_t4 = new DataNode(t4) ; 
        // create op nodes 
        OpNode* p0_t_0 = new OpNode(Opcode_t::SUB) ;// t0-t1 
        OpNode* p0_t_1 = new OpNode(Opcode_t::SUB) ;// t0-t1-t2
        OpNode* p1_t_0 = new OpNode(Opcode_t::SUB) ;// t2-t1
        OpNode* p1_t_1 = new OpNode(Opcode_t::SUB) ;// t2-t1-t3
        OpNode* p2_t_0 = new OpNode(Opcode_t::SUB) ;// t4-t3
        OpNode* p2_t_1 = new OpNode(Opcode_t::SUB) ;// t4-t3-t2
                                                    // add inputs to toep (setting operands) 
        p0_t_0->SetOperands(dn_t0, dn_t1) ;
        p0_t_1->SetOperands(p0_t_0, dn_t2) ;
        p1_t_0->SetOperands(dn_t2, dn_t1) ;
        p1_t_1->SetOperands(p1_t_0, dn_t3) ;
        p2_t_0->SetOperands(dn_t4, dn_t3) ;
        p2_t_1->SetOperands(p2_t_0, dn_t2) ;
        // add node to datanodes as input 
        dn_t0->AddInput(node) ;
        dn_t1->AddInput(node) ;
        dn_t2->AddInput(node) ;
        dn_t3->AddInput(node) ;
        dn_t4->AddInput(node) ;
        // add users to node  
        node->AddUser(dn_t0) ;
        node->AddUser(dn_t1) ;
        node->AddUser(dn_t2) ;
        node->AddUser(dn_t3) ;
        node->AddUser(dn_t4) ;
    } 
    else if (type == "vec") { 
        // v0 used for P0,v1 used for P1,v0-v1 used for P2
        Vec1d* vec= static_cast<Vec1d*>(node->GetValue()) ;
        Vec1d* v0 = vec->operator()(0, vec->Size()/3) ;
        Vec1d* v1 = vec->operator()(vec->Size()/3, vec->Size()/3) ;
        Vec1d* v2 = vec->operator()(2*vec->Size()/3, vec->Size()/3) ;
        // Create data nodes for vecs  
        DataNode* dn_v0 = new DataNode(v0) ;
        DataNode* dn_v1 = new DataNode(v1) ;
        DataNode* dn_v2 = new DataNode(v1) ;
        // creat op nodes 
        OpNode* p3_v = new OpNode(Opcode_t::ADD) ;
        OpNode* p4_v = new OpNode(Opcode_t::ADD) ;
        OpNode* p5_v = new OpNode(Opcode_t::ADD) ;
        // Set operands of op nodes 
        p3_v->SetOperands(dn_v1, dn_v2) ;
        p4_v->SetOperands(dn_v0, dn_v2) ;
        p5_v->SetOperands(dn_v0, dn_v1) ;
        // add node as input to datanodes  
        dn_v0->AddInput(node) ;
        dn_v1->AddInput(node) ;
        dn_v2->AddInput(node) ;
        // add users to nodes
        node->AddUser(dn_v0) ;
        node->AddUser(dn_v1) ;
        node->AddUser(dn_v2) ; 
    } 
    else { 
        // error 
        throw std::runtime_error("Invalid node type") ;
    } 

}
