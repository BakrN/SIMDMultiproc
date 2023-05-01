#pragma once

// inforation about toeplitz we need. is size and ptr of some sort to data (could be index or whatever) ? 
// Way to index 
// maybe contains two vec1ds  
#include "Buffer.h" 
#include "Vec.h"
#include <memory> 
#include <utility> 
#include <iostream> 
class Toep2d {
    public: 
        Toep2d(Buffer* buf, int size) { 
            m_size = size ; 
            // should be place contiguously in memory
            m_col  = std::make_unique<Vec1d>(buf, size-1) ;  
            m_row  = std::make_unique<Vec1d>(buf, size) ;   
            
        }  
        Toep2d() : m_col(nullptr), m_row(nullptr) , m_size(0) {}; 
        Toep2d(BufferRef& ref, int mat_size) {
            m_size= mat_size ;    
            m_col = std::make_unique<Vec1d>(BufferRef(ref.GetBuffer(), ref.GetAddr(), m_size-1)) ; 
            m_row = std::make_unique<Vec1d>(BufferRef(ref.GetBuffer(), ref.GetAddr()+m_size, m_size)) ; 
            // col and row have to be in contigous memory
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
            //std::cout << "current row addr: " << m_row->GetRef().GetAddr() << std::endl ;
            //std::cout << "current col addr: " << m_col->GetRef().GetAddr() << std::endl ;
            int col_size =  ((m_size - (row+size)) +size >= m_size) ? row+size-1: size; 
            //std::cout << "COL SIZE: " << col_size << std::endl ;
            Vec1d* vcol, *vrow; 
            if (row>col ) { 
                // all values in coL  ?  
                int row_index = m_size - (row-col) -1  ; 
                int col_index = row_index+1 - (size) ;  
                // what is row 
                vrow = m_col->operator()(row_index, size) ; 
                vcol = m_col->operator()(col_index, size-1) ;  
            } 
            else { 

                vrow = m_row->operator()(col-row, size) ;  
                vcol = m_row->operator()((col-row)-(size-1), size-1) ;  
            } 
            
            toep->SetCol(vcol) ;
            toep->SetRow(vrow) ; 
            toep->m_size = size ;
            return toep ;  
        } 
        int Size() {return m_size;} 
        void SetCol(Vec1d* col) { 
            m_col.reset(col) ; 
        }
        void SetRow(Vec1d* row) { 
            m_row.reset(row) ; 
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

