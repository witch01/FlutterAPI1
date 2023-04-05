import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:taskapi/model/task.dart';

import '../model/user.dart';
import '../utils/app_responce.dart';
import '../utils/app_utils.dart';
import '../utils/model_responce.dart';


class AppTaskConttolelr extends ResourceController {
  AppTaskConttolelr(this.managedContext);
  final ManagedContext managedContext;



   @Operation.post() Future<Response> createTask(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() Task task,) async {
    try{
      final fUser = await managedContext.fetchObjectWithID<User>(AppUtils.getIdFromHeader(header));

      if(task.dateTask==null || task.description=="" || task.tag==""){
        return Response.badRequest(
          body:
              ModelResponse(message: 'Все поля должны быть заполнены'),
        );
      }
      late final int id;
      await managedContext.transaction((transaction) async {
          final qCreateTask = Query<Task>(transaction)
          ..values.dateTask = task.dateTask
          ..values.description = task.description
          ..values.tag=task.tag
          ..values.user = fUser;

          final createdtask = await qCreateTask.insert();
          id=createdtask.id!;
      });

        final taskData = await managedContext.fetchObjectWithID<Task>(id);
       return Response.ok(
         ModelResponse(
          data: taskData!.backing.contents,
          message: 'Задача успешно добавлена',
        ),
      );
       
    }on QueryException catch(e){
      return Response.serverError(

        body:  ModelResponse(message: e.message, error: "Not added")
      
      );
    }
    
  }

}