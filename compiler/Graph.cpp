#include "Graph.h"
#include <type_traits>


ForwardLevelIterator::ForwardLevelIterator(Node* node) : GraphIterator(node) {
    // Initialize the stack with the given node
    m_ptr.push(node);
}

Node& ForwardLevelIterator::operator*() {
    // Return a reference to the top element of the stack
    return *m_ptr.top();
}

Node* ForwardLevelIterator::operator->() {
    // Return a pointer to the top element of the stack
    return m_ptr.top();
}

ForwardLevelIterator& ForwardLevelIterator::operator++() {
    // Pop the top element of the stack
    Node* current = m_ptr.top();
    m_ptr.pop();

    // Push the children of the current node onto the stack
    for (Node* child : current->Users()) {
        m_ptr.push(child);
    }
    // Return a reference to this iterator
    return *this;
}

ForwardLevelIterator& ForwardLevelIterator::operator--() {
    // Pop the top element of the stack
    m_ptr.pop();

    // Return a reference to this iterator
    return *this;
}

bool ForwardLevelIterator::operator==(const GraphIterator& other) {

    // Compare the stacks of the two iterators by comparing the sizes, the current top reference 
    if(auto other_cast = dynamic_cast<const ForwardLevelIterator*>(&other)) {
        return m_ptr.size() == other_cast->m_ptr.size() && m_ptr.top() == other_cast->m_ptr.top() && m_ptr.top()->Ptr() == other_cast->m_ptr.top()->Ptr();
    }
    return false ;
}

bool ForwardLevelIterator::operator!=(const GraphIterator& other) {
    // Compare the stacks of the two iterators 
    if(auto other_cast = dynamic_cast<const ForwardLevelIterator*>(&other)) {
        return m_ptr.size() != other_cast->m_ptr.size() || m_ptr.top() != other_cast->m_ptr.top() || m_ptr.top()->Ptr() != other_cast->m_ptr.top()->Ptr();
    }
    return false ;
}

