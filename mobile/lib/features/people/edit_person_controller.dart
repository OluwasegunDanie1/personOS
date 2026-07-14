import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import 'people_models.dart';
import 'person_profile_controller.dart';

enum EditPersonLoadStatus { loading, loaded, error }

enum EditPersonSubmitStatus { idle, submitting, success, noChange, error }

/// The 8 PATCH-authorized fields as captured directly from the Edit form's
/// own controls — raw, not yet normalized. [dateOfBirth] is a date-only
/// value from a calendar-date picker (never a time component); [gender]
/// being null represents the form's explicit "Not specified" selection, not
/// an unanswered field (the form always has a definite gender selection:
/// Male, Female, or Not specified).
class EditPersonFormValues {
  const EditPersonFormValues({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.status,
    required this.gender,
    required this.dateOfBirth,
    required this.address,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final PersonStatus status;
  final PersonGender? gender;
  final DateTime? dateOfBirth;
  final String address;
}

class EditPersonState {
  const EditPersonState({
    required this.loadStatus,
    required this.detail,
    required this.loadErrorMessage,
    required this.submitStatus,
    required this.submitErrorMessage,
    required this.shouldClose,
  });

  factory EditPersonState.initial() => const EditPersonState(
    loadStatus: EditPersonLoadStatus.loading,
    detail: null,
    loadErrorMessage: null,
    submitStatus: EditPersonSubmitStatus.idle,
    submitErrorMessage: null,
    shouldClose: false,
  );

  final EditPersonLoadStatus loadStatus;

  /// The real, authoritative initial values this Edit session loaded
  /// independently via GET Detail — never People Directory summary data,
  /// never route-passed state, never a hardcoded default.
  final PersonDetail? detail;
  final String? loadErrorMessage;
  final EditPersonSubmitStatus submitStatus;
  final String? submitErrorMessage;

  /// Mirrors PersonProfileController/CreateFollowUpController/
  /// AddPersonController's shouldClose exactly: set once the active
  /// organization stops matching the organization this Edit session opened
  /// for. The screen must close (to /people) without acting on any
  /// in-flight load/submit result once this is true.
  final bool shouldClose;

  EditPersonState copyWith({
    EditPersonLoadStatus? loadStatus,
    PersonDetail? Function()? detail,
    String? Function()? loadErrorMessage,
    EditPersonSubmitStatus? submitStatus,
    String? Function()? submitErrorMessage,
    bool? shouldClose,
  }) {
    return EditPersonState(
      loadStatus: loadStatus ?? this.loadStatus,
      detail: detail != null ? detail() : this.detail,
      loadErrorMessage: loadErrorMessage != null ? loadErrorMessage() : this.loadErrorMessage,
      submitStatus: submitStatus ?? this.submitStatus,
      submitErrorMessage: submitErrorMessage != null ? submitErrorMessage() : this.submitErrorMessage,
      shouldClose: shouldClose ?? this.shouldClose,
    );
  }
}

String? _normalizeNullableTrim(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _normalizeEmail(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed.toLowerCase();
}

/// Owns the Edit Person lifecycle for exactly one (personId,
/// opening-organization) pair: an independent Person Detail load, plus a
/// changed-fields-only PATCH submit.
///
/// Organization pinning + stale-response protection mirrors
/// PersonProfileController/CreateFollowUpController exactly, but with two
/// independent generation counters (mirroring PersonProfileController's
/// separate `_generation`/`_followUpGeneration` split) since a load retry
/// and a submit are unrelated operations that must not invalidate one
/// another: [_loadGeneration] guards the Detail load/retry, [_submitGeneration]
/// guards the PATCH submit. Both are bumped together only by the
/// organization-switch listener, so switching organizations still
/// invalidates every in-flight request.
///
/// Authority Question 3's changed-fields-only strategy is implemented in
/// [submit]: every one of the 8 editable fields is normalized using
/// backend-compatible rules (trim firstName/lastName/address; nullable
/// email/phone/dateOfBirth/address compare as null when empty; dateOfBirth
/// compares as YYYY-MM-DD, never a DateTime instant; gender compares as
/// MALE/FEMALE/null; status compares as ACTIVE/INACTIVE) and compared
/// against the real loaded Person Detail. A field is only included in the
/// PATCH body when its normalized value differs; an unchanged nullable
/// field is never sent, and a field explicitly cleared to null is always
/// sent as JSON null (via [FieldUpdate.clear]), never conflated with
/// omission. If nothing changed, no PATCH is ever issued — [submitStatus]
/// becomes [EditPersonSubmitStatus.noChange] instead.
///
/// On a real successful PATCH, this controller never constructs or merges a
/// local PersonDetail: it calls the already-mounted
/// PersonProfileController's own [PersonProfileController.refreshDetail],
/// which performs the real GET Detail request that remains the sole
/// authority for Profile's displayed Detail.
class EditPersonController extends Notifier<EditPersonState> {
  EditPersonController(this.personId);

  final String personId;

  late final String openingOrganizationId;
  int _loadGeneration = 0;
  int _submitGeneration = 0;

  @override
  EditPersonState build() {
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

    return EditPersonState.initial();
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

  /// Explicit, testable invalidation for Cancel/back.
  void cancel() {
    _loadGeneration++;
    _submitGeneration++;
  }

  Future<void> retryLoad() async {
    if (openingOrganizationId.isEmpty) return;
    final generation = ++_loadGeneration;
    state = state.copyWith(loadStatus: EditPersonLoadStatus.loading, loadErrorMessage: () => null);
    await _loadDetail(generation: generation);
  }

  Future<void> _loadDetail({required int generation}) async {
    if (openingOrganizationId.isEmpty) return;

    try {
      final detail = await ref
          .read(peopleApiProvider)
          .detail(organizationId: openingOrganizationId, personId: personId);

      if (!_isLoadCurrent(generation)) return;

      state = state.copyWith(
        loadStatus: EditPersonLoadStatus.loaded,
        detail: () => detail,
        loadErrorMessage: () => null,
      );
    } catch (error) {
      if (!_isLoadCurrent(generation)) return;
      state = state.copyWith(
        loadStatus: EditPersonLoadStatus.error,
        detail: () => null,
        loadErrorMessage: () => error.toString(),
      );
    }
  }

  Future<void> submit(EditPersonFormValues form) async {
    if (state.submitStatus == EditPersonSubmitStatus.submitting) return;
    if (openingOrganizationId.isEmpty) return;

    final initial = state.detail;
    if (initial == null) return;

    final normalizedFirstName = form.firstName.trim();
    final normalizedLastName = form.lastName.trim();
    final normalizedEmail = _normalizeEmail(form.email);
    final normalizedPhone = _normalizeNullableTrim(form.phone);
    final normalizedAddress = _normalizeNullableTrim(form.address);
    final normalizedDateOfBirth = form.dateOfBirth != null ? formatDateOnly(form.dateOfBirth!) : null;
    final initialDateOfBirth = initial.dateOfBirth != null ? formatDateOnly(initial.dateOfBirth!) : null;

    var firstName = const FieldUpdate<String>.omit();
    if (normalizedFirstName != initial.firstName.trim()) {
      firstName = FieldUpdate.value(normalizedFirstName);
    }

    var lastName = const FieldUpdate<String>.omit();
    if (normalizedLastName != initial.lastName.trim()) {
      lastName = FieldUpdate.value(normalizedLastName);
    }

    var email = const FieldUpdate<String>.omit();
    if (normalizedEmail != initial.email) {
      email = normalizedEmail == null ? const FieldUpdate.clear() : FieldUpdate.value(normalizedEmail);
    }

    var phone = const FieldUpdate<String>.omit();
    if (normalizedPhone != initial.phone) {
      phone = normalizedPhone == null ? const FieldUpdate.clear() : FieldUpdate.value(normalizedPhone);
    }

    var status = const FieldUpdate<PersonStatus>.omit();
    if (form.status != initial.status) {
      status = FieldUpdate.value(form.status);
    }

    var gender = const FieldUpdate<PersonGender>.omit();
    if (form.gender != initial.gender) {
      gender = form.gender == null ? const FieldUpdate.clear() : FieldUpdate.value(form.gender!);
    }

    var dateOfBirth = const FieldUpdate<String>.omit();
    if (normalizedDateOfBirth != initialDateOfBirth) {
      dateOfBirth = normalizedDateOfBirth == null
          ? const FieldUpdate.clear()
          : FieldUpdate.value(normalizedDateOfBirth);
    }

    var address = const FieldUpdate<String>.omit();
    if (normalizedAddress != initial.address) {
      address = normalizedAddress == null ? const FieldUpdate.clear() : FieldUpdate.value(normalizedAddress);
    }

    final hasAnyChange =
        firstName.isSet ||
        lastName.isSet ||
        email.isSet ||
        phone.isSet ||
        status.isSet ||
        gender.isSet ||
        dateOfBirth.isSet ||
        address.isSet;

    if (!hasAnyChange) {
      // Truthful no-change behavior (Product Task 047): no PATCH is ever
      // issued, and this is not conflated with a real success.
      state = state.copyWith(submitStatus: EditPersonSubmitStatus.noChange);
      return;
    }

    final generation = ++_submitGeneration;
    state = state.copyWith(submitStatus: EditPersonSubmitStatus.submitting, submitErrorMessage: () => null);

    try {
      await ref
          .read(peopleApiProvider)
          .update(
            organizationId: openingOrganizationId,
            personId: personId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            status: status,
            gender: gender,
            dateOfBirth: dateOfBirth,
            address: address,
          );

      if (!_isSubmitCurrent(generation)) return;

      // The real GET Detail refresh remains the sole Profile Detail
      // authority — the PATCH summary response above is validated but never
      // merged/fabricated into a PersonDetail.
      await ref.read(personProfileControllerProvider(personId).notifier).refreshDetail();

      if (!_isSubmitCurrent(generation)) return;

      state = state.copyWith(submitStatus: EditPersonSubmitStatus.success);
    } catch (error) {
      if (!ref.mounted || generation != _submitGeneration) return;
      state = state.copyWith(submitStatus: EditPersonSubmitStatus.error, submitErrorMessage: () => error.toString());
    }
  }
}

final editPersonControllerProvider = NotifierProvider.family.autoDispose<
  EditPersonController,
  EditPersonState,
  String
>(EditPersonController.new);
