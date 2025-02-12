import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:todos_demo_app/models/todo_model.dart';

class ApiService {

  static const String baseUrl = "https://dummyjson.com/todos";

  static Future<List<Todo>> fetchTodos() async {
    final response = await http.get(Uri.parse("https://dummyjson.com/todos"));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      List<Todo> todos = (jsonData['todos'] as List).map((json) => Todo.fromJson(json)).toList();
      await saveTodosHive(todos); // Await the save to Hive

      return todos;
    } else {
      throw Exception("Failed to load todos");
    }
  }

  static Future<Todo?> updateTodo(int id, Map<String, dynamic> todo) async{
    final response = await http.put(
      Uri.parse("https://dummyjson.com/todos/$id"),
      headers:{'content-Type': 'application/json'},
      body:jsonEncode(todo),
    );
    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if(response.statusCode== 200){
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return Todo.fromJson(responseData);
    }else{
      throw Exception("Failed to update todo: ${response.body}");
    }
  }
  static Future<void> deleteTodo(int id)async{
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if(response.statusCode== 200){
      print("Todo Deleted Successfully");
    }else{
      throw Exception("Failed to deleted todo");
    }
  }
  static Future<void> saveTodosHive(List<Todo> todos) async{
    var box = await Hive.openBox<Todo>('todosBox');
    await box.clear(); // Clear existing todos
    for (var todo in todos) {
      box.put(todo.id, todo);
    }
  }
  static Future<Todo> addTodo(Map<String, dynamic> todo) async {
    final url = Uri.parse('https://dummyjson.com/todos/add'); // Ensure this is correct
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json',},
        body: jsonEncode(todo),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String,dynamic> responseData = jsonDecode(response.body);
        return Todo.fromJson(responseData);
      } else {
        throw Exception('Failed to add todo: ${response.body}');
      }
    } catch (e) {
      print("Error adding todo: $e");
      throw Exception('Failed to add todo');
    }
  }
}
