// import 'dart:io';

// import 'package:dio/dio.dart';
// import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker_poc/bloc/web_view_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:plugin_liveness/plugin_liveness.dart';
import 'package:plugin_mrz/plugin_mrz.dart';
import 'package:plugin_nfc/plugin_nfc.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late InAppWebViewController webViewController;
  late final WebViewCubit webViewCubit;

  final pluginMrz = PluginMrz();
  final pluginNfc = PluginNfc();
  final pluginLiveness = PluginLiveness();

  String convertDate(String date) {
    // Asegurarse de que la fecha tiene el formato correcto de 6 dígitos (AAMMDD)
    if (date.length == 6) {
      // Extraer los componentes de la fecha
      String yearPrefix = (int.parse(date.substring(0, 2)) >= 50)
          ? '20'
          : '19'; // Si es >=50, asume 2000; si es <50, asume 1900
      String year = yearPrefix + date.substring(0, 2); // Año
      String month = date.substring(2, 4); // Mes
      String day = date.substring(4, 6); // Día

      // Devolver la fecha en formato AAAA-MM-DD
      return '$year-$month-$day';
    } else {
      return 'Fecha inválida';
    }
  }

  @override
  void initState() {
    super.initState();
    webViewCubit = WebViewCubit();
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    return MaterialApp(
      theme: ThemeData.dark(),
      home: BlocBuilder<WebViewCubit, WebViewState>(
          bloc: webViewCubit,
          builder: (context, state) {
            if (state.status == WebViewStatus.unloaded) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text("Asignar URL WebView"),
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "Ingresar la URL",
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            webViewCubit.loadUrl(_controller.text);
                          },
                          child: const Text("Asignar Url"),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Scaffold(
              appBar: AppBar(
                title: const Text("WebView"),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      webViewController.reload();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      webViewCubit.unload();
                    },
                  ),
                ],
              ),
              body: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: InAppWebView(
                        initialUrlRequest: URLRequest(
                          url:
                              // WebUri.uri(Uri.parse("http://192.168.1.98:5173")),
                              // WebUri.uri(
                              //     Uri.parse("http://192.168.20.26:5173")),
                              // WebUri.uri(Uri.parse(state.url!)),
                              // WebUri.uri(Uri.parse("https://mispruebas.space")),
                              WebUri.uri(Uri.parse(
                                  "https://ocr-qa.vinkel.co/bematch/passport")),
                          // WebUri.uri(Uri.parse("http://192.168.1.24:3000/passport")),
                          // WebUri.uri(Uri.parse("http://192.168.20.4:3000")),
                          // WebUri.uri(Uri.parse("https://ocr-qa.vinkel.co/w30/web_view/")),
                        ),
                        initialSettings: InAppWebViewSettings(
                          mediaPlaybackRequiresUserGesture: false,
                          allowsInlineMediaPlayback:
                              true, // Importante para iOS
                        ),
                        onPermissionRequest:
                            (controller, permissionRequest) async {
                          return PermissionResponse(
                              resources: permissionRequest.resources,
                              action: PermissionResponseAction.GRANT);
                        },
                        onWebViewCreated: (controller) {
                          webViewController = controller;
                          controller.addJavaScriptHandler(
                            handlerName: 'mrzHandler',
                            callback: (args) async {
                              Map<dynamic, dynamic>? mrzData =
                                  await pluginMrz.enableMRZ();
                              print("MRZ Data: $mrzData");
                              return mrzData;
                            },
                          );
                          controller.addJavaScriptHandler(
                            handlerName: 'logMessage',
                            callback: (args) async {
                              final Map<String, dynamic> data = args[0];
                              // mrzData!["dateOfBirth"] = convertDate(mrzData["dateOfBirth"]);
                              // mrzData["expirationDate"] =
                              //     convertDate(mrzData["expirationDate"]);
                              print(data);
                              print("Log Message: $data");
                              return "Ok";
                            },
                          );
                          controller.addJavaScriptHandler(
                            handlerName: 'nfcHandler',
                            callback: (args) async {
                              final Map<String, dynamic> datosIngreso = args[0];
                              print("Disparo la lectura de NFC");
                              print(datosIngreso);

                              try {
                                // assets/plugin_nfc_messages.json
                                // await pluginNfc.configureLenguage("es");

                                final data = await pluginNfc.enableNFC(
                                  datosIngreso["documentNumber"],
                                  datosIngreso["dateOfBirth"],
                                  datosIngreso["expirationDate"],
                                );
                                final bytesImage = data!["passportImageBytes"];
                                String base64Image = base64Encode(bytesImage);
                                data["base64Imagen"] = base64Image;

                                data?.remove("passportPhoto");
                                data["status"] = true;
                                return data;
                              } catch (e) {
                                return {
                                  "error": e.toString(),
                                  "status": false,
                                };
                              }
                            },
                          );
                          controller.addJavaScriptHandler(
                            handlerName: 'livenessHandler',
                            callback: (args) async {
                              final Map<String, dynamic> datosLiveness =
                                  args[0];
                              List<int> listImageBytes = List<int>.from(
                                  datosLiveness["passportImageBytes"]);

                              Uint8List bytesImage =
                                  Uint8List.fromList(listImageBytes);
                              print("Disparo Liveness");
                              print(datosLiveness);

                              // assets/plugin_liveness_messages.json
                              // await pluginLiveness.configureLenguage("es");

                              // Lottie de pantalla de carga
                              // assets/plugin_liveness_lottie_loading.json

                              //Parametros de liveness
                              // BytesImage
                              // LivenessMode
                              /// 0-default: Pasivo
                              /// 1: Activo
                              /// 2: None
                              /// 3: Custom
                              final livenessResponse =
                                  await pluginLiveness.verifyImage(
                                bytesImage,
                                datosLiveness["livenessMode"],
                              );

                              //Response =
                              /// capturedImage: UInt8List Bytes de la imagen
                              /// isVerified = Match con la persona del pasaporte true/false
                              /// succeededLiveness = Liveness Valido true/false

                              return livenessResponse;
                            },
                          );
                        },
                      ),
                    ),
                  ]),
            );
          }),
    );
  }
}
