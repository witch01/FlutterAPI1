import 'dart:io';

import 'package:conduit/conduit.dart';

import '../model/user.dart';
import '../utils/app_responce.dart';
import '../utils/app_utils.dart';

class AppUserConttolelr extends ResourceController {
  AppUserConttolelr(this.managedContext);

  final ManagedContext managedContext;

  @Operation.get()
  Future<Response> getProfile(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
  ) async {
    try {
      // Получаем id пользователя
      // Была создана новая функция ее нужно реализоваться для просмотра функции нажмите на картинку
      final id = AppUtils.getIdFromHeader(header);
      // Получаем данные пользователя по его id
      final user = await managedContext.fetchObjectWithID<User>(id);
      // Удаляем не нужные параметры для красивого вывода данных пользователя
      user!.removePropertiesFromBackingMap(['refreshToken', 'accessToken']);

      return AppResponse.ok(
          message: 'Успешное получение профиля', body: user.backing.contents);
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка получения профиля');
    }
  }
}