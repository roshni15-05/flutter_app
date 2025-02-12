import 'package:hive/hive.dart';
import 'package:todos_demo_app/models/todo_model.dart';

class HiveHelper {
  static Box<Todo> get _todoBox => Hive.box<Todo>('todosBox');

  static Future<void> addTodo(Todo todo) async {
    var box = await Hive.openBox<Todo>('todosBox');
    await _todoBox.add(todo);
    print("Todo added to Hive: ${todo.todo}");
  }

  static List<Todo> getTodos() {
    return _todoBox.values.toList(); // Fetch todos from Hive box
  }

  static Future<void> updateTodo(int index, Todo updatedTodo) async {
    await _todoBox.putAt(index, updatedTodo);
  }

  static Future<void> deleteTodo(int index) async {
    await _todoBox.deleteAt(index);
  }

  static Future<void> toggleCompletion(int index, bool isCompleted)
  async{
    final box = _todoBox;
    final todo = box.getAt(index);
    if (todo!=null){
      await box.putAt(
        index,
        Todo(
          id: todo.id,
          todo: todo.todo,
          description: todo.description,
          priority: todo.priority,
          isCompleted: !todo.isCompleted,
          userId: todo.userId,
        ),
      );
    }
  }

  static Future<void> saveTodos(List<Todo> apiTodos) async {
    await _todoBox.clear();
    for(var todo in apiTodos){
      await _todoBox.put(todo.id, todo);
    }
  }
}
