import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:note/model/note.dart';

class NotesDatabase {
  static final NotesDatabase instance = NotesDatabase._init();

  static Database? _database;

  NotesDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('noted.db');

    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database database, int version) async {
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final textType = 'TEXT NOT NULL';
    final boolType = 'BOOLEAN NOT NULL';
    final integerType = 'INTEGER NOT NULL';

    database.execute('''
      CREATE TABLE $tableNotes ( 
        ${NoteFields.id} $idType, 
        ${NoteFields.isImportant} $boolType,
        ${NoteFields.number} $integerType,
        ${NoteFields.title} $textType,
        ${NoteFields.description} $textType,
        ${NoteFields.time} $textType
      )
    ''');
  }

  Future close() async {
    final database = await instance.database;

    database.close();
  }

  Future<List<Note>> getAll() async {
    final database = await instance.database;

    final orderBy = '${NoteFields.time} ASC';

    final results = await database.query(tableNotes, orderBy: orderBy);

    return results.map((json) => Note.fromJson(json)).toList();
  }

  Future<Note> create(Note note) async {
    final database = await instance.database;

    final id = await database.insert(tableNotes, note.toJson());

    return note.copy(id: id);
  }

  Future<Note> getOne(int id) async {
    final database = await instance.database;

    final maps = await database.query(
      tableNotes,
      columns: NoteFields.values,
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Note.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<int> update(Note note) async {
    final database = await instance.database;

    return database.update(
      tableNotes,
      note.toJson(),
      where: '${NoteFields.id} = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(int id) async {
    final database = await instance.database;

    return database.delete(
      tableNotes,
      where: '${NoteFields.id} = ?',
      whereArgs: [id],
    );
  }
}
