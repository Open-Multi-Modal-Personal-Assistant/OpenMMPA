import 'package:bloc/bloc.dart';

class UtteranceCubit extends Cubit<int> {
  UtteranceCubit() : super(quickMode);

  static const int quickMode = 0;
  static const int thoroughMode = 0;
  static const int translateMode = 2;

  void setState(int mode) => emit(mode);
}
