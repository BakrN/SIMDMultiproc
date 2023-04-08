#pragma once
#include <memory> 
#include <cstdint>
#include <assert.h>
class Buffer{ 
    public: 
        Buffer(int size) ; 
        ~Buffer() ; 
        void Expand() ;  // expand buffer size 
        int  GetFree() ; // Get Next free addr  
        void Reserve(int index, int size) ;  // reserve memory block 
    private: 
        int m_size ;    // element count 
        int m_nxt_free; // next free address 
}; 
// buffer ref , read and write 
// you can 

class BufferRef { 
    public : 
        // cpy constructor
        BufferRef(const BufferRef& other)  ;
        // assignment operator
        BufferRef& operator=(const BufferRef& other); 
        BufferRef(Buffer& buf, uint32_t size); 
        BufferRef(Buffer& buf, uint32_t addr , uint32_t size); 
        void Reserve() ;
        void AttachBuffer(Buffer* buf) ; 
        bool Attached() ; 
        uint32_t GetAddr() const ;
        uint32_t GetSize() const  ; 
        Buffer& GetBuffer() ;
    private: 
        std::shared_ptr<Buffer> m_buf ;
        uint32_t m_addr ; 
        uint32_t m_size ; 
        bool m_reserved ; 
} ;
