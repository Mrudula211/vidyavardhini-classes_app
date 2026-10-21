import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/promotion_repository.dart';

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  return PromotionRepository();
});

final currentAcademicYearProvider =
    FutureProvider.autoDispose<AcademicYearInfo?>((ref) {
  return ref.watch(promotionRepositoryProvider).fetchCurrentYear();
});
