import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';

String localizeReservationError(
  AppLocalizations strings,
  Object error, {
  Map<String, String> overrides = const {},
}) {
  return localizeAuthError(
    strings,
    error,
    overrides: {
      'peopleCount 必须大于 0': strings.reservationErrorInvalidPeopleCount,
      'slotId 与 reserveTime 至少传一个': strings.reservationErrorSlotOrTimeRequired,
      '当前时段余量不足': strings.reservationErrorSlotCapacityUnavailable,
      '已超过允许取消时间': strings.reservationErrorCancelDeadlinePassed,
      '预订当前不可取消': strings.reservationErrorCancelUnavailable,
      '新时段余量不足': strings.reservationErrorRescheduleSlotCapacityUnavailable,
      '预订当前不可改期': strings.reservationErrorRescheduleUnavailable,
      '预订时段不存在': strings.reservationErrorSlotNotFound,
      '预订不存在': strings.reservationErrorNotFound,
      ...overrides,
    },
  );
}
