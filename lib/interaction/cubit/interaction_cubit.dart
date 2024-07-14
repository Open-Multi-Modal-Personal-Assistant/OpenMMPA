import 'package:bloc/bloc.dart';

class InteractionCubit extends Cubit<int> {
  InteractionCubit() : super(quickMode);

  static const int quickMode = 0;
  static const int thoroughMode = 1;
  static const int translateMode = 2;

  void setState(int mode) => emit(mode);
}
