#pragma once 
#include <initializer_list>
#include <stack>
#include <string>
#include <vector> 
#include <unordered_map>
// commutative node

class Node { 
    public: 
        Node() ; 
        Node(const Node &) = default; // cpy
        Node(Node&&) = default; // move
        Node &operator=(const Node &) = default;// cpy
        Node &operator=(Node &&) = default; // move
        Node(const std::initializer_list<Node*>& list) ; 
        virtual ~Node() = 0 ; 
        virtual void* GetValue(); 
        std::vector<Node*>& Users() ; 
        std::vector<Node*>& Inputs() ; 
        void AddAttribute(const std::string& key, const std::string& value){m_attributes[key] = value;} ;
        bool HasAttribute(const std::string& key) { 
            return m_attributes.find(key) != m_attributes.end() ; 
        }
        std::string GetAttribute(const std::string& key) {;
            return m_attributes[key] ; 
        }
        Node* Ptr() { 
            return this ;
        } 
        void AddInput(Node* node){m_inputs.push_back(node);} ;
        void AddUser(Node* node){m_users.push_back(node);} ;
      private: 
        std::vector<Node*> m_inputs; 
        std::vector<Node*> m_users ; 
        std::unordered_map<std::string, std::string> m_attributes;
};  

class GraphIterator
{
    public:
        GraphIterator(Node* node);
        virtual Node& operator*();
        virtual Node* operator->();
        virtual GraphIterator& operator++();
        virtual GraphIterator& operator--();
        virtual bool operator==(const GraphIterator&) ; 
        virtual bool operator!=(const GraphIterator&) ; 
};

class ForwardLevelIterator : public GraphIterator{ 
    public : 
        ForwardLevelIterator(Node* node) ; 
        Node& operator*() override;  
        Node* operator->() override ;  
        ForwardLevelIterator& operator++() override; // covariant return type 
        ForwardLevelIterator& operator--() override; 
        bool operator==(const GraphIterator&) override; 
        bool operator!=(const GraphIterator&) override; 
    private:  
        std::stack<Node*> m_ptr;   
    
}; 

class ReverseLevelIterator : public GraphIterator{ 
    public : 
        ReverseLevelIterator(Node* node) ; 
        Node& operator*() override;  
        Node* operator->() override ;  
        ReverseLevelIterator& operator++() override; 
        ReverseLevelIterator& operator--() override; 
        bool operator==(const GraphIterator&) override; 
        bool operator!=(const GraphIterator&) override; 
    private:  
        std::stack<Node*> m_ptr;
}  ; 

class Graph { 
    public: 
        GraphIterator begin() ; 
        GraphIterator end() ;  // take rightmost  node 
    private: 
        Node* m_root ; 

} ;







// iterator 

