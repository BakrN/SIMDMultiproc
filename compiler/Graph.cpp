#include "Graph.h"
#include <type_traits>
#include <iostream> 
#include <unordered_set> 
#include <functional>
Node::~Node() { 
}

std::vector<Node*>& Node::Users() {
    return m_users;
}
std::vector<Node*>& Node::Inputs() {
    return m_inputs;
}
void Node::AddAttribute(const std::string& key, const std::string& value){
    m_attributes[key] = value;

} 
bool Node::HasAttribute(const std::string& key) { 
    return m_attributes.find(key) != m_attributes.end() ; 
}
std::string Node::GetAttribute(const std::string& key) {;
    return m_attributes[key] ; 
}
void Node::AddInput(Node* node){
    m_inputs.push_back(node); 
} 
void Node::AddUser(Node* node){
    m_users.push_back(node);
} 


ReverseLevelIterator::ReverseLevelIterator(Node* node, const std::string& type, bool auto_traverse) : m_type(type) {

    std::queue<Node*> q;
    q.push(node);
    while (!q.empty()) {
        Node* n = q.front();
        q.pop();
        if ( type.empty() || n->GetAttribute("node_type") == type) { // Only add nodes of specified type

            m_ptr.push(n);
            if (!auto_traverse) 
                break ; 
        }
        for (auto& user : n->Users()) {
            q.push(user);
        }
    }
}

Node& ReverseLevelIterator::operator*() {
    return *m_ptr.top();
}

Node* ReverseLevelIterator::operator->() {
    return m_ptr.top();
}

ReverseLevelIterator& ReverseLevelIterator::operator++() {
    m_ptr.pop();
    return *this;
}

ReverseLevelIterator& ReverseLevelIterator::operator--() {
    Node* n = m_ptr.top();
    std::vector<Node*>& inputs = n->Inputs();
    if (!inputs.empty()) {
        std::sort(inputs.begin(), inputs.end(), [](Node* a, Node* b) {
                return a->Users().size() < b->Users().size();
                });
        for (auto& input : inputs) {
            if (input->GetAttribute("type") == m_type) { // Only add nodes of specified type
                m_ptr.push(input);
            }
        }
    }
    return *this;
}

bool ReverseLevelIterator::operator==(const GraphIterator& other) {

    // Compare the stacks of the two iterators by comparing the sizes, the current top reference 
    if(auto other_cast = dynamic_cast<const ReverseLevelIterator*>(&other)) {
        return m_ptr.size() == other_cast->m_ptr.size() && m_ptr.top() == other_cast->m_ptr.top() && m_ptr.top() == other_cast->m_ptr.top();
    }
    return false ;
}

bool ReverseLevelIterator::operator!=(const GraphIterator& other) {
    if(auto other_cast = dynamic_cast<const ReverseLevelIterator*>(&other)) {
        return m_ptr.size() != other_cast->m_ptr.size() || m_ptr.top() != other_cast->m_ptr.top() || m_ptr.top() != other_cast->m_ptr.top();
    }
    return false ;
}


ForwardLevelIterator::ForwardLevelIterator(Node* node)  {
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
        return m_ptr.size() == other_cast->m_ptr.size() && m_ptr.top() == other_cast->m_ptr.top() && m_ptr.top() == other_cast->m_ptr.top();
    }
    return false ;
}

bool ForwardLevelIterator::operator!=(const GraphIterator& other) {
    // Compare the stacks of the two iterators 
    if(auto other_cast = dynamic_cast<const ForwardLevelIterator*>(&other)) {
        return m_ptr.size() != other_cast->m_ptr.size() || m_ptr.top() != other_cast->m_ptr.top() || m_ptr.top() != other_cast->m_ptr.top();
    }
    return false ;
}

Graph::Graph(Node* root) : m_root(root) {
}
ForwardLevelIterator Graph::begin() {
    return ForwardLevelIterator(m_root);
}
ForwardLevelIterator Graph::end() { // ! TODO : Implement this
    std::stack<Node*> m_ptr;
    Node* current = nullptr;
    m_ptr.push(m_root);
    while(!m_ptr.empty()) {
        current = m_ptr.top();
        m_ptr.pop() ; 
        for (auto& user : current->Users()) {
            m_ptr.push(user);
        }
    }
    return ForwardLevelIterator(current);
}
ReverseLevelIterator Graph::rbegin() { // ! TODO : Incorporate type filtering 
    return ReverseLevelIterator(m_root, ""); // 
}
ReverseLevelIterator Graph::rend() { // ! TODO : Implement this
    return ReverseLevelIterator(nullptr, "");
}

Node* Graph::GetRoot() {
    return m_root;
}

void Graph::PrintGraph() {
    std::unordered_map<Node*, int> level;
    std::queue<Node*> q;

    level[m_root] = 0;
    q.push(m_root);

    while (!q.empty()) {
        Node* node = q.front();
        q.pop();

        std::cout << "Level " << level[node] << ": ";
        std::cout << "Node " << node << std::endl;

        for (Node* user : node->Users()) {
            if (level.find(user) == level.end()) {
                level[user] = level[node] + 1;
                q.push(user);
            }
        }
    }
}

