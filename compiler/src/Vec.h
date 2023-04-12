#pragma once 
#include <cstdint>
#include "Buffer.h"
class Vec1d { 
    public: 
        Vec1d(const Vec1d& vec) : m_ref(vec.m_ref), m_size(vec.m_size) {}
        Vec1d& operator=(const Vec1d& vec) { 
            m_ref = vec.m_ref ; 
            m_size = vec.m_size ; 
            return *this ; 
        }
        Vec1d(Buffer* buffer, uint32_t size) : m_ref(buffer, size) {
            m_size = size ; 
        }
        Vec1d(const BufferRef& ref) : m_ref(ref) {  
            m_size = ref.GetSize() ;
        }
        //  returns new vector with addr and size
        Vec1d* operator()(uint32_t index, uint32_t size) { 
            assert(m_ref.GetAddr()+index+ size <= m_ref.GetAddr() + m_size) ;
            Vec1d* vec = new Vec1d(BufferRef(m_ref.GetBuffer(), m_ref.GetAddr()+index, size) ); 
            return vec ;
        }
        BufferRef& GetRef() { 
            return m_ref ; 
        } 
        uint32_t Size() { 
            return m_size ; 
        }
    private: 
        uint32_t m_size;  
        BufferRef m_ref ;
} ; 




