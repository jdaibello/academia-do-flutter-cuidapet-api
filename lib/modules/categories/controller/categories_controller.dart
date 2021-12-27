import 'dart:async';
import 'dart:convert';

import 'package:cuidapet_api/modules/categories/service/i_categories_service.dart';
import 'package:injectable/injectable.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'categories_controller.g.dart';

@Injectable()
class CategoriesController {
  ICategoriesService service;

  CategoriesController({required this.service});

  @Route.get('/')
  Future<Response> findAll(Request request) async {
    try {
      final categories = await service.findAll();
      final categoriesResponse = categories
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'type': c.type,
              })
          .toList();

      return Response.ok(jsonEncode(categoriesResponse));
    } catch (e) {
      return Response.internalServerError();
    }
  }

  Router get router => _$CategoriesControllerRouter(this);
}
