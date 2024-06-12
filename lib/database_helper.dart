import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'todo.db');
    return openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE todo_lists(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE todo_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            list_id INTEGER,
            title TEXT,
            is_done INTEGER,
            FOREIGN KEY (list_id) REFERENCES todo_lists (id) ON DELETE CASCADE
          )
        ''');
      },
      version: 1,
    );
  }

  Future<void> insertTodoList(String name) async {
    final db = await database;
    await db.insert('todo_lists', {'name': name});
  }

  Future<void> deleteTodoList(int id) async {
    final db = await database;
    await db.delete('todo_lists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertTodoItem(int listId, String title) async {
    final db = await database;
    await db.insert('todo_items', {'list_id': listId, 'title': title, 'is_done': 0});
  }

  Future<void> deleteTodoItem(int id) async {
    final db = await database;
    await db.delete('todo_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTodoItem(int id, bool isDone) async {
    final db = await database;
    await db.update('todo_items', {'is_done': isDone ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getTodoLists() async {
    final db = await database;
    return await db.query('todo_lists');
  }

  Future<List<Map<String, dynamic>>> getTodoItems(int listId) async {
    final db = await database;
    return await db.query('todo_items', where: 'list_id = ?', whereArgs: [listId]);
  }
}
