import 'package:hive/hive.dart';
part 'todo_model.g.dart';

@HiveType(typeId: 0)
class Todo {

  @HiveField(0)
  final int id;

  @HiveField(1)
  final String todo;

  @HiveField(2)
  final String description;

  @HiveField(3)
  int priority;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  int userId;

  Todo({
    required this.id,
    required this.todo,
    required this.description,
    this.priority = 1,
    this.isCompleted = false,
    required this.userId,
  });

  factory Todo.fromJson(Map<String,dynamic> json){
    return Todo(
      id: int.tryParse(json['id'].toString()) ?? 0,
      todo:json['todo'] ?? 'No Title' ,
      description: 'Fetched from API',
      priority:1,
      isCompleted:json['completed']?? false,
      userId: json['userId'],
    );
  }


  Map<String, dynamic> toJson(){
    return{
      'id': id,
      'todo':todo,
      'description': description,
      'priority': priority,
      'completed': isCompleted,
       'userId': userId
    };
  }
}
