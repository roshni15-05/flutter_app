import 'package:todos_demo_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:todos_demo_app/database/hive_helper.dart';
import 'package:todos_demo_app/models/todo_model.dart';

class AddEditPage extends StatefulWidget {
  final Todo? todo; // Accept optional todo
  final int? index; // Accept optional index

  const AddEditPage({super.key, this.todo, this.index});

  @override
  State<AddEditPage> createState() => _AddEditPageState();
}

class _AddEditPageState extends State<AddEditPage> {

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int _priority = 1; // Default: Medium Priority

  @override
  void initState() {
    super.initState();

    // If editing, pre-fill fields
    if (widget.todo != null) {
      _titleController.text = widget.todo!.todo;
      _descriptionController.text = widget.todo!.description;
      _priority = widget.todo!.priority;
    }
  }

  Color _getPriorityColor() {
    // Return the background color based on priority
    if (_priority == 2) {
      return Colors.red; // High priority: Red
    } else if (_priority == 1) {
      return Colors.orange; // Medium priority: Orange
    } else {
      return Colors.green; // Low priority: Green
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todo == null ? 'Add Todo' : 'Edit Todo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: _getPriorityColor(), // Set the background color based on priority
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: _getPriorityColor(), // Set the background color based on priority
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: DropdownButtonFormField<int>(
              value: _priority,
              items: const [
                DropdownMenuItem(value: 2, child: Text('High Priority')),
                DropdownMenuItem(value: 1, child: Text('Medium Priority')),
                DropdownMenuItem(value: 0, child: Text('Low Priority')),
              ],
              onChanged: (value) {
                setState(() {
                  _priority = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: ElevatedButton(
              onPressed: _saveTodo,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(180, 60),
                  backgroundColor: Colors.purple),
              child: Text(widget.todo == null ? 'Add Todo' : 'Update Todo',
                  style: const TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTodo() async {
    String title = _titleController.text.trim();
    String description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and description cannot be empty')),
      );
      return;
    }

    final todoData = {
      "todo": title,
      "description": description,
      "priority": _priority,
      "completed": false,
      "userId": 5,
    };

    try {
      Todo newTodo = await ApiService.addTodo(todoData); // Add to API
      await HiveHelper.addTodo(newTodo); // Save to Hive

      print("Added Todo: ${newTodo.todo}");

      Navigator.pop(context); // Return 'true' to trigger UI refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }
}
