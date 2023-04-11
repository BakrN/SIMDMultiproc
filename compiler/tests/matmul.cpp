#include "../Solver.h"  
#include "../Algo.h" 
#include "../Command.h"
void naive_matmul(unit_t* matrix, unit_t* vec, unit_t* result, int size) {  // row major order
    for (int i = 0 ; i < size; i++) { 
        for (int j = 0 ; j < size ; j++) { 
            for (int k = 0 ; k < size ; k++) { 
                result[i*size + j] += matrix[i*size + k] * vec[k*size + j] ;
            }
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
    unit_t* toep = create_toep(4) ;
    unit_t* vec = create_vec(4) ;
    unit_t* result = new unit_t[4] ;
    unit_t* mat = get_mat(toep, 4) ;
    naive_matmul(mat, vec, result, 4) ;
    std::cout << "matvec: " << std::endl ;
    for (int i = 0 ; i < 4 ; i++) { 
        std::cout << "[" ;
        for (int j = 0 ; j < 4 ; j++) { 
            std::cout << mat[i*4 + j] << " " ; 
        }
        std::cout << "]"  ;
        std::cout << "  [" << vec[i] << "]" ;
        std::cout << std::endl ; 
    }
    std::cout << "Naive Result: " << std::endl ;
    for (int i = 0 ; i < 4 ; i++) { 
        std::cout << result[i] << std::endl ; 
    } 
    Buffer buf(100);  
    Toep2d* toep_struct = new Toep2d(&buf, 8 );// 4x4
    Vec1d*  vec_struct = new Vec1d(&buf, 8) ; // 4x1
    DataNode* toep_node = new DataNode(toep_struct);
    DataNode* vec_node = new DataNode(vec_struct);
    ProductNode* node = new ProductNode(toep_node , vec_node ,  true);  
    std::cout << "Starting decomposition graph builder" << std::endl;
    DecompositionGraphBuilder builder(buf, node);  
    Graph* graph = builder.BuildGraph() ;  
    std::cout << "Finished decomposition graph builder" << std::endl;
    Graph* toep_graph = new Graph(static_cast<ProductNode*>(graph->GetRoot())->GetToepNode());
    Graph* vec_graph  = new Graph(static_cast<ProductNode*>(graph->GetRoot())->GetVecNode());

    return 0 ; 
} 
