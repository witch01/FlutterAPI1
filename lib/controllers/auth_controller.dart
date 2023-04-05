
import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

import '../model/user.dart';
import '../utils/app_utils.dart';
import '../utils/model_responce.dart';

class AppAuthContoler extends ResourceController {

  AppAuthContoler(this.managedContext);

  final ManagedContext managedContext;


  @Operation.put()
  Future<Response>signUp(@Bind.body() User user) async{

    if (user.password == "" || user.email == ""  || user.firstname=="" || user.lastname=="") {
      return Response.badRequest(
          body: ModelResponse(message: 'Все поля должны быть заполнены'));
    }
    try{
      // Генерация соли
      final salt = generateRandomSalt();
      // Генерация хэша пароля
      final hashPassword = generatePasswordHash(user.password!, salt);

      late final int id;


      await managedContext.transaction((transaction) async {
        // Создаем запрос для создания пользователя
        final qCreateUser = Query<User>(transaction)
          ..values.firstname = user.firstname
          ..values.lastname = user.lastname
          ..values.middlename = user.middlename
          ..values.email = user.email
          ..values.salt = salt
          ..values.hashPassword = hashPassword;
          
        // Добавление пользоваетля в базу данных
        final createdUser = await qCreateUser.insert();

        // Сохраняем id пользователя
        id = createdUser.id!;

        // Обновление токена
        _updateTokens(id, transaction);
      });
      
      final userData = await managedContext.fetchObjectWithID<User>(id);


      return Response.ok(
        ModelResponse(
          data: userData!.backing.contents,
          message: 'Пользователь успешно зарегистрирован',
        ),
      );


    }on QueryException catch(e){
      return Response.serverError(

        body:  ModelResponse(message: e.message)
      
      );
    }
    
  }


  @Operation.post()
  Future<Response> signIn(@Bind.body() User user) async {
    if (user.password == null || user.email == null) {
      return Response.badRequest(
          body: ModelResponse(message: 'Поля  password и email обязательны'));
    }

    try {
      // Поиск пользователя по имени в базе данных
      final qFindUser = Query<User>(managedContext)
        ..where((element) => element.email).equalTo(user.email)
        ..returningProperties(
          (element) => [
            element.id,
            element.salt,
            element.hashPassword,
          ],
        );
      final findUser = await qFindUser.fetchOne();

      if (findUser == null) {
        throw QueryException.input('Пользователь не найден', []);
      }
      final requestHashPassword =
          generatePasswordHash(user.password ?? '', findUser.salt ?? '');
      if (requestHashPassword == findUser.hashPassword) {
        _updateTokens(findUser.id ?? -1, managedContext);
        final newUser =
            await managedContext.fetchObjectWithID<User>(findUser.id);

        return Response.ok(ModelResponse(
          data: newUser!.backing.contents,
          message: 'Успешная авторизация',
        ));
      } else {
        throw QueryException.input('Не верный пароль', []);
      }
    } on QueryException catch(e){
      return Response.serverError(body: ModelResponse(message: e.message));
    }
  }


  @Operation.post('refresh')
    Future<Response> refreshToken(
        @Bind.path('refresh') String refreshToken) async {
      try {
        // Полчаем id пользователя из jwt token
        final id = AppUtils.getIdFromToken(refreshToken);

        // Получаем данные пользователя по его id
        final user = await managedContext.fetchObjectWithID<User>(id);

        if (user!.refreshToken != refreshToken) {
          return Response.unauthorized(body: 'Token не валидный');
        }

        // Обновление token
        _updateTokens(id, managedContext);

        return Response.ok(
          ModelResponse(
            data: user.backing.contents,
            message: 'Токен успешно обновлен',
          ),
        );
      } on QueryException catch (e) {
        return Response.serverError(body: ModelResponse(message: e.message));
      }
    }



   void _updateTokens(int id, ManagedContext transaction) async {
    final Map<String, String> tokens = _getTokens(id);

    final qUpdateTokens = Query<User>(transaction)
      ..where((element) => element.id).equalTo(id)
      ..values.accessToken = tokens['access']
      ..values.refreshToken = tokens['refresh'];

    await qUpdateTokens.updateOne();
  }



  Map<String, String> _getTokens(int id) {
    final key = Platform.environment['SECRET_KEY'] ?? 'SECRET_KEY';
    final accessClaimSet = JwtClaim(
      maxAge: const Duration(hours: 1), // Время жизни token
      otherClaims: {'id': id},
    );
    final refreshClaimSet = JwtClaim(
      otherClaims: {'id': id},
    );
    final tokens = <String, String>{};
    tokens['access'] = issueJwtHS256(accessClaimSet, key);
    tokens['refresh'] = issueJwtHS256(refreshClaimSet, key);

    return tokens;
  }
}