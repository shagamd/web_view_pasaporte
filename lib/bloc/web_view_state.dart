part of 'web_view_cubit.dart';

enum WebViewStatus { unloaded, loaded }

class WebViewState extends Equatable {
  final WebViewStatus status;
  final String? url;

  const WebViewState({
    this.status = WebViewStatus.unloaded,
    this.url,
  });

  WebViewState copyWith({
    WebViewStatus? status,
    String? url,
  }) {
    return WebViewState(
      status: status ?? this.status,
      url: url ?? this.url,
    );
  }

  @override
  List<Object?> get props => [
        status,
        url,
      ];
}
