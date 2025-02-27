
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'web_view_state.dart';

class WebViewCubit extends Cubit<WebViewState> {
  WebViewCubit() : super(const WebViewState());

  void loadUrl(String url) {
    if(url.isEmpty) {
      return;
    }
    emit(state.copyWith(
      status: WebViewStatus.loaded,
      url: url,
    ));
  }

  void unload() {
    emit(const WebViewState());
  }
}