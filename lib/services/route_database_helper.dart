import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class RouteModel {
  final int? id;
  final String name;
  final String? description;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String startAddress;
  final String endAddress;
  final String polyline;
  final double? safetyScore;
  final String? duration;
  final String? distance;
  final String? crimeAnalysisJson; // Store as JSON string
  final bool isSaferRoute;
  final String routeType;
  final String createdAt;
  final String updatedAt;

  RouteModel({
    this.id,
    required this.name,
    this.description,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.startAddress,
    required this.endAddress,
    required this.polyline,
    this.safetyScore,
    this.duration,
    this.distance,
    this.crimeAnalysisJson,
    required this.isSaferRoute,
    required this.routeType,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startLat': startLat,
      'startLng': startLng,
      'endLat': endLat,
      'endLng': endLng,
      'startAddress': startAddress,
      'endAddress': endAddress,
      'polyline': polyline,
      'safetyScore': safetyScore,
      'duration': duration,
      'distance': distance,
      'crimeAnalysisJson': crimeAnalysisJson,
      'isSaferRoute': isSaferRoute ? 1 : 0,
      'routeType': routeType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      startLat: map['startLat'],
      startLng: map['startLng'],
      endLat: map['endLat'],
      endLng: map['endLng'],
      startAddress: map['startAddress'],
      endAddress: map['endAddress'],
      polyline: map['polyline'],
      safetyScore: map['safetyScore'],
      duration: map['duration'],
      distance: map['distance'],
      crimeAnalysisJson: map['crimeAnalysisJson'],
      isSaferRoute: map['isSaferRoute'] == 1,
      routeType: map['routeType'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }
}

class RouteDatabaseHelper {
  static final RouteDatabaseHelper _instance = RouteDatabaseHelper._internal();
  factory RouteDatabaseHelper() => _instance;
  RouteDatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'routes.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE routes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        startLat REAL,
        startLng REAL,
        endLat REAL,
        endLng REAL,
        startAddress TEXT,
        endAddress TEXT,
        polyline TEXT,
        safetyScore REAL,
        duration TEXT,
        distance TEXT,
        crimeAnalysisJson TEXT,
        isSaferRoute INTEGER,
        routeType TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
  }

  Future<int> insertRoute(RouteModel route) async {
    final db = await database;
    return await db.insert('routes', route.toMap());
  }

  Future<List<RouteModel>> getRoutes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('routes', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => RouteModel.fromMap(maps[i]));
  }

  Future<int> deleteRoute(int id) async {
    final db = await database;
    return await db.delete('routes', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
