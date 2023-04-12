#pragma once 
#include <initializer_list>
#include <string>
#include <vector> 
#include <unordered_map>
#include <algorithm> 
#include <queue> 


class Node { 
    public: 
        Node() :m_parent (nullptr) {} ; 
        Node(const Node &) = default; // cpy
        Node(Node&&) = default; // move
        Node &operator=(const Node &) = default;// cpy
        Node &operator=(Node &&) = default; // move
        std::vector<Node*>& Users() ; 
        std::vector<Node*>& Inputs() ; 
        void AddAttribute(const std::string& key, const std::string& value); 
        bool HasAttribute(const std::string& key) ; 
        std::string GetAttribute(const std::string& key) ;
        void AddInput(Node* node) ;
        void AddUser(Node* node);
        void SetParent(Node* node) ;  
        Node* GetParent(); 
        // virtual 
        virtual ~Node()  ; 
        virtual void* GetValue() =0; 
      private: 
        std::vector<Node*> m_inputs; 
        std::vector<Node*> m_users ; 
        std::unordered_map<std::string, std::string> m_attributes;
        Node* m_parent; 
};  

class GraphIterator
{
    public:
        GraphIterator()   = default; 
        ~GraphIterator() = default;
        virtual Node& operator*() = 0 ;
        virtual Node* operator->()= 0 ;
        virtual GraphIterator& operator++() = 0 ;
        virtual GraphIterator& operator--() = 0 ; 
        virtual bool operator==(const GraphIterator&) = 0 ; 
        virtual bool operator!=(const GraphIterator&) = 0 ; 
};

class ForwardLevelIterator : public GraphIterator{ 
    public : 
        ForwardLevelIterator(Node* node) ; 
        ~ForwardLevelIterator() ;
        virtual Node& operator*() override;  
        virtual Node* operator->() override ;  
        virtual ForwardLevelIterator& operator++() override ; // covariant return type 
        virtual ForwardLevelIterator& operator--() override ; 
        virtual bool operator==(const GraphIterator&) override; 
        virtual bool operator!=(const GraphIterator&) override; 
    private:  
        std::queue<Node*> m_ptr;   
    
}; 

class ReverseLevelIterator : public GraphIterator{ 
public: 
    ReverseLevelIterator(Node* node, const std::string& type = "", bool auto_traverse =true) ;// Filter specific node type with type
    ~ReverseLevelIterator() ;
    virtual Node& operator*() override;  
    virtual Node* operator->() override ;  
    virtual ReverseLevelIterator& operator++() override; 
    virtual ReverseLevelIterator& operator--() override; 
    virtual bool operator==(const GraphIterator&) override; 
    virtual bool operator!=(const GraphIterator&) override; 
private:  
    std::queue<Node*> m_ptr;
    std::string m_type;
};


class Graph { 
    public: 
        Graph(Node* root) ;
        ForwardLevelIterator begin() ;  
        ForwardLevelIterator end()   ;  // take rightmost  node 
        ReverseLevelIterator rbegin() ; 
        ReverseLevelIterator rend()   ;  // take rightmost  node  
        Node* GetRoot() ;
        void PrintGraph() ; 
        void PrintGraphReverse() ; 
    private: 
        Node* m_root ; 

} ;





// iterator 

