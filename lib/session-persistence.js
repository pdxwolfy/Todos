const SeedData = require("./seed-data");
const deepCopy = require("./deep-copy.js");
const nextId = require('./next-id');
const { sortTodoLists, sortTodos } = require('./sort');

module.exports = class SessionPersistence {
  constructor(session) {
    this._todoLists = session.todoLists || deepCopy(SeedData);
    session.todoLists = this._todoLists;
  }

  sortedTodoLists() {
    let todoLists = deepCopy(this._todoLists);
    let undone = todoLists.filter(todoList => !this.isDoneTodoList(todoList));
    let done = todoLists.filter(todoList => this.isDoneTodoList(todoList));
    return sortTodoLists(undone, done);
  }

  isDoneTodoList(todoList) {
    return todoList.length > 0 && todoList.todos.every((todo) => todo.done);
  }

  loadTodoList(todoListId) {
    let todoList = this._findTodoList(todoListId);
    return deepCopy(todoList);
  }

  hasUndoneTodos(todoList) {
    return todoList.todos.some((todo) => !todo.done);
  }

  sortedTodos(todoList) {
    let todos = todoList.todos;
    let undone = todos.filter((todo) => !todo.done)
    let done = todos.filter((todo) => todo.done)
    return sortTodos(undone, done);
  }

  loadTodo(todoListId, todoId) {
    let todo = this._findTodo(todoListId, todoId);
    // if (!todoList) return undefined;
    return deepCopy(todo);
  };

  toggleDoneTodo(todoListId, todoId) {
    let todo = this._findTodo(todoListId, todoId);

    if (!todo) return false;
    todo.done = !todo.done;
    return true;
  }

  deleteTodoList(todoListId) {
    let todoListIndex = this._todoLists.findIndex((todoList) => todoList.id === todoListId);

    if (todoListIndex === -1) return false;

    this._todoLists.splice(todoListIndex, 1);
    return true;


  }

  deleteTodo(todoListId, todoId) {
    let todoList = this._findTodoList(todoListId);
    if (!todoList) return false;

    let todoIndex = todoList.todos.findIndex(todo => todo.id === todoId);
    if (todoIndex === -1) return false;

    todoList.todos.splice(todoIndex, 1);
    return true;
  }

  _findTodoList(todoListId) {
    return this._todoLists.find((todoList) => todoListId === todoList.id);
  }

  _findTodo(todoListId, todoId) {
    let todoList = this._findTodoList(todoListId);
    console.log(todoList);

    return todoList.todos.find((todo) => todo.id === todoId)
  }

  completeAll(todoListId) {
    let todoList = this._findTodoList(todoListId);
    
    if (!todoList) return false;

    todoList.todos.filter((todo) => !todo.done)
      .forEach(todo => todo.done = true);

    return true;
  }

  createTodo(todoTitle, todoListId) {
    let todoList = this._findTodoList(todoListId);

    if (!todoList) return false;

    todoList.todos.push({
      id: nextId(),
      title: todoTitle,
      done: false,
    });

    return true;
  }

  setTitle(todoListId, title) {
    let todoList = this._findTodoList(todoListId);
    if (!todoList) return false;
    todoList.title = title;
    return true;
  }

  existsTodoListTitle(title) {
    return this._todoLists.some((todoList) => todoList.title === title);
  }

  createTodoList(title) {
    let todoList = {
      id: nextId(),
      title: title,
      todos: []
    }

    this._todoLists.push(todoList)
    return true;
  }

  isUniqueConstraintViolation(_error) {
    return false;
  }
}