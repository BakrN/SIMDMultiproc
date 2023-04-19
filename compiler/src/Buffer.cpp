#include "Buffer.h"
#include <iostream>
Buffer::Buffer(int size) { 
    m_size= size ; 
    m_nxt_free = 0 ; 
    m_start = 0 ;
}

Buffer::~Buffer() {
}

void Buffer::Expand() {
    // Expands the size of the buffer by doubling the current size.
    m_size *= 2;
}

int Buffer::GetFree() {
    // Returns the address of the next free element in the buffer, and advances the free pointer to the next element.
    return m_nxt_free;
}
int Buffer::GetStart() const {
    // Returns the address of the first element in the buffer.
    return m_start;
}
void Buffer::Reserve(int index, int size) {
    // Reserves a block of memory in the buffer starting at the given index with the given size.
    m_nxt_free = (m_nxt_free>(index+size))? m_nxt_free  : index + size;
    if (index < m_start) {
        m_start = index;
    }
}
// cpy constructosr
BufferRef::BufferRef(const BufferRef& other) { 
    this->m_buf  = other.m_buf ; 
    this->m_addr = other.m_addr ; 
    this->m_size = other.m_size ; 
    m_buf->Reserve(m_addr, m_size) ;
}
// assignment operator
BufferRef& BufferRef::operator=(const BufferRef& other) { 
    m_buf  = other.m_buf ; 
    m_addr = other.m_addr ; 
    m_size = other.m_size ; 
    m_buf->Reserve(m_addr, m_size) ;
    return *this ; 

}
BufferRef::BufferRef(Buffer* buf, uint32_t size)  {
    m_buf = buf; 
    m_size = size ;
    m_addr = buf->GetFree() ; 
    buf->Reserve(m_addr, m_size) ;

} 
BufferRef::BufferRef(Buffer* buf , int addr , uint32_t size) {
    m_buf = buf; 
    m_size = size ;
    m_addr = addr ; 
    buf->Reserve(m_addr, m_size) ;
} 

void BufferRef::Reserve() { 
        m_addr = m_buf->GetFree() ;  
        m_buf->Reserve(m_addr, m_size) ; 
} 
void BufferRef::AttachBuffer(Buffer* buf) { 
    m_buf = buf ; 
}

bool BufferRef::Attached() { 
    return m_buf != nullptr ; 
}
int BufferRef::GetAddr() const { 
    return m_addr ; 
}
uint32_t BufferRef::GetSize() const {  
    return m_size ; 
}
Buffer* BufferRef::GetBuffer() {  
    return m_buf ; 
}

