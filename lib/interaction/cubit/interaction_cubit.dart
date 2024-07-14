import 'package:bloc/bloc.dart';

class InteractionCubit extends Cubit<int> {
  InteractionCubit() : super(uniModalMode);

  static const int uniModalMode = 0;
  static const int translateMode = 1;
  static const int multiModalMode = 2;

  void setState(int mode) => emit(mode);
}
