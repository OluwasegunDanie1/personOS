import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../organizations/organization_context_controller.dart';
import 'people_models.dart';
import 'people_state_controller.dart';

enum AddPersonSubmitStatus { idle, submitting, success, error }

class AddPersonState {
  const AddPersonState({required this.status, required this.errorMessage, required this.shouldClose});

  factory AddPersonState.idle() =>
      const AddPersonState(status: AddPersonSubmitStatus.idle, errorMessage: null, shouldClose: false);

  final AddPersonSubmitStatus status;
  final String? errorMessage;

  /// Set when the active organization changed away from the organization
  /// this form was opened for. The screen must pop without showing any
  /// success/error UI when this becomes true.
  final bool shouldClose;

  AddPersonState copyWith({AddPersonSubmitStatus? status, String? Function()? errorMessage, bool? shouldClose}) {
    return AddPersonState(
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      shouldClose: shouldClose ?? this.shouldClose,
    );
  }
}

/// Owns the Add Person submit lifecycle for exactly one screen instance.
///
/// Organization pinning: the opening organization is captured once (via
/// ref.read, not ref.watch) the first time this Notifier builds. A
/// ref.listen on organizationContextControllerProvider then watches for
/// changes *after* opening — if the active organization stops being the
/// opening organization, the current submit generation is invalidated and
/// [AddPersonState.shouldClose] is set so the screen can pop safely.
///
/// Stale-response protection: every submit captures a generation counter.
/// A response is only applied (directory refresh + success state) if
/// ref.mounted is still true, the generation is still current, and the
/// active organization is still the opening organization — checked once
/// right after the POST resolves and again after the directory refresh
/// completes, matching the required success-flow ordering.
class AddPersonController extends Notifier<AddPersonState> {
  late final String openingOrganizationId;
  int _generation = 0;

  @override
  AddPersonState build() {
    final organizationContext = ref.read(organizationContextControllerProvider);
    openingOrganizationId = organizationContext is OrganizationContextActive
        ? organizationContext.selectedOrganizationId
        : '';

    ref.listen(organizationContextControllerProvider, (previous, next) {
      final stillOpeningOrganization =
          next is OrganizationContextActive && next.selectedOrganizationId == openingOrganizationId;
      if (!stillOpeningOrganization) {
        _generation++;
        state = state.copyWith(shouldClose: true);
      }
    });

    return AddPersonState.idle();
  }

  /// Explicit, testable invalidation for Cancel/back — any in-flight
  /// submit's eventual response becomes a no-op once this is called.
  void cancel() {
    _generation++;
  }

  bool _isCurrent(int generation) {
    if (!ref.mounted || generation != _generation) return false;
    final organizationContext = ref.read(organizationContextControllerProvider);
    return organizationContext is OrganizationContextActive &&
        organizationContext.selectedOrganizationId == openingOrganizationId;
  }

  Future<void> submit({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required PersonStatus status,
    PersonGender? gender,
    DateTime? dateOfBirth,
    String? address,
  }) async {
    if (state.status == AddPersonSubmitStatus.submitting) return;
    if (openingOrganizationId.isEmpty) return;

    final generation = ++_generation;
    state = state.copyWith(status: AddPersonSubmitStatus.submitting, errorMessage: () => null);

    try {
      await ref.read(peopleApiProvider).create(
        organizationId: openingOrganizationId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        status: status,
        gender: gender,
        dateOfBirth: dateOfBirth,
        address: address,
      );

      if (!_isCurrent(generation)) return;

      await ref.read(peopleDirectoryControllerProvider.notifier).refresh();

      if (!_isCurrent(generation)) return;

      state = state.copyWith(status: AddPersonSubmitStatus.success);
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(status: AddPersonSubmitStatus.error, errorMessage: () => error.toString());
    }
  }
}

final addPersonControllerProvider = NotifierProvider.autoDispose<AddPersonController, AddPersonState>(
  AddPersonController.new,
);
