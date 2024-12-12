# app.py
from flask import Flask, render_template, request, jsonify
import sqlite3
from datetime import datetime

app = Flask(__name__)

def init_db():
    conn = sqlite3.connect('todos.db')
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task TEXT NOT NULL,
            status TEXT DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Insert default DevOps tasks if table is empty
    c.execute('SELECT COUNT(*) FROM todos')
    if c.fetchone()[0] == 0:
        default_tasks = [
            ("Set up Jenkins Pipeline for CI/CD", "pending"),
            ("Configure EKS Cluster in AWS", "completed"),
            ("Create Dockerfile for Flask Application", "completed"),
            ("Implement Kubernetes Deployments", "pending"),
            ("Set up Monitoring and Logging", "pending"),
            ("Configure Auto-scaling for EKS", "pending"),
            ("Implement Security Best Practices", "pending"),
            ("Create Infrastructure as Code (Terraform)", "completed"),
            ("Set up Backup and Disaster Recovery", "pending"),
        ]
        c.executemany('INSERT INTO todos (task, status) VALUES (?, ?)', default_tasks)
    
    conn.commit()
    conn.close()

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/api/todos', methods=['GET'])
def get_todos():
    conn = sqlite3.connect('todos.db')
    c = conn.cursor()
    c.execute('SELECT * FROM todos ORDER BY created_at DESC')
    todos = [{'id': row[0], 'task': row[1], 'status': row[2], 
              'created_at': row[3], 'updated_at': row[4]} for row in c.fetchall()]
    conn.close()
    return jsonify(todos)

@app.route('/api/todos', methods=['POST'])
def add_todo():
    task = request.json.get('task')
    conn = sqlite3.connect('todos.db')
    c = conn.cursor()
    c.execute('INSERT INTO todos (task) VALUES (?)', (task,))
    todo_id = c.lastrowid
    conn.commit()
    conn.close()
    return jsonify({'id': todo_id, 'task': task, 'status': 'pending'})

@app.route('/api/todos/<int:todo_id>', methods=['PUT'])
def update_todo(todo_id):
    status = request.json.get('status')
    conn = sqlite3.connect('todos.db')
    c = conn.cursor()
    c.execute('UPDATE todos SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?', 
              (status, todo_id))
    conn.commit()
    conn.close()
    return jsonify({'success': True})

@app.route('/api/todos/<int:todo_id>', methods=['DELETE'])
def delete_todo(todo_id):
    conn = sqlite3.connect('todos.db')
    c = conn.cursor()
    c.execute('DELETE FROM todos WHERE id = ?', (todo_id,))
    conn.commit()
    conn.close()
    return jsonify({'success': True})

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5053)