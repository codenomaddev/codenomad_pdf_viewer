# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [1.1.0] - 2025-11-11

### Adicionado
- Logging detalhado com debugPrint em todos os pontos de erro para facilitar debug
- Flag --verbose nas configurações de debug do VS Code
- Ícones personalizados para Android e iOS

### Corrigido
- Erro "Bytes are required" ao salvar PDF - agora usa Uint8List corretamente
- Função de salvar PDF agora funciona tanto para URIs de conteúdo quanto arquivos locais
- Problemas de build do Gradle devido a versões desatualizadas
- Avisos do linter (library_private_types_in_public_api)
- Configuração do flutter_lints que não estava sendo encontrada

### Alterado
- Nome do app de "codenomad_pdf_reader" para "Nomad Pdf Viewer"
- Gradle atualizado de 8.3.0 para 8.7.0
- Android Gradle Plugin atualizado de 8.1.0 para 8.6.0
- Kotlin atualizado de 1.8.22 para 2.1.0
- flutter_lints atualizado de 5.0.0 para 6.0.0
- Configurações de memória do Gradle otimizadas (Xmx2048M, MaxMetaspaceSize=512M)
- Desabilitado Jetifier para reduzir consumo de memória

## [1.0.0] - 2025-11-11

### Adicionado
- Visualização de PDFs com zoom e navegação
- Abertura de arquivos PDF do dispositivo
- Compartilhamento de PDFs
- Impressão de PDFs
- Salvamento de cópias de PDFs
- Suporte para abrir PDFs de outros apps via intent
- Marcadores (bookmarks) para PDFs
- Interface Material Design 3
- Suporte para Android e iOS
