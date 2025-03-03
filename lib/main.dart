import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'CodeNomad PDF Viewer',
    home: HomePage(),
  ));
}

/// Página inicial do visualizador de PDFs
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  static const platform = MethodChannel('pdf_reader_channel');
  String? _pdfPath;

  @override
  void initState() {
    super.initState();
    _handleIntent(); // Verifica se o app foi aberto via intent
  }

  /// Captura intents ao abrir o app via compartilhamento de arquivos
  Future<void> _handleIntent() async {
    if (Platform.isAndroid) {
      try {
        final String? path = await platform.invokeMethod('getPdfPathAndroid');
        if (path != null) {
          setState(() {
            _pdfPath = path;
          });
        }
      } catch (e) {
        debugPrint("Erro ao abrir PDF via intent: $e");
      }
    }

      if (Platform.isIOS) {
    try {
      final String? path = await platform.invokeMethod('getPdfPathIos');
      if (path != null) {
        setState(() {
          _pdfPath = path;
        });
      }
    } catch (e) {
      debugPrint("Erro ao abrir PDF via intent no iOS: $e");
    }
  }
  }

  /// Permite ao usuário selecionar um PDF manualmente
  Future<void> _pickPdfFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _pdfPath = result.files.single.path!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CodeNomad PDF Viewer', style: TextStyle(fontSize: 12),),
        actions: <Widget>[
          if (_pdfPath != null)
            IconButton(
              icon: const Icon(Icons.bookmark, color: Colors.white),
              onPressed: () {
                _pdfViewerKey.currentState?.openBookmarkView();
              },
            ),
          IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.white),
            onPressed: _pickPdfFile, // Botão para escolher um PDF manualmente
          ),
        ],
      ),
      body: _pdfPath == null
          ? Center(
              child: ElevatedButton(
                onPressed: _pickPdfFile,
                child: const Text('Selecionar um PDF'),
              ),
            )
          : SfPdfViewer.file(File(_pdfPath!), key: _pdfViewerKey),
    );
  }
}
