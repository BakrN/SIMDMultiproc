#pragma once

// inforation about toeplitz we need. is size and ptr of some sort to data (could be index or whatever) ? 
// Way to index 
// maybe contains two vec1ds  
#include "Buffer.h" 
#include "Vec.h"
#include <memory> 
#include <utility> 

class Toep2d {
    public: 
        Toep2d(Buffer& buf, int size) { 
            m_size = size ; 
            // should be place contiguously in memory
            m_col  = std::make_unique<Vec1d>(buf, size-1) ; 
            m_row  = std::make_unique<Vec1d>(buf, size) ;  
        }  
        Toep2d() : m_col(nullptr), m_row(nullptr) , m_size(0) {}; 
        Toep2d(BufferRef& ref) {
            m_size =  (ref.GetSize()+1)/2 ;   
            m_col = std::make_unique<Vec1d>(BufferRef(ref.GetBuffer(), ref.GetAddr(), m_size-1)) ; 
            m_row = std::make_unique<Vec1d>(BufferRef(ref.GetBuffer(), ref.GetAddr()+m_size, m_size)) ; 
        } 
        ~Toep2d() { 
            m_col.reset() ; 
            m_row.reset() ;
        }
        Toep2d* operator()(int row, int col , int size ){ 
            assert (row+size <= m_size) ;
            assert (col+size <= m_size) ;
            Toep2d* toep = new Toep2d() ;  
            // top left sub matrix, no need to allocate new mem to buffer 
            // Let's assume x and y are 0  
            int col_size =  ((m_size - (row+size)) +size >= m_size) ? row+size-1: size; 
            Vec1d* vcol = m_col->operator()(m_size-(row+size) , size) ;  // No lower bound check
            Vec1d* vrow = m_row->operator()(col+size , size) ; // Here I'm just assuming it works 
            toep->SetCol(vcol) ;
            toep->SetRow(vrow) ;
            return toep ;  
        } 
        int Size() {return m_size;} 
        void SetCol(Vec1d* col) { 
            m_col = std::make_unique<Vec1d>(*col) ; 
        }
        void SetRow(Vec1d* row) { 
            m_row = std::make_unique<Vec1d>(*row) ; 
        } 
        BufferRef& GetColRef() { 
            return m_col->GetRef() ; 
        }
        BufferRef& GetRowRef() { 
            return m_row->GetRef() ; 
        }
    private: 
        int m_size ; 
        std::unique_ptr<Vec1d> m_col ,m_row; 
} ; 

