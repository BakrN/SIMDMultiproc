#include "Solver.h"    
#include "Algo.h"  
#include "Command.h"

void naive_matmul(unit_t* matrix, unit_t* vec, unit_t* result, int size) {  // row major order
    for (int row = 0 ; row < size; row++) { 
        result[row] = 0 ;
        for (int col = 0 ; col < size ; col++) { 
            result [row] += matrix[row*size + col] * vec[col] ;
        } 
    }  
}
unit_t* create_toep(int size) { 
    unit_t* matrix = new unit_t[size-1] ; 
    for (int i = 0 ; i < size-1 ; i++) { 
        matrix[i] = rand() % 100 ;  
    }
    return matrix ; 
}
unit_t* create_vec(int size) { 
    unit_t* vec = new unit_t[size] ; 
    for (int i = 0 ; i < size ; i++) { 
        vec[i] = rand() % 100 ; 
    }
    return vec ; 
}
unit_t* get_mat(unit_t* toep, int size) {// get the matrix from the toep
    unit_t* mat = new unit_t[size*size] ; 
    for (int row = 0 ; row< size ; row++) { 
        for (int col = 0 ; col< size ; col++) { 
                mat[row*size+col]= toep[(size)-1 - row + col]; 
        }
    }
    return mat ; 
}

int main() {   
    int size = 32;
    unit_t* toep = create_toep(size) ;
    unit_t* vec = create_vec(size) ;
    unit_t* result = new unit_t[size] ;
    unit_t* mat = get_mat(toep, size) ;
    naive_matmul(mat, vec, result, size) ;
    std::cout << "matvec: " << std::endl ;
    for (int i = 0 ; i < size ; i++) { 
        std::cout << "[" ;
        for (int j = 0 ; j < size ; j++) { 
            std::cout << mat[i*size + j] << " " ; 
        }
        std::cout << "]"  ;
        std::cout << "  [" << vec[i] << "]" ;
        std::cout << std::endl ; 
    }
    std::cout << "Naive Result: " << std::endl ;
    for (int i = 0 ; i < size ; i++) { 
        std::cout << result[i] << std::endl ;  
    } 
    Buffer buf(1000);  
    Toep2d* toep_struct = new Toep2d(&buf, size );
    Vec1d*  vec_struct = new Vec1d(&buf,   size) ;  
    DataNode* toep_node = new DataNode(toep_struct);
    DataNode* vec_node = new DataNode(vec_struct);
    ProductNode* node = new ProductNode(toep_node , vec_node ,  true);  
    std::cout << "Starting decomposition graph builder" << std::endl;
    DecompositionGraphBuilder builder(buf, node);  
    Graph* graph = builder.BuildGraph() ;  
    std::cout << "Finished decomposition graph builder" << std::endl;
    Graph* toep_graph = new Graph(static_cast<ProductNode*>(graph->GetRoot())->GetToepNode());
    Graph* vec_graph  = new Graph(static_cast<ProductNode*>(graph->GetRoot())->GetVecNode());
    DecomposerCommandGenerator toep_command_generator(toep_graph->GetRoot()); 
    toep_graph->PrintGraph() ;
    // testing iterator 

    
    
    
    
    
    
    //for (auto it = toep_graph->begin() ; it != toep_graph->end() ; ++it) { 
    //    if ((*it).GetAttribute("node_type") == "op"){ 
    //        op_node++; 
    //        if(static_cast<OpNode&>(*it).GetOpcode() == Opcode_t::ADD) { 
    //            addcount++ ; 
    //        }
    //        else if(static_cast<OpNode&>(*it).GetOpcode() == Opcode_t::SUB) { 
    //            subcount++ ; 
    //        }
    //        else if (static_cast<OpNode&>(*it).GetOpcode() == Opcode_t::MMUL_2x) { 
    //            matmul2xcount++ ; 
    //        }
    //        else if (static_cast<OpNode&>(*it).GetOpcode() == Opcode_t::MMUL_3x) { 
    //            matmul3xcount++ ; 
    //        }
    //    }  else { 
    //        if ((*it).GetAttribute("node_type") == "data") { 
    //            data_node++ ; 
    //        }
    //    } 
    //}

    /*toep_command_generator.Generate() ; 
    std::cout << "Printing toep commands" << std::endl;
    for (auto& command : toep_command_generator.GetCommands()) { 
        std::cout << command << std::endl ; 
    }*/ 
    return 0 ; 
} 
