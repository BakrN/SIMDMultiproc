#pragma once 
#include <cstdint>
#include "Buffer.h"
class Vec1d { 
    public: 
        Vec1d(Buffer& buffer, uint32_t size) : m_data(buffer, size) {
            m_size = size ; 
        }
        Vec1d(const BufferRef& ref) : m_data(ref) {  
            m_size = ref.GetSize() ;
        }
        //  returns new vector with addr and size
        Vec1d* operator()(uint32_t index, uint32_t size) { 
            assert(m_data.GetAddr()+index+ size <= m_data.GetAddr() + m_size) ;
            Vec1d* vec = new Vec1d(BufferRef(m_data.GetBuffer(), m_data.GetAddr()+index, size) ); 
            return vec ;
        }
        BufferRef& GetRef() { 
            return m_data ; 
        } 
        uint32_t Size() { 
            return m_size ; 
        }
    private: 
        uint32_t m_size;  
        BufferRef m_data ;
} ; 




