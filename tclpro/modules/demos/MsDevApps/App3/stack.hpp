// A C++ template implementation of a stack.

#ifndef STACK_HPP
#define STACK_HPP

template <class T>
class Stack
{
public:
    Stack();
    ~Stack();
    void push (T data);
    T peek();
    T pop();
private:
    class Link
    {
    public:
	Link(T data, Link *next)
	{
	    _data = data;
	    _next = next;
	}
	T _data;
	Link *_next;
    } *_head;
};

template <class T>
Stack<T>::Stack()
    : _head(NULL)
{}

template <class T>
Stack<T>::~Stack()
{
    Link *cursor = _head;
    while (_head != NULL) {
	cursor = cursor->_next;
	delete _head;
	_head = cursor;
    }
}

template <class T>
void Stack<T>::push(T data) {
    Link *newLink = new Link(data, _head);
    _head = newLink;
};

template <class T>
T Stack<T>::peek() {
    if (_head == NULL) return 0;
    return _head->_data;
};

template <class T>
T Stack<T>::pop() {
    if (_head == NULL) return 0;
    T result = _head->_data;
    Link *oldHead = _head;
    _head = _head->_next;
    delete oldHead;
    return result;
};

#endif
