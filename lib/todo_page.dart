import 'package:flutter/material.dart';
import 'todo.dart';
import 'database_helper.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({Key? key}) : super(key: key);

  @override
  _TodoPageState createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshTodoList();
    _searchController.addListener(_filterTodos);
  }

  Future<void> _refreshTodoList() async {
    final todos = await _dbHelper.getTodos();
    setState(() {
      _todos = todos;
      _filteredTodos = todos;
    });
  }

  void _filterTodos() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredTodos = _todos;
      });
    } else {
      _dbHelper.searchTodos(query).then((todos) {
        setState(() {
          _filteredTodos = todos;
        });
      });
    }
  }

  void _showAddTodoDialog({Todo? todo}) {
    final titleController = TextEditingController(text: todo?.title ?? '');
    final descriptionController = TextEditingController(text: todo?.description ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(todo == null ? 'Tambah Film' : 'Perbarui Film'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul Film'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                final newTodo = Todo(
                  id: todo?.id,
                  title: titleController.text,
                  description: descriptionController.text,
                  isCompleted: todo?.isCompleted ?? false,
                );
                if (todo == null) {
                  await _dbHelper.insertTodo(newTodo);
                } else {
                  await _dbHelper.updateTodo(newTodo);
                }
                await _refreshTodoList();
                Navigator.pop(context);
              }
            },
            child: Text(todo == null ? 'Tambah' : 'Perbarui'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Film'),
        content: const Text('Apakah Anda yakin ingin menghapus film ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await _dbHelper.deleteTodo(id);
              await _refreshTodoList();
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCompletedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Film yang Sudah Selesai'),
        content: const Text('Apakah Anda yakin ingin menghapus semua film yang sudah dicentang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await _dbHelper.deleteCompletedTodos();
              await _refreshTodoList();
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Film'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _showDeleteCompletedDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cari Film',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTodos.length,
              itemBuilder: (context, index) {
                final todo = _filteredTodos[index];
                return ListTile(
                  leading: Checkbox(
                    value: todo.isCompleted,
                    onChanged: (value) async {
                      todo.isCompleted = value ?? false;
                      await _dbHelper.updateTodo(todo);
                      await _refreshTodoList();
                    },
                  ),
                  title: Text(todo.title),
                  subtitle: Text(todo.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddTodoDialog(todo: todo),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteDialog(todo.id!),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}