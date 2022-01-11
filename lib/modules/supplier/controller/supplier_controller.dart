import 'dart:convert';

import 'package:cuidapet_api/application/logger/i_logger.dart';
import 'package:cuidapet_api/entities/supplier.dart';
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

  @Route.get('/<id|[0-9]+>')
  Future<Response> findById(Request request, String id) async {
    try {
      final supplier = await service.findById(int.parse(id));

      if (supplier == null) {
        return Response.ok(jsonEncode({}));
      }

      return Response.ok(_supplierMapper(supplier));
    } catch (e, s) {
      log.error('Error when finding supplier by id', e, s);
      return Response.internalServerError(
        body: jsonEncode(
          {'message': 'Error when finding supplier by id'},
        ),
      );
    }
  }

  @Route.get('/<supplierId|[0-9]+>/services')
  Future<Response> findServicesBySupplierId(
    Request request,
    String supplierId,
  ) async {
    try {
      final supplierServices = await service.findServicesBySupplier(
        int.parse(supplierId),
      );

      final result = supplierServices
          .map((s) => {
                'id': s.id,
                'supplier_id': s.supplierId,
                'name': s.name,
                'price': s.price,
              })
          .toList();

      return Response.ok(jsonEncode(result));
    } catch (e, s) {
      log.error('Error when finding services', e, s);
      return Response.internalServerError(
        body: jsonEncode(
          {'message': 'Error when finding services'},
        ),
      );
    }
  }

  @Route.get('/user')
  Future<Response> checkUserExists(Request request) async {
    final email = request.url.queryParameters['email'];
    if (email == null) {
      return Response(
        400,
        body: jsonEncode(
          {'message': 'E-mail is required'},
        ),
      );
    }

    final emailExists = await service.checkUserEmailExists(email);
    return emailExists ? Response(200) : Response(204);
  }

  String _supplierMapper(Supplier supplier) {
    return jsonEncode({
      'id': supplier.id,
      'nome': supplier.name,
      'logo': supplier.logo,
      'endereco': supplier.address,
      'telefone': supplier.phone,
      'latitude': supplier.latitude,
      'longitude': supplier.longitude,
      'categoria': {
        'id': supplier.category?.id,
        'nome': supplier.category?.name,
        'tipo': supplier.category?.type,
      },
    });
  }

  Router get router => _$SupplierControllerRouter(this);
}
