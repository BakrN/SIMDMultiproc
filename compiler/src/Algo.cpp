#include "Algo.h"
#include "Toeplitz.h"
#include "Operator.h"
#include <stdexcept>
#include <unordered_set>
DecompositionGraphBuilder::DecompositionGraphBuilder(ProductNode* node) { 
    m_root = node; 
    m_graph = new Graph(node) ;  
}
DecompositionGraphBuilder::~DecompositionGraphBuilder() { 
    // delete m_graph ;  
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
    std::unordered_set<ProductNode*> visited ;
    while(!q.empty()) { 
        Node* node = q.front() ;
        q.pop() ;
        // stop at product node of size 2 and 3  
        ProductNode* pnode = dynamic_cast<ProductNode*>(node) ; 
        if(pnode && visited.find(pnode) == visited.end())  { 

            if(pnode->GetToepNode() != nullptr && pnode->GetVecNode() != nullptr) { 
                // check if we reached size 2 
                Toep2d* toep = static_cast<Toep2d*>(pnode->GetToepNode()->GetValue());  
                visited.insert(pnode) ;
                if (toep->Size() %2 == 0) {
                    if (toep->Size() > BASE_MMUL_2x_SIZE) { 
                        // split node 
                        SplitTwoWay(pnode) ;
                    } else { 
                        OpNode* op = new OpNode(Opcode_t::MMUL_2x) ;
                        Vec1d* vec = static_cast<Vec1d*>(pnode->GetVecNode()->GetValue()) ;
                        BufferRef ref = BufferRef(vec->GetRef().GetBuffer(), vec->GetRef().GetAddr(), vec->GetRef().GetSize()) ;
                        op->SetOperands(pnode->GetToepNode(), pnode->GetVecNode(), ref) ;
                        continue ; 
                    } 
                } else if (toep->Size() %3 == 0) { 
                    if (toep->Size() > BASE_MMUL_3x_SIZE) { 
                        // split node 
                        std::cout << "splitting 3 way" << std::endl ;
                        SplitThreeWay(pnode) ; 
                    } else { 
                        OpNode* op = new OpNode(Opcode_t::MMUL_3x) ;
                        Vec1d* vec = static_cast<Vec1d*>(pnode->GetVecNode()->GetValue()) ;
                        BufferRef ref = BufferRef(vec->GetRef().GetBuffer(), vec->GetRef().GetAddr(), vec->GetRef().GetSize()) ;
                        op->SetOperands(pnode->GetToepNode(), pnode->GetVecNode(), ref) ;
                        continue ; 
                    } 
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
    // T0 + t1 replaces t0 , t1 + t2 replaces t2 ,
    // toeplitz decomposition
    // t1+t0 used for P0,t1+t2 used for P1,t1 used for P2
    Toep2d* toep = static_cast<Toep2d*>(node->GetToepNode()->GetValue()) ;
    Toep2d* t0 = toep->operator()(0,toep->Size()/2, toep->Size()/2) ; // error here 
    Toep2d* t2 = toep->operator()(toep->Size()/2,0, toep->Size()/2) ;
    Toep2d* t1 = toep->operator()(0,0, toep->Size()/2) ;

    //std::cout << "t0 col addr: " << t0->GetColRef().GetAddr() ; 
    //std::cout << " t0 row addr: " << t0->GetRowRef().GetAddr() ; 
    //std::cout << " t0 col size: " << t0->GetColRef().GetSize() ; 
    //std::cout << " t0 row size: " << t0->GetRowRef().GetSize() << std::endl ; 

    //std::cout << "t1 col addr: " << t1->GetColRef().GetAddr() ; 
    //std::cout << " t1 row addr: " << t1->GetRowRef().GetAddr() ; 
    //std::cout << " t1 col size: " << t1->GetColRef().GetSize() ; 
    //std::cout << " t1 row size: " << t1->GetRowRef().GetSize() << std::endl ; 

    //std::cout << "t2 col addr: " << t2->GetColRef().GetAddr() ; 
    //std::cout << " t2 row addr: " << t2->GetRowRef().GetAddr() ; 
    //std::cout << " t2 col size: " << t2->GetColRef().GetSize() ; 
    //std::cout << " t2 row size: " << t2->GetRowRef().GetSize() << std::endl ; 


    // create data nodes for toeps 
    DataNode* dn_t0 = new DataNode(t0) ; 
    DataNode* dn_t2 = new DataNode(t2) ; 
    DataNode* p2_t  = new DataNode(t1) ; 
    dn_t0->AddInput(node->GetToepNode()) ;
    dn_t2->AddInput(node->GetToepNode()) ;
    p2_t->AddInput(node->GetToepNode()) ;
    // add users to node 
    node->GetToepNode()->AddUser(dn_t0) ;
    node->GetToepNode()->AddUser(dn_t2) ;
    node->GetToepNode()->AddUser(p2_t) ; 
    // create op nodes for t1+t0 and t1+t2 
    OpNode* p0_t = new OpNode(Opcode_t::ADD) ; 
    OpNode* p1_t = new OpNode(Opcode_t::ADD) ;  
    //BufferRef t2_ov_ref = t2 // + m_size-1; 
    //BufferRef t0_ov_ref; 
    //BufferRef p0_t_ov_ref = BufferRef(t0->GetColRef().GetBuffer(), t0->GetColRef().GetAddr()+t0->GetColRef().GetSize(), t0->GetColRef().GetSize()*2+1 ) ;// size doesn't matter only start index 
    //BufferRef p1_t_ov_ref = BufferRef(t2->GetColRef().GetBuffer(), (int)t2->GetColRef().GetAddr()-(int)t2->GetColRef().GetSize(), t2->GetColRef().GetSize()*2+1 ) ;// size doesn't matter only start index

    p0_t->SetOperands(dn_t0 , p2_t );// , p0_t_ov_ref ) ; 
    //p0_t->AddAttribute("rtol", ""); // right to left exec
    p1_t->SetOperands(p2_t  , dn_t2 );//, p1_t_ov_ref ) ;

    // Vector decomposition
    // v0 used for P0,v1 used for P1,v0-v1 used for P2
    Vec1d* vec= static_cast<Vec1d*>(node->GetVecNode()->GetValue()) ;
    Vec1d* v0 = vec->operator()(0, vec->Size()/2) ;
    Vec1d* v1 = vec->operator()(vec->Size()/2, vec->Size()/2) ;
    // Create data nodes for vecs  
    DataNode* p0_v = new DataNode(v1) ;
    DataNode* p1_v = new DataNode(v0) ; 
    // add inputs to vec
    p0_v->AddInput(node->GetVecNode()) ;
    p1_v->AddInput(node->GetVecNode()) ;
    // add users to nodes
    node->GetVecNode()->AddUser(p0_v) ;
    node->GetVecNode()->AddUser(p1_v) ;
    // create op nodes for v0-v1
    OpNode* p2_v = new OpNode(Opcode_t::SUB) ;
    p2_v->SetOperands(p1_v, p0_v) ;
    // Recomposition
    ProductNode* p0 = new ProductNode(p0_t ,p0_v)   ;
    ProductNode* p1 = new ProductNode(p1_t ,p1_v)   ; 
    ProductNode* p2 = new ProductNode(p2_t ,p2_v)  ; 
    // Reduce p0 , p1 ,p2 to get original node 
    OpNode* reduce0 = new OpNode(Opcode_t::ADD) ;
    OpNode* reduce1 = new OpNode(Opcode_t::SUB) ;
    BufferRef ref_0 = BufferRef(vec->GetRef().GetBuffer(), vec->GetRef().GetAddr(), vec->GetRef().GetSize()/2) ;
    BufferRef ref_1 = BufferRef(vec->GetRef().GetBuffer(), vec->GetRef().GetAddr()+vec->GetRef().GetSize()/2, vec->GetRef().GetSize()/2) ;
    reduce0->SetOperands(p0, p2);//, ref_0) ; // problem here
    reduce1->SetOperands(p1, p2);//, ref_1) ; 
    node->AddInput(reduce0) ;
    node->AddInput(reduce1) ;
    reduce0->AddUser(node) ;
    reduce1->AddUser(node) ;  
    node->GetResultFromInputs(); 
}
void DecompositionGraphBuilder::SplitThreeWay(ProductNode* node) { 
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
    std::string type = node->GetAttribute("value_type") ;
    // t1+t0 used for P0,t1+t2 used for P1,t1 used for P2
    Toep2d* toep = static_cast<Toep2d*>(node->GetToepNode()->GetValue()) ; 
    // Print information about toep 
    std::cout << "toep col addr: " << toep->GetColRef().GetAddr() << " size: " << toep->GetColRef().GetSize() << std::endl ; // problem with initialization 
    std::cout << "toep row addr: " << toep->GetRowRef().GetAddr() << " size: " << toep->GetRowRef().GetSize() << std::endl ;

    Toep2d* t0 = toep->operator()(0,2*toep->Size()/3, toep->Size()/3) ;
    Toep2d* t1 = toep->operator()(0,toep->Size()/3, toep->Size()/3) ;
    Toep2d* t2 = toep->operator()(0,0, toep->Size()/3) ;
    Toep2d* t3 = toep->operator()(toep->Size()/3,0, toep->Size()/3) ; 
    Toep2d* t4 = toep->operator()(2*toep->Size()/3,0, toep->Size()/3) ;
    // create data nodes for toeps
    DataNode* dn_t0 = new DataNode(t0) ; 
    DataNode* p3_t = new DataNode(t1) ; 
    DataNode* p4_t = new DataNode(t2) ; 
    DataNode* p5_t = new DataNode(t3) ; 
    DataNode* dn_t4 = new DataNode(t4) ; 
    // Print info about data nodes 
    std::cout << "t0 col addr: " << t0->GetColRef().GetAddr() << " size: " << t0->GetColRef().GetSize() << " row addr: " << t0->GetRowRef().GetAddr() << " size: " << t0->GetRowRef().GetSize() << std::endl ; 
    std::cout << "t1 col addr: " << t1->GetColRef().GetAddr() << " size: " << t1->GetColRef().GetSize() << " row addr: " << t1->GetRowRef().GetAddr() << " size: " << t1->GetRowRef().GetSize() << std::endl ;
    std::cout << "t2 col addr: " << t2->GetColRef().GetAddr() << " size: " << t2->GetColRef().GetSize() << " row addr: " << t2->GetRowRef().GetAddr() << " size: " << t2->GetRowRef().GetSize() << std::endl ;
    std::cout << "t3 col addr: " << t3->GetColRef().GetAddr() << " size: " << t3->GetColRef().GetSize() << " row addr: " << t3->GetRowRef().GetAddr() << " size: " << t3->GetRowRef().GetSize() << std::endl ;
    std::cout << "t4 col addr: " << t4->GetColRef().GetAddr() << " size: " << t4->GetColRef().GetSize() << " row addr: " << t4->GetRowRef().GetAddr() << " size: " << t4->GetRowRef().GetSize() << std::endl ;



    // create op nodes 
    OpNode* p0_t_0 = new OpNode(Opcode_t::SUB) ;// t0-t1 
    OpNode* p0_t_1 = new OpNode(Opcode_t::SUB) ;// t0-t1-t2
    OpNode* p1_t_0 = new OpNode(Opcode_t::SUB) ;// t2-t1
    OpNode* p1_t_1 = new OpNode(Opcode_t::SUB) ;// t2-t1-t3
    OpNode* p2_t_0 = new OpNode(Opcode_t::SUB) ;// t4-t3
    OpNode* p2_t_1 = new OpNode(Opcode_t::SUB) ;// t4-t3-t2
                                                // add inputs to toep (setting operands) 
    p0_t_0->SetOperands(dn_t0, p3_t) ; // (edit this) 
    p0_t_1->SetOperands(p0_t_0, p4_t) ;
    p1_t_0->SetOperands(p4_t, p3_t) ;
    p1_t_1->SetOperands(p1_t_0,p5_t) ;
    p2_t_0->SetOperands(dn_t4, p5_t) ;
    p2_t_1->SetOperands(p2_t_0, p4_t) ;
    // add node to datanodes as input 
    dn_t0->AddInput(node->GetToepNode()) ;
    p3_t->AddInput(node->GetToepNode()) ;
    p4_t->AddInput(node->GetToepNode()) ;
    p5_t->AddInput(node->GetToepNode()) ;
    dn_t4->AddInput(node->GetToepNode()) ;
    // add users to node  
    node->GetToepNode()->AddUser(dn_t0) ;
    node->GetToepNode()->AddUser(p3_t) ;
    node->GetToepNode()->AddUser(p4_t) ;
    node->GetToepNode()->AddUser(p5_t) ;
    node->GetToepNode()->AddUser(dn_t4) ;

    // v0 used for P0,v1 used for P1,v0-v1 used for P2
    Vec1d* vec= static_cast<Vec1d*>(node->GetVecNode()->GetValue()) ;
    Vec1d* v0 = vec->operator()(0, vec->Size()/3) ;
    Vec1d* v1 = vec->operator()(vec->Size()/3, vec->Size()/3) ;
    Vec1d* v2 = vec->operator()(2*vec->Size()/3, vec->Size()/3) ;
    // Create data nodes for vecs  
    DataNode* p2_v = new DataNode(v0) ;
    DataNode* p1_v = new DataNode(v1) ;
    DataNode* p0_v = new DataNode(v2) ;
    // creat op nodes 
    OpNode* p3_v = new OpNode(Opcode_t::ADD) ;
    OpNode* p4_v = new OpNode(Opcode_t::ADD) ;
    OpNode* p5_v = new OpNode(Opcode_t::ADD) ;
    // Set operands of op nodes 
    p3_v->SetOperands(p1_v, p0_v) ;
    p4_v->SetOperands(p2_v, p0_v) ;
    p5_v->SetOperands(p2_v, p1_v) ;
    // add node as input to datanodes  
    p2_v->AddInput(node->GetVecNode()) ;
    p1_v->AddInput(node->GetVecNode()) ;
    p0_v->AddInput(node->GetVecNode()) ;
    // add users to nodes
    node->GetVecNode()->AddUser(p2_v) ;
    node->GetVecNode()->AddUser(p1_v) ;
    node->GetVecNode()->AddUser(p0_v) ; 
    // Create intermediate vecs 
    //p0 + p3 + p4 
    //p1 + p3 + p5
    //p2 + p4 + p5 
    ProductNode* p0 = new ProductNode(p0_t_1 ,p0_v)   ;
    ProductNode* p1 = new ProductNode(p1_t_1 ,p1_v)   ; 
    ProductNode* p2 = new ProductNode(p2_t_1 ,p2_v)  ; 
    ProductNode* p3 = new ProductNode(p3_t   ,p3_v)  ; 
    ProductNode* p4 = new ProductNode(p4_t   ,p4_v)  ; 
    ProductNode* p5 = new ProductNode(p5_t   ,p5_v)  ;  
    // create op nodes responsible for reducing P vectors back into original ve node->
    OpNode* p0_p3 = new OpNode(Opcode_t::ADD) ;
    OpNode* p0_p3_p4 = new OpNode(Opcode_t::ADD) ;
    OpNode* p1_p3 = new OpNode(Opcode_t::ADD) ;
    OpNode* p1_p3_p5 = new OpNode(Opcode_t::ADD) ;
    OpNode* p2_p4 = new OpNode(Opcode_t::ADD) ;
    OpNode* p2_p4_p5 = new OpNode(Opcode_t::ADD) ;
    // set operands of op nodes
    // ! TODO: determine what data to overwrite later
    p0_p3->SetOperands(p0, p3) ;
    p0_p3_p4->SetOperands(p0_p3, p4) ;
    p1_p3->SetOperands(p1, p3) ;
    p1_p3_p5->SetOperands(p1_p3, p5) ;
    p2_p4->SetOperands(p2, p4) ;
    p2_p4_p5->SetOperands(p2_p4, p5) ;
    // add the opnodes as inputs to node 
    node->AddInput(p0_p3_p4) ;
    node->AddInput(p1_p3_p5) ;
    node->AddInput(p2_p4_p5) ;
    // add users to op nodes
    p0_p3_p4->AddUser(node) ;
    p1_p3_p5->AddUser(node) ;
    p2_p4_p5->AddUser(node) ;

}
