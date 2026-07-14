import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import '../people/people_models.dart' show FieldUpdate;
import 'event_models.dart';
import 'events_provider.dart';

enum EditEventLoadStatus { loading, loaded, error }

enum EditEventSubmitStatus { idle, submitting, success, noChange, error }

enum EditEventCancelStatus { idle, cancelling, success, error }

/// The editable fields captured directly from the Edit form's own controls
/// — raw, not yet normalized. [startDate]/[endDate] must already be
/// fully-resolved local DateTimes (Date + Time combined by the picker
/// widgets), never a bare date or a bare time.
class EditEventFormValues {
  const EditEventFormValues({
    required this.title,
    required this.category,
    required this.description,
    required this.venue,
    required this.startDate,
    required this.endDate,
  });

  final String title;
  final String category;
  final String description;
  final String venue;
  final DateTime? startDate;
  final DateTime? endDate;
}

class EditEventState {
  const EditEventState({
    required this.loadStatus,
    required this.detail,
    required this.loadErrorMessage,
    required this.submitStatus,
    required this.submitErrorMessage,
    required this.cancelStatus,
    required this.cancelErrorMessage,
    required this.shouldClose,
  });

  factory EditEventState.initial() => const EditEventState(
    loadStatus: EditEventLoadStatus.loading,
    detail: null,
    loadErrorMessage: null,
    submitStatus: EditEventSubmitStatus.idle,
    submitErrorMessage: null,
    cancelStatus: EditEventCancelStatus.idle,
    cancelErrorMessage: null,
    shouldClose: false,
  );

  final EditEventLoadStatus loadStatus;

  /// The real, authoritative initial values this Edit session loaded
  /// independently via GET Detail — never List summary data, never
  /// route-passed state.
  final EventDetail? detail;
  final String? loadErrorMessage;
  final EditEventSubmitStatus submitStatus;
  final String? submitErrorMessage;
  final EditEventCancelStatus cancelStatus;
  final String? cancelErrorMessage;

  /// Mirrors EditPersonController/CreateFollowUpController's shouldClose
  /// exactly: set once the active organization stops matching the
  /// organization this Edit session opened for.
  final bool shouldClose;

  EditEventState copyWith({
    EditEventLoadStatus? loadStatus,
    EventDetail? Function()? detail,
    String? Function()? loadErrorMessage,
    EditEventSubmitStatus? submitStatus,
    String? Function()? submitErrorMessage,
    EditEventCancelStatus? cancelStatus,
    String? Function()? cancelErrorMessage,
    bool? shouldClose,
  }) {
    return EditEventState(
      loadStatus: loadStatus ?? this.loadStatus,
      detail: detail != null ? detail() : this.detail,
      loadErrorMessage: loadErrorMessage != null ? loadErrorMessage() : this.loadErrorMessage,
      submitStatus: submitStatus ?? this.submitStatus,
      submitErrorMessage: submitErrorMessage != null ? submitErrorMessage() : this.submitErrorMessage,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      cancelErrorMessage: cancelErrorMessage != null ? cancelErrorMessage() : this.cancelErrorMessage,
      shouldClose: shouldClose ?? this.shouldClose,
    );
  }
}

