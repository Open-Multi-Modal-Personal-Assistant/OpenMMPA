import 'package:bloc/bloc.dart';

class ImageCubit extends Cubit<String> {
  ImageCubit() : super('');

  void setPath(String imagePath) {
    emit(imagePath);
  }
}
