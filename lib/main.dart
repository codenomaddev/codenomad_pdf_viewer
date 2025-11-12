import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Nomad PDF Viewer',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
    ),
    home: HomePage(),
  ));
}

/// Página inicial do visualizador de PDFs
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  static const platform = MethodChannel('pdf_reader_channel');

  String? _pdfPath;
  String? _pdfFileName;
  double _currentZoom = 1.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _handleIntent();
    _setupMethodCallHandler();
  }

  /// Configura o handler para receber notificações do Android/iOS
  void _setupMethodCallHandler() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onPdfReceived') {
        final String? path = call.arguments as String?;
        if (path != null) {
          _loadPdf(path);
        }
      }
    });
  }

  /// Captura intents ao abrir o app via compartilhamento de arquivos
  Future<void> _handleIntent() async {
    if (Platform.isAndroid) {
      try {
        final String? path = await platform.invokeMethod('getPdfPathAndroid');
        if (path != null) {
          _loadPdf(path);
        }
      } catch (e) {
        debugPrint("Erro ao abrir PDF via intent: $e");
      }
    }

    if (Platform.isIOS) {
      try {
        final String? path = await platform.invokeMethod('getPdfPathIos');
        if (path != null) {
          _loadPdf(path);
        }
      } catch (e) {
        debugPrint("Erro ao abrir PDF via intent no iOS: $e");
      }
    }
  }

  /// Carrega um PDF a partir de um caminho
  void _loadPdf(String pdfPath) {
    setState(() {
      _pdfPath = pdfPath;
      _pdfFileName = path.basename(pdfPath);
      _currentZoom = 1.0;
    });
  }

  /// Permite ao usuário selecionar um PDF manualmente
  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        _loadPdf(result.files.single.path!);
      }
    } catch (e) {
      debugPrint('Erro ao selecionar arquivo: $e');
      _showErrorSnackBar('Erro ao selecionar arquivo: $e');
    }
  }

  /// Compartilha o PDF atual
  Future<void> _sharePdf() async {
    if (_pdfPath == null) return;

    try {
      setState(() => _isLoading = true);

      // Compartilha o PDF usando XFile (funciona tanto para URIs de conteúdo quanto arquivos locais)
      await Share.shareXFiles(
        [XFile(_pdfPath!)],
        subject: _pdfFileName ?? 'PDF Document',
      );

      _showSuccessSnackBar('PDF compartilhado com sucesso!');
    } catch (e) {
      debugPrint('Erro ao compartilhar PDF: $e');
      _showErrorSnackBar('Erro ao compartilhar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Imprime o PDF atual
  Future<void> _printPdf() async {
    if (_pdfPath == null) return;

    try {
      setState(() => _isLoading = true);

      File pdfFile;

      // Se for uma URI de conteúdo, precisamos ler os bytes
      if (_pdfPath!.startsWith('content://')) {
        // Para URIs de conteúdo, precisamos copiar para um arquivo temporário
        final tempDir = await getTemporaryDirectory();
        final fileName = _pdfFileName ?? 'document.pdf';
        pdfFile = File('${tempDir.path}/$fileName');

        // Aqui seria necessário usar um canal nativo para ler a URI de conteúdo
        // Por simplicidade, vamos tentar ler diretamente
        _showErrorSnackBar('Impressão de URIs de conteúdo requer implementação adicional');
        return;
      } else {
        pdfFile = File(_pdfPath!);
      }

      final bytes = await pdfFile.readAsBytes();

      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
      );

      _showSuccessSnackBar('PDF enviado para impressão!');
    } catch (e) {
      debugPrint('Erro ao imprimir PDF: $e');
      _showErrorSnackBar('Erro ao imprimir: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Salva/exporta uma cópia do PDF
  Future<void> _savePdf() async {
    if (_pdfPath == null) return;

    debugPrint('=== Iniciando salvamento de PDF ===');
    debugPrint('Caminho do PDF: $_pdfPath');
    debugPrint('Nome do arquivo: $_pdfFileName');

    try {
      setState(() => _isLoading = true);

      // Primeiro, lê os bytes do arquivo
      Uint8List bytes;
      if (_pdfPath!.startsWith('content://')) {
        debugPrint('Lendo bytes de URI de conteúdo...');
        final xFile = XFile(_pdfPath!);
        bytes = await xFile.readAsBytes();
      } else {
        debugPrint('Lendo bytes de arquivo local...');
        final sourceFile = File(_pdfPath!);
        bytes = await sourceFile.readAsBytes();
      }
      debugPrint('Bytes lidos: ${bytes.length} bytes');

      // Agora chama saveFile com os bytes
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar PDF',
        fileName: _pdfFileName ?? 'document.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );

      if (outputPath != null) {
        debugPrint('PDF salvo com sucesso em: $outputPath');
        _showSuccessSnackBar('PDF salvo com sucesso!');
      } else {
        debugPrint('Usuário cancelou o salvamento');
      }
    } catch (e) {
      debugPrint('ERRO ao salvar PDF: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      _showErrorSnackBar('Erro ao salvar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Aumenta o zoom
  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 0.25).clamp(0.5, 4.0);
      _pdfViewerController.zoomLevel = _currentZoom;
    });
  }

  /// Diminui o zoom
  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 0.25).clamp(0.5, 4.0);
      _pdfViewerController.zoomLevel = _currentZoom;
    });
  }

  /// Reseta o zoom
  void _resetZoom() {
    setState(() {
      _currentZoom = 1.0;
      _pdfViewerController.zoomLevel = 1.0;
    });
  }

  /// Mostra uma mensagem de erro
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Mostra uma mensagem de sucesso
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Mostra o menu de opções
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartilhar'),
              onTap: () {
                Navigator.pop(context);
                _sharePdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Imprimir'),
              onTap: () {
                Navigator.pop(context);
                _printPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('Salvar como...'),
              onTap: () {
                Navigator.pop(context);
                _savePdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Marcadores'),
              onTap: () {
                Navigator.pop(context);
                _pdfViewerKey.currentState?.openBookmarkView();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pdfFileName ?? 'Nomad PDF Viewer',
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          if (_pdfPath != null) ...[
            // Botão de zoom out
            IconButton(
              icon: const Icon(Icons.zoom_out),
              tooltip: 'Diminuir zoom',
              onPressed: _zoomOut,
            ),
            // Indicador de zoom
            Center(
              child: GestureDetector(
                onTap: _resetZoom,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '${(_currentZoom * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Botão de zoom in
            IconButton(
              icon: const Icon(Icons.zoom_in),
              tooltip: 'Aumentar zoom',
              onPressed: _zoomIn,
            ),
            // Botão de menu de opções
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Mais opções',
              onPressed: _showOptionsMenu,
            ),
          ],
          // Botão para abrir arquivo
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Abrir PDF',
            onPressed: _pickPdfFile,
          ),
        ],
      ),
      body: Stack(
        children: [
          _pdfPath == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.picture_as_pdf,
                        size: 100,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Nenhum PDF selecionado',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _pickPdfFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Selecionar um PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'v1.1.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildPdfViewer(),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Constrói o visualizador de PDF
  Widget _buildPdfViewer() {
    try {
      // Se for uma URI de conteúdo (Android)
      if (_pdfPath!.startsWith('content://')) {
        return SfPdfViewer.file(
          File(_pdfPath!),
          key: _pdfViewerKey,
          controller: _pdfViewerController,
          onDocumentLoadFailed: (details) {
            debugPrint('Erro ao carregar PDF via URI de conteúdo: ${details.error}');
            debugPrint('Descrição: ${details.description}');
            _showErrorSnackBar('Erro ao carregar PDF: ${details.error}');
          },
        );
      } else {
        // Para arquivos locais normais
        return SfPdfViewer.file(
          File(_pdfPath!),
          key: _pdfViewerKey,
          controller: _pdfViewerController,
          onDocumentLoadFailed: (details) {
            debugPrint('Erro ao carregar PDF de arquivo local: ${details.error}');
            debugPrint('Descrição: ${details.description}');
            _showErrorSnackBar('Erro ao carregar PDF: ${details.error}');
          },
        );
      }
    } catch (e) {
      debugPrint('Exceção ao construir visualizador de PDF: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            Text('Erro ao carregar PDF:\n$e'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickPdfFile,
              child: const Text('Escolher outro arquivo'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }
}
