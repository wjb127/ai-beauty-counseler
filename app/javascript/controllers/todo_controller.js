import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "list"]

  connect() {
    this.todos = []
  }

  handleSubmit(event) {
    event.preventDefault()
    const input = this.inputTarget
    const text = input.value.trim()
    
    if (text) {
      this.addTodo(text)
      input.value = ""
    }
  }

  addTodo(text) {
    const todo = {
      id: Date.now(),
      text: text,
      completed: false
    }
    
    this.todos.push(todo)
    this.renderTodos()
  }

  toggleTodo(event) {
    const id = parseInt(event.target.dataset.id)
    const todo = this.todos.find(t => t.id === id)
    if (todo) {
      todo.completed = !todo.completed
      this.renderTodos()
    }
  }

  deleteTodo(event) {
    const id = parseInt(event.target.dataset.id)
    this.todos = this.todos.filter(t => t.id !== id)
    this.renderTodos()
  }

  renderTodos() {
    const html = this.todos.map(todo => `
      <li class="flex items-center justify-between p-4 bg-white rounded-lg shadow-sm border border-gray-200">
        <div class="flex items-center space-x-3">
          <input type="checkbox" ${todo.completed ? 'checked' : ''} 
                 data-action="click->todo#toggleTodo" 
                 data-id="${todo.id}"
                 class="w-5 h-5 text-yellow-500 rounded focus:ring-yellow-400">
          <span class="${todo.completed ? 'line-through text-gray-500' : 'text-gray-800'} text-lg">
            ${todo.text}
          </span>
        </div>
        <button data-action="click->todo#deleteTodo" 
                data-id="${todo.id}"
                class="text-red-500 hover:text-red-700 font-bold text-lg">
          삭제
        </button>
      </li>
    `).join('')
    
    this.listTarget.innerHTML = html
  }
} 