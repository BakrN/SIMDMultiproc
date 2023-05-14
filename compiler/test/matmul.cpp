#include "Solver.h"    
#include "Algo.h"  
#include "Command.h"
#include <cstring> 
void naive_matmul(unit_t* matrix, unit_t* vec, unit_t* result, int size) {  // row major order
    for (int row = 0 ; row < size; row++) { 
        result[row] = 0 ;
        for (int col = 0 ; col < size ; col++) { 
            result [row] += matrix[row*size + col] * vec[col] ;
        } 
    }  
}
unit_t* create_toep(int size) { 
    unit_t* matrix = new unit_t[2*size-1] ; 
    for (int i = 0 ; i < 2*size-1 ; i++) { 
        matrix[i] = rand() % 100 ;  
    }
    return matrix ; 
}
unit_t* create_vec(int size) { 
    unit_t* vec = new unit_t[size] ; 
    for (int i = 0 ; i < size ; i++) { 
        vec[i] = rand() % 100  * (rand()%2 -1); 
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

void print_vec(unit_t* vec , int size) { 
    for (int i = 0 ; i < size ; i++) { 
        std::cout << vec[i] << " " ; 
    }
    std::cout << std::endl ; 
}
void print_toep(unit_t* toep, int size) { 
    for ( int row = 0 ; row < size ; row++) { 
        for (int col = 0 ; col < size ; col++) { 
            std::cout << toep[(size)-1 - row + col] << " " ; 
        }
        std::cout << std::endl ; 
    }
    std::cout << std::endl ; 
}
// write a function to compare to arrays with size size 
bool compare_vec(unit_t* vec1, unit_t* vec2, int size) { 
    for (int i = 0 ; i < size ; i++) { 
        if (vec1[i] != vec2[i]) { 
            // display where the 
            std::cout << "Error at index: " << i << std::endl ;
            std::cout << "vec1: " << vec1[i] << " vec2: " << vec2[i] << std::endl ;
            return false ; 
        }
    }
    std::cout << "Test passed" << std::endl ;
    return true ; 
}

#define MEM_LENGTH 131072

int main(int argc, char** argv) {   
    // take size as input in argv 
    if (argc != 2) { 
        std::cout << "Usage: ./matmul <size>" << std::endl ; 
        return 0 ; 
    }
    int size = atoi(argv[1]) ;
    // works for 2x2 case 
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
    Buffer toep_buf(10000);  
    Buffer vec_buf (10000);  
    Toep2d* toep_struct = new Toep2d(&toep_buf, size );
    Vec1d*  vec_struct = new Vec1d(&vec_buf,    size) ;  
    DataNode* toep_node = new DataNode(toep_struct);
    DataNode* vec_node = new DataNode(vec_struct);
    ProductNode* node = new ProductNode(toep_node , vec_node );  
    DecompositionGraphBuilder builder( node);  
    Graph* graph = builder.BuildGraph() ;  
    DecomposerCommandGenerator command_generator(graph->GetRoot()); 
    //toep_graph->PrintGraph() ;
    command_generator.Generate() ; 
    unit_t* decomp_out = new unit_t[toep_buf.GetFree() -toep_buf.GetStart() + vec_buf.GetFree() - vec_buf.GetStart()] ;     
    memcpy(decomp_out-toep_buf.GetStart(), toep, ((2*size)-1)*sizeof(unit_t)) ; // memory calls to dma
    memcpy(decomp_out+toep_buf.GetFree()-toep_buf.GetStart(), vec, size*sizeof(unit_t)) ; 
    Serializer::SerializeMem(decomp_out, toep_buf.GetFree() -toep_buf.GetStart() + vec_buf.GetFree() - vec_buf.GetStart(), "../../hardware/sim/init_mem.txt") ;
    print_toep(decomp_out-toep_buf.GetStart() ,size) ; 
    print_vec(decomp_out +toep_buf.GetFree()-toep_buf.GetStart(), size) ;   

    std::cout << "Printing toep commands" << std::endl;
    for (auto& cmd : command_generator.GetToepCommands()) { 
        std::cout << cmd << std::endl ; 
    }
    std::cout << "Printing vec commands" << std::endl;
    for (auto& cmd : command_generator.GetVecCommands()) { 
        std::cout << cmd << std::endl ; 
    }
    std::cout << "Printing recomp commands with size: " << command_generator.GetRecompCommands().size()<< std::endl;
    for (auto& cmd : command_generator.GetRecompCommands()) { 
        std::cout << cmd << std::endl ; 
    }
    Solver::ExecuteCmds(decomp_out , command_generator.GetToepCommands()  ) ;
    Solver::ExecuteCmds(decomp_out , command_generator.GetVecCommands()   ) ;
    Solver::ExecuteCmds(decomp_out , command_generator.GetRecompCommands()) ;
    int index = static_cast<Vec1d*>(node->GetValue())->GetRef().GetAddr() + toep_buf.GetFree() - toep_buf.GetStart() ; 
    //
    print_vec(decomp_out+index, size);
    compare_vec(result, decomp_out+index, size); 
    //std::cout << " Final Buffer Size: "  << toep_buf.GetFree() -toep_buf.GetStart() + vec_buf.GetFree() - vec_buf.GetStart() << std::endl ;
    //
    Serializer::SerializeCommand(command_generator.GetToepCommands() ,"../../hardware/sim/cmd_queue.txt") ; 
    Serializer::SerializeCommand(command_generator.GetVecCommands() ,"../../hardware/sim/cmd_queue.txt", true) ;
    Serializer::SerializeCommand(command_generator.GetRecompCommands() ,"../../hardware/sim/cmd_queue.txt", true) ;
    std::cout << "finished writing: " << command_generator.GetRecompCommands().size()+ command_generator.GetToepCommands().size()+command_generator.GetVecCommands().size()<< " commands" << std::endl ;
    std::cout << "Recomp commands: " << command_generator.GetRecompCommands().size() << std::endl ;
    Serializer::SerializeMem(decomp_out, toep_buf.GetFree() -toep_buf.GetStart() + vec_buf.GetFree() - vec_buf.GetStart(), "../../hardware/sim/valid_mem.txt") ;
    std::cout << "Finished writing mem with size: " << toep_buf.GetFree() -toep_buf.GetStart() + vec_buf.GetFree() - vec_buf.GetStart() << std::endl ;
    //std::cout << " Finished writing mem: 
    std::cout << " Final Buffer Size: "  << toep_buf.GetFree() -toep_buf.GetStart() + vec_buf.GetFree() - vec_buf.GetStart() << std::endl ; 
    // Write to the config file 
    std::ofstream config_file ;
    config_file.open("../../hardware/sim/config.txt") ;
    config_file << "CMD_SIZE=" << command_generator.GetRecompCommands().size()+ command_generator.GetToepCommands().size()+command_generator.GetVecCommands().size() << std::endl ;
    //config_file << "MEM_SIZE=" << toep_buf.GetFree() -toep_buf.GetStart() + vec_buf.GetFree() - vec_buf.GetStart() << std::endl ;
    //config_file << "MEM_MIN=" << toep_buf.GetFree() -toep_buf.GetStart() + vec_buf.GetFree() - vec_buf.GetStart() << std::endl ;
    config_file << "RECOMP_CMD_SIZE=" << command_generator.GetRecompCommands().size() << std::endl ;
    config_file << "TOEP_CMD_SIZE=" << command_generator.GetToepCommands().size() << std::endl ;
    return 0 ; 
} 
