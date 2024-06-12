import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'todo_item.dart';

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key, required this.title});

  final String title;

  @override
  _TodoHomePageState createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  Map<int, String> listNames = {}; // Map to store list names
  Map<int, List<TodoItem>> todoLists = {};
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadTodoLists();
  }

  Future<void> _loadTodoLists() async {
    List<Map<String, dynamic>> lists = await dbHelper.getTodoLists();
    Map<int, List<TodoItem>> loadedTodoLists = {};
    Map<int, String> loadedListNames = {};
    for (var list in lists) {
      int listId = list['id'];
      String listName = list['name'];
      List<Map<String, dynamic>> items = await dbHelper.getTodoItems(listId);
      List<TodoItem> todoItems = items.map((item) => TodoItem(id: item['id'], title: item['title'], isDone: item['is_done'] == 1)).toList();
      loadedTodoLists[listId] = todoItems;
      loadedListNames[listId] = listName;
    }
    setState(() {
      todoLists = loadedTodoLists;
      listNames = loadedListNames;
    });
  }

  void _addTodoList(String listName) async {
    await dbHelper.insertTodoList(listName);
    _loadTodoLists();
  }

  void _deleteTodoList(int listId) async {
    await dbHelper.deleteTodoList(listId);
    setState(() {
      todoLists.remove(listId);
      listNames.remove(listId);
    });
  }

  void _addTodoItem(int listId, String title) async {
    await dbHelper.insertTodoItem(listId, title);
    _loadTodoLists();
  }

  void _deleteTodoItem(int listId, int itemId) async {
    await dbHelper.deleteTodoItem(itemId);
    _loadTodoLists();
  }

  void _toggleTodoItem(int listId, TodoItem item) async {
    item.isDone = !item.isDone;
    await dbHelper.updateTodoItem(item.id, item.isDone);
    _loadTodoLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView(
        children: todoLists.keys.map((listId) => _buildTodoList(listId)).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddListDialog(context), // This triggers the dialog to add a new list.
        tooltip: 'Add List',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodoList(int listId) {
    var todoItems = todoLists[listId] ?? [];
    String listName = listNames[listId] ?? 'Unnamed List';
    return Card(
      child: ExpansionTile(
        title: Text(listName),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteTodoList(listId),
        ),
        children: [
          if (todoItems.isNotEmpty)
            for (var item in todoItems)
              ListTile(
                title: Text(item.title,
                    style: TextStyle(decoration: item.isDone ? TextDecoration.lineThrough : null)),
                leading: Checkbox(
                  value: item.isDone,
                  onChanged: (bool? value) {
                    _toggleTodoItem(listId, item);
                  },
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteTodoItem(listId, item.id),
                ),
              )
          else
            const ListTile(
              title: Text("No items yet"),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              child: const Text("Add Item"),
              onPressed: () => _showAddItemDialog(listId),
            ),
          )
        ],
      ),
    );
  }


  void _showAddListDialog(BuildContext context) {
    TextEditingController listNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Todo List'),
          content: TextField(
            controller: listNameController,
            decoration: const InputDecoration(hintText: "List name"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                var listName = listNameController.text.trim();
                if (listName.isNotEmpty) {
                  _addTodoList(listName);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddItemDialog(int listId) {
    TextEditingController itemController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Todo Item'),
          content: TextField(
            controller: itemController,
            decoration: const InputDecoration(hintText: "Todo item title"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (itemController.text.isNotEmpty) {
                  _addTodoItem(listId, itemController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
