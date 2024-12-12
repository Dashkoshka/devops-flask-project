// static/script.js
document.addEventListener('DOMContentLoaded', loadTodos);

async function loadTodos() {
    try {
        const response = await fetch('/api/todos');
        const todos = await response.json();
        const todoList = document.getElementById('todoList');
        todoList.innerHTML = '';

        todos.forEach(todo => {
            const todoElement = createTodoElement(todo);
            todoList.appendChild(todoElement);
        });
    } catch (error) {
        console.error('Error loading todos:', error);
    }
}

function createTodoElement(todo) {
    const div = document.createElement('div');
    div.className = `todo-item ${todo.status === 'completed' ? 'completed' : ''}`;
    div.dataset.id = todo.id;

    div.innerHTML = `
        <span class="task-text">${todo.task}</span>
        <button onclick="toggleTodo(${todo.id})" class="action-btn" data-tooltip="${todo.status === 'completed' ? 'Mark as pending' : 'Mark as completed'}">
            <img src="/static/images/${todo.status === 'completed' ? 'completed.png' : 'pending.png'}" 
                 alt="${todo.status}" class="pokemon-icon">
        </button>
        <button onclick="deleteTodo(${todo.id})" class="action-btn" data-tooltip="Release this task">
            <img src="/static/images/delete.png" alt="Delete" class="pokemon-icon">
        </button>
    `;

    return div;
}

async function addTodo() {
    const input = document.getElementById('newTodo');
    const task = input.value.trim();

    if (!task) return;

    try {
        const response = await fetch('/api/todos', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ task })
        });

        const todo = await response.json();
        const todoList = document.getElementById('todoList');
        todoList.prepend(createTodoElement(todo));
        input.value = '';
    } catch (error) {
        console.error('Error adding todo:', error);
    }
}

async function toggleTodo(id) {
    const todoElement = document.querySelector(`[data-id="${id}"]`);
    const isCompleted = todoElement.classList.contains('completed');
    const newStatus = isCompleted ? 'pending' : 'completed';

    try {
        await fetch(`/api/todos/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ status: newStatus })
        });

        todoElement.classList.toggle('completed');
        const statusImg = todoElement.querySelector('.pokemon-icon');
        statusImg.src = `/static/images/${newStatus}.png`;
    } catch (error) {
        console.error('Error updating todo:', error);
    }
}

async function deleteTodo(id) {
    try {
        const response = await fetch(`/api/todos/${id}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            const todoElement = document.querySelector(`[data-id="${id}"]`);
            if (todoElement) {
                todoElement.style.animation = 'fadeOut 0.3s ease';
                // Wait for animation to complete before removing the element
                setTimeout(() => {
                    todoElement.remove();
                }, 300);
            }
        }
    } catch (error) {
        console.error('Error deleting todo:', error);
    }
}