String? _normalizeNullableTrim(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Owns the Edit Event lifecycle for exactly one (eventId,
/// opening-organization) pair: an independent Event Detail load, a
/// changed-fields-only PATCH submit, and the Cancel Event action.
///
/// Organization pinning + stale-response protection mirrors
/// EditPersonController exactly, with two independent generation counters
/// ([_loadGeneration] guards the Detail load/retry, [_submitGeneration]
/// guards both PATCH submit and Cancel Event, since both mutate the same
/// loaded detail and must not race each other).
///
/// On a real successful PATCH or Cancel, this controller never constructs
/// or merges a local EventDetail: it invalidates the shared
/// eventDetailProvider(eventId) family instance, so Event Detail's own real
/// GET remains the sole displayed-Detail authority.
class EditEventController extends Notifier<EditEventState> {
  EditEventController(this.eventId);

  final String eventId;

  late final String openingOrganizationId;
  int _loadGeneration = 0;
  int _submitGeneration = 0;

  @override
  EditEventState build() {
    final organizationContext = ref.read(organizationContextControllerProvider);
    openingOrganizationId = organizationContext is OrganizationContextActive
        ? organizationContext.selectedOrganizationId
        : '';

    ref.listen(organizationContextControllerProvider, (previous, next) {
      final stillOpeningOrganization =
          next is OrganizationContextActive && next.selectedOrganizationId == openingOrganizationId;
      if (!stillOpeningOrganization) {
        _loadGeneration++;
        _submitGeneration++;
        state = state.copyWith(shouldClose: true);
      }
    });

    final generation = ++_loadGeneration;
    Future.microtask(() => _loadDetail(generation: generation));

    return EditEventState.initial();
  }

  bool _isLoadCurrent(int generation) {
    if (!ref.mounted || generation != _loadGeneration) return false;
    final organizationContext = ref.read(organizationContextControllerProvider);
    return organizationContext is OrganizationContextActive &&
        organizationContext.selectedOrganizationId == openingOrganizationId;
  }

  bool _isSubmitCurrent(int generation) {
    if (!ref.mounted || generation != _submitGeneration) return false;
    final organizationContext = ref.read(organizationContextControllerProvider);
    return organizationContext is OrganizationContextActive &&
        organizationContext.selectedOrganizationId == openingOrganizationId;
  }

  /// Explicit, testable invalidation for Cancel/back navigation.
  void closeSession() {
    _loadGeneration++;
    _submitGeneration++;
  }

  Future<void> retryLoad() async {
    if (openingOrganizationId.isEmpty) return;
    final generation = ++_loadGeneration;
    state = state.copyWith(loadStatus: EditEventLoadStatus.loading, loadErrorMessage: () => null);
    await _loadDetail(generation: generation);
  }

  Future<void> _loadDetail({required int generation}) async {
    if (openingOrganizationId.isEmpty) return;

    try {
      final detail = await ref
          .read(eventsApiProvider)
          .detail(organizationId: openingOrganizationId, eventId: eventId);

      if (!_isLoadCurrent(generation)) return;

      state = state.copyWith(loadStatus: EditEventLoadStatus.loaded, detail: () => detail, loadErrorMessage: () => null);
    } catch (error) {
      if (!_isLoadCurrent(generation)) return;
      state = state.copyWith(
        loadStatus: EditEventLoadStatus.error,
        detail: () => null,
        loadErrorMessage: () => error.toString(),
      );
    }
  }

  /// Returns true when [form] differs from the real loaded detail in any
  /// changed-field sense — drives the "Unsaved changes" indicator. Always
  /// false before the initial load completes.
  bool isDirty(EditEventFormValues form) {
    final initial = state.detail;
    if (initial == null) return false;
    return _diff(initial, form).hasAnyChange;
  }

  _EventFieldDiff _diff(EventDetail initial, EditEventFormValues form) {
    var title = const FieldUpdate<String>.omit();
    final normalizedTitle = form.title.trim();
    if (normalizedTitle != initial.title.trim()) {
      title = FieldUpdate.value(normalizedTitle);
    }

    var category = const FieldUpdate<String>.omit();
    final normalizedCategory = _normalizeNullableTrim(form.category);
    if (normalizedCategory != initial.category) {
      category = normalizedCategory == null ? const FieldUpdate.clear() : FieldUpdate.value(normalizedCategory);
    }

    var description = const FieldUpdate<String>.omit();
    final normalizedDescription = _normalizeNullableTrim(form.description);
    if (normalizedDescription != initial.description) {
      description = normalizedDescription == null
          ? const FieldUpdate.clear()
          : FieldUpdate.value(normalizedDescription);
    }

    var venue = const FieldUpdate<String>.omit();
    final normalizedVenue = _normalizeNullableTrim(form.venue);
    if (normalizedVenue != initial.venue) {
      venue = normalizedVenue == null ? const FieldUpdate.clear() : FieldUpdate.value(normalizedVenue);
    }

    var startDate = const FieldUpdate<DateTime>.omit();
    if (form.startDate != null && !form.startDate!.isAtSameMomentAs(initial.startDate)) {
      startDate = FieldUpdate.value(form.startDate!);
    }

    var endDate = const FieldUpdate<DateTime>.omit();
    final endDateChanged = form.endDate == null
        ? initial.endDate != null
        : !form.endDate!.isAtSameMomentAs(initial.endDate ?? DateTime.fromMillisecondsSinceEpoch(0));
    if (endDateChanged) {
      endDate = form.endDate == null ? const FieldUpdate.clear() : FieldUpdate.value(form.endDate!);
    }

    return _EventFieldDiff(
      title: title,
      category: category,
      description: description,
      venue: venue,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> submit(EditEventFormValues form) async {
    if (state.submitStatus == EditEventSubmitStatus.submitting) return;
    if (openingOrganizationId.isEmpty) return;

    final initial = state.detail;
    if (initial == null) return;

    final diff = _diff(initial, form);
    if (!diff.hasAnyChange) {
      state = state.copyWith(submitStatus: EditEventSubmitStatus.noChange);
      return;
    }

    final generation = ++_submitGeneration;
    state = state.copyWith(submitStatus: EditEventSubmitStatus.submitting, submitErrorMessage: () => null);

    try {
      await ref
          .read(eventsApiProvider)
          .update(
            organizationId: openingOrganizationId,
            eventId: eventId,
            title: diff.title,
            category: diff.category,
            description: diff.description,
            venue: diff.venue,
            startDate: diff.startDate,
            endDate: diff.endDate,
          );

      if (!_isSubmitCurrent(generation)) return;

      // The real GET Detail refresh remains the sole Event Detail
      // authority — invalidating forces the next watch to refetch.
      ref.invalidate(eventDetailProvider(eventId));

      final refreshed = await ref.read(eventsApiProvider).detail(organizationId: openingOrganizationId, eventId: eventId);
      if (!_isSubmitCurrent(generation)) return;

      state = state.copyWith(submitStatus: EditEventSubmitStatus.success, detail: () => refreshed);
    } catch (error) {
      if (!ref.mounted || generation != _submitGeneration) return;
      state = state.copyWith(submitStatus: EditEventSubmitStatus.error, submitErrorMessage: () => error.toString());
    }
  }

  /// Cancel Event: one-way. There is no restore/uncancel authority, so this
  /// never clears cancelledAt back to null. Idempotent on the backend — a
  /// repeat call simply returns the already-cancelled Event unchanged.
  Future<void> cancelEvent() async {
    if (state.cancelStatus == EditEventCancelStatus.cancelling) return;
    if (openingOrganizationId.isEmpty) return;

    final generation = ++_submitGeneration;
    state = state.copyWith(cancelStatus: EditEventCancelStatus.cancelling, cancelErrorMessage: () => null);

    try {
      final cancelled = await ref
          .read(eventsApiProvider)
          .cancel(organizationId: openingOrganizationId, eventId: eventId);

      if (!_isSubmitCurrent(generation)) return;

      ref.invalidate(eventDetailProvider(eventId));

      state = state.copyWith(cancelStatus: EditEventCancelStatus.success, detail: () => cancelled);
    } catch (error) {
      if (!ref.mounted || generation != _submitGeneration) return;
      state = state.copyWith(cancelStatus: EditEventCancelStatus.error, cancelErrorMessage: () => error.toString());
    }
  }
}

final editEventControllerProvider = NotifierProvider.family.autoDispose<
  EditEventController,
  EditEventState,
  String
>(EditEventController.new);

class _EventFieldDiff {
  const _EventFieldDiff({
    required this.title,
    required this.category,
    required this.description,
    required this.venue,
    required this.startDate,
    required this.endDate,
  });

  final FieldUpdate<String> title;
  final FieldUpdate<String> category;
  final FieldUpdate<String> description;
  final FieldUpdate<String> venue;
  final FieldUpdate<DateTime> startDate;
  final FieldUpdate<DateTime> endDate;

  bool get hasAnyChange =>
      title.isSet || category.isSet || description.isSet || venue.isSet || startDate.isSet || endDate.isSet;
}
