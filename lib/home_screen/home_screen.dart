import 'package:todos_demo_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:todos_demo_app/database/hive_helper.dart';
import 'package:todos_demo_app/models/todo_model.dart';
import 'package:todos_demo_app/home_screen/add_edit_page.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool) toggleTheme;
  final bool isDarkMode;

  const HomeScreen({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Todo> _todos = [];
  List<Todo> _filteredTodos = []; // List to hold filtered todos
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTodos();

    // Correct way to listen for changes:
    _searchController.addListener(_filterTodos); // Call _filterTodos when text changes
  }

  void _filterTodos() {
    String searchText = _searchController.text.toLowerCase(); // Case-insensitive search

    setState(() {
      _filteredTodos = _todos.where((todo) =>
      todo.todo.toLowerCase().contains(searchText) ||
          todo.description.toLowerCase().contains(searchText)).toList();
    });
  }

  Future<void> _fetchTodos() async {
    try {
      List<Todo> hiveTodos = await HiveHelper.getTodos();
      setState(() {
        _todos = hiveTodos;
        _filteredTodos = List.from(_todos);
      });

      List<Todo> apiTodos = await ApiService.fetchTodos();
      await HiveHelper.saveTodos(apiTodos);

      setState(() {
        _todos = apiTodos;
        _filteredTodos = List.from(_todos);
      });
    } catch (e) {
      print("Error fetching todos: $e");
    }
  }

  Future<void> _addTodo(Todo todo) async{
    await ApiService.addTodo(todo as Map<String, dynamic>);
    await HiveHelper.addTodo(todo);
    _fetchTodos();
  }

  Future<void> _deleteTodo(int index) async{
    final todo = _todos[index];
    await ApiService.deleteTodo(todo.id);
    await HiveHelper.deleteTodo(todo.id);

    setState(() {
      _todos.removeAt(index);
      _filteredTodos= List.from(_todos);
    });
  }
  // Color based on priority
  Color _getPriorityColor(int priority) {
    if (priority == 2) {
      return Colors.red; // High priority
    } else if (priority == 1) {
      return Colors.orange; // Medium priority
    } else {
      return Colors.green; // Low priority
    }
  }
  // Edit Todo in the list
  void _editTodo(int index, Todo todo) async {
    bool? result = await Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (context) => AddEditPage(todo: todo, index: index),
    ),
    );
    if(result==true){
      _fetchTodos(); // Refresh list after edit
    }
  }
  // Change priority of the Todo
  Future<void> _changePriority(int index, Todo todo) async {
    int newPriority = todo.priority;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Priority'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('High'),
                onTap: () {
                  newPriority = 2;
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Medium'),
                onTap: () {
                  newPriority = 1;
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Low'),
                onTap: () {
                  newPriority = 0;
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
    if (newPriority != todo.priority) {
      todo.priority = newPriority;
      // Update the todo in the database
      await HiveHelper.updateTodo(index, todo);
      setState(() {});// refresh the ui
      _fetchTodos(); // Refresh list after updating
    }
  }
  Future<void> _toggleCompletion(int index, bool isCompleted) async{
    await HiveHelper.toggleCompletion(index, isCompleted);
    _fetchTodos();
  }
  @override
  void dispose() {
    _searchController.dispose(); // Dispose of the search controller
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TODO APP'),
        backgroundColor: Colors.lightBlue,
        centerTitle: true,
        actions: [
          IconButton( icon: Icon(widget.isDarkMode ? Icons.dark_mode:Icons.light_mode),
            onPressed: (){
              widget.toggleTheme(!widget.isDarkMode);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var newTodo = await Navigator.push(
            context, MaterialPageRoute(builder: (context) => AddEditPage()),
          );
          if(newTodo != null && newTodo is Todo) {
            setState(() {
              _todos.insert(0, newTodo);
              _filteredTodos = List.from(_todos);
            });
          }
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white, size: 40),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Todo...',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTodos.length,
              itemBuilder: (context, index) {
                final todo = _filteredTodos[index];
                print("Displaying Todo: ${todo.todo}");
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(todo.priority),
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: ListTile(
                    leading: Checkbox(
                      value: todo.isCompleted,
                      onChanged: (bool ? value) async{
                        setState(() {
                          todo.isCompleted = value ?? false;
                        });
                        await HiveHelper.updateTodo(index, todo);
                        if(todo.isCompleted){
                          Future.delayed(const Duration(seconds: 1),() async{
                            await _deleteTodo(index);
                          });
                        }
                      },
                    ),
                    title: Text(todo.todo),
                    subtitle: Text(todo.description),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteTodo(index);
                        } else if (value == 'edit') {
                          _editTodo(index, todo);
                        } else if (value == 'priority') {
                          _changePriority(index, todo); // Change priority
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        const PopupMenuItem(value: 'priority', child: Text('Change Priority')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
