#include "Graph.h"
#include "Operator.h"
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
void Node::SetParent(Node* node) { 
    m_parent = node; 
}
Node* Node::GetParent() { 
    return m_parent; 
}
ReverseLevelIterator::~ReverseLevelIterator() {
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
    return *m_ptr.front();
}

Node* ReverseLevelIterator::operator->() {
    return m_ptr.front();
}

ReverseLevelIterator& ReverseLevelIterator::operator++() {
    m_ptr.pop();
    return *this;
}

ReverseLevelIterator& ReverseLevelIterator::operator--() {
    Node* n = m_ptr.front();
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
        return m_ptr.size() == other_cast->m_ptr.size() && m_ptr.front() == other_cast->m_ptr.front() && m_ptr.front() == other_cast->m_ptr.front();
    }
    return false ;
}

bool ReverseLevelIterator::operator!=(const GraphIterator& other) {
    if(auto other_cast = dynamic_cast<const ReverseLevelIterator*>(&other)) {
        return m_ptr.size() != other_cast->m_ptr.size() || m_ptr.front() != other_cast->m_ptr.front() || m_ptr.front() != other_cast->m_ptr.front();
    }
    return false ;
}


ForwardLevelIterator::ForwardLevelIterator(Node* node)  {
    // Initialize the stack with the given node
    if(node){ 
        m_ptr.push(node); 
    } 
}
ForwardLevelIterator::~ForwardLevelIterator() { 
}
Node& ForwardLevelIterator::operator*() {
    // Return a reference to the top element of the stack
    return *m_ptr.front();
}

Node* ForwardLevelIterator::operator->() {
    // Return a pointer to the top element of the stack
    return m_ptr.front();
}

ForwardLevelIterator& ForwardLevelIterator::operator++() {
    // Pop the top element of the stack
    Node* current = m_ptr.front(); 
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
        if (m_ptr.empty() && other_cast->m_ptr.empty()) {
            return true;
        }
        return m_ptr.size() == other_cast->m_ptr.size() && m_ptr.front() == other_cast->m_ptr.front() && m_ptr.front() == other_cast->m_ptr.front();
    }
    return false ;
}

bool ForwardLevelIterator::operator!=(const GraphIterator& other) {
    // Compare the queues of the two iterators 
    return !this->operator==(other);
}

Graph::Graph(Node* root) : m_root(root) {
}
ForwardLevelIterator Graph::begin() {
    return ForwardLevelIterator(m_root);
}
ForwardLevelIterator Graph::end() { // ! TODO : Implement this
    return ForwardLevelIterator(nullptr);
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

    int data_node = 0 ; 
    int op_node = 0 ;  
    int addcount = 0 ; 
    int subcount = 0 ;  
    int matmul2xcount=  0 ; 
    int matmul3xcount=  0 ; 
    std::unordered_map<Node*, int> level;
    std::queue<Node*> q;

    level[m_root] = 0;
    q.push(m_root);

    while (!q.empty()) {
        Node* node = q.front();
        q.pop();
        std::cout << "Level " << level[node] << ": ";
        std::cout << "Node " << node <<  " node type: " << node->GetAttribute("node_type") << " value type: " << node->GetAttribute("value_type"); 
        if (node->GetAttribute("node_type")=="op") { 
            OpNode* op = dynamic_cast<OpNode*>(node);
            op_node++ ; 
            if (op->GetOpcode() == Opcode_t::ADD) { 
                std::cout << " Operation type:  ADD ";
                addcount++ ;
            } else if (op->GetOpcode() == Opcode_t::SUB) { 
                std::cout << " Operation type:  SUB ";
                subcount++ ;
            } else if (op->GetOpcode() == Opcode_t::MMUL_2x) { 
                matmul2xcount++ ;
                std::cout << " Operation type:  MMUL_2x ";
            } else { 
                matmul3xcount++ ;
                std::cout << " Operation type:  MMUL_3x ";
            } 
        } else if (node->GetAttribute("node_type")=="data"){ 
            data_node++ ; 
        } 
        std::cout << std::endl;

        for (Node* user : node->Users()) { 
            // std::cout << "  User " << user << std::endl;
            if (level.find(user) == level.end()) {
                level[user] = level[node] + 1;
                q.push(user);
            }
        }
    }
    std::cout << "Number of data nodes: " << data_node << "Number of op nodes: " << op_node << std::endl ; 
    std::cout << "Number of Addition nodes: " << addcount << std::endl ;
    std::cout << "Number of Subtraction nodes: " << subcount << std::endl ; 
    std::cout << "Number of 2x2 matmul nodes: " << matmul2xcount << std::endl ;
    std::cout << "Number of 3x3 matmul nodes: " << matmul3xcount << std::endl ;

}
void Graph::PrintGraphReverse() {
    std::unordered_map<Node*, int> level;
    std::queue<Node*> q;

    level[m_root] = 0;
    q.push(m_root);

    while (!q.empty()) {
        Node* node = q.front();
        q.pop();
        std::cout << "Level " << level[node] << ": ";
        std::cout << "Node " << node <<  " node type: " << node->GetAttribute("node_type") << " value type: " << node->GetAttribute("value_type"); 
        if (node->GetAttribute("node_type")=="op") { 
            OpNode* op = dynamic_cast<OpNode*>(node);
            if (op->GetOpcode() == Opcode_t::ADD) { 
                std::cout << " Operation type:  ADD ";
            } else if (op->GetOpcode() == Opcode_t::SUB) { 
                std::cout << " Operation type:  SUB ";
            } else if (op->GetOpcode() == Opcode_t::MMUL_2x) { 
                std::cout << " Operation type:  MMUL_2x ";
            } else { 
                std::cout << " Operation type:  MMUL_3x ";
            } 
        } 
        std::cout << std::endl;

        for (Node* input: node->Inputs()) { 
            // std::cout << "  User " << user << std::endl;
            if (level.find(input) == level.end()) {
                level[input] = level[node] + 1;
                q.push(input);
            }
        }
    }
}
