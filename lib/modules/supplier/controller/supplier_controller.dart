import 'dart:async';
import 'dart:convert';

import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:cuidapet_api/modules/supplier/service/i_supplier_service.dart';
import 'package:injectable/injectable.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'supplier_controller.g.dart';

@Injectable()
class SupplierController {
  final ISupplierService service;
  final ILogger log;

  SupplierController({required this.service, required this.log});

  @Route.get('/')
  Future<Response> findNearByMe(Request request) async {
    try {
      final latitude =
          double.tryParse(request.url.queryParameters['lat'] ?? '');
      final longitude =
          double.tryParse(request.url.queryParameters['lng'] ?? '');

      if (latitude == null || longitude == null) {
        return Response(
          400,
          body: jsonEncode(
            {'message': 'Latitude [lat] and longitude [lng] are required'},
          ),
        );
      }

      final suppliers = await service.findNearByMe(latitude, longitude);
      final result = suppliers
          .map(
            (s) => {
              'id': s.id,
              'name': s.name,
              'logo': s.logo,
              'distance': s.distance,
              'category_id': s.categoryId,
            },
          )
          .toList();

      return Response.ok(jsonEncode(result));
    } catch (e, s) {
      log.error('Error when finding suppliers near by me', e, s);
      return Response.internalServerError(
        body: jsonEncode(
          {'message': 'Error when finding suppliers near by me'},
        ),
      );
    }
  }

  Router get router => _$SupplierControllerRouter(this);
}
