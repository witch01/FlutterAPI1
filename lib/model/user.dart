

import 'package:conduit/conduit.dart';
import 'package:taskapi/model/task.dart';

class User extends ManagedObject<_User> implements _User {}

class _User {
  @primaryKey
  int? id;
  @Column(unique: true, indexed: true)
  String? email;

  @Column(unique: false, indexed: true)
  String? firstname;

  @Column(unique: false, indexed: true)
  String? lastname;

  @Column(unique: false, indexed: true)
  String? middlename;

  @Serialize(input: true, output: false)
  String? password;
  @Column(nullable: true)
  String? accessToken;
  @Column(nullable: true)
  String? refreshToken;
  @Column(omitByDefault: true)
  String? salt;
  @Column(omitByDefault: true)
  String? hashPassword;

  ManagedSet<Task>? taskList;
}