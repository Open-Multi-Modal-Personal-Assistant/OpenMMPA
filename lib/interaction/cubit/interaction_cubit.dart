import 'package:bloc/bloc.dart';

enum InteractionMode {
  uniModalMode,
  translateMode,
  multiModalMode,
}

class InteractionCubit extends Cubit<InteractionMode> {
  InteractionCubit() : super(InteractionMode.uniModalMode);

  void setState(InteractionMode mode) => emit(mode);
}
