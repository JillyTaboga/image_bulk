import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../core/constants.dart';
import 'file_controller.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directory = ref.watch(directoryProvider);
    final destiny = ref.watch(destinyDirectory);
    final destinyController = ref.watch(destinyDirectory.notifier);
    final images = ref.watch(imagesProvider);
    final directoryController = ref.watch(directoryProvider.notifier);
    return NavigationView(
      appBar: const NavigationAppBar(
        title: Text('ImageBulk'),
        automaticallyImplyLeading: false,
      ),
      paneBodyBuilder: (body) {
        return const CenterWidget();
      },
      pane: NavigationPane(
        displayMode: PaneDisplayMode.open,
        items: [
          PaneItemHeader(
            header: const Text('Pasta de Origem'),
          ),
          PaneItemAction(
            icon: const Icon(FluentIcons.folder),
            title: Text(directory),
            onTap: () {
              directoryController.getDirectory();
            },
          ),
          PaneItemHeader(
            header: const Text('Pasta de Destino'),
          ),
          PaneItemAction(
            icon: const Icon(FluentIcons.folder),
            title: Text(destiny),
            onTap: () {
              destinyController.getDirectory();
            },
          ),
          PaneItemHeader(header: Text('Total de imagens: ${images.length}')),
          PaneItemHeader(
            header: Builder(builder: (context) {
              return SizeWidget(
                label: 'Largura:',
                provider: widthProvider,
              );
            }),
          ),
          PaneItemHeader(
            header: SizeWidget(
              label: 'Altura:',
              provider: heightProvider,
            ),
          ),
          PaneItemHeader(
            header: const GenerationWidget(),
          ),
        ],
      ),
    );
  }
}

class CenterWidget extends HookConsumerWidget {
  const CenterWidget({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directoryLoading = ref.watch(directoryLoadingProvider);
    final files = ref.watch(filesProvider);
    final directoryController = ref.watch(directoryProvider.notifier);
    return directoryLoading
        ? const Center(
            child: ProgressRing(),
          )
        : GridView.builder(
            itemCount: files.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemBuilder: (context, index) {
              final file = files[index];
              return FileWidget(
                file: file,
                onTapDirectory: () {
                  directoryController.setDirectory(file.path);
                },
              );
            },
          );
  }
}

class GenerationWidget extends HookConsumerWidget {
  const GenerationWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, ref) {
    final generationProgress = ref.watch(generationProvider);
    final generationController = ref.watch(generationProvider.notifier);
    final destiny = ref.watch(destinyDirectory);
    return Column(
      children: [
        FilledButton(
          onPressed: (generationProgress == 0 || generationProgress == 1)
              ? () async {
                  generationController.generate();
                }
              : null,
          child: const Text('Gerar'),
        ),
        if (generationProgress > 0)
          ProgressBar(
            value: generationProgress * 100,
          ),
        if (generationProgress == 1)
          TextButton(
            child: const Text('Todos arquivos gerados'),
            onPressed: () {
              launchUrlString(destiny);
            },
          ),
      ],
    );
  }
}

class SizeWidget extends HookConsumerWidget {
  const SizeWidget({
    super.key,
    required this.provider,
    required this.label,
  });

  final StateProvider<int?> provider;
  final String label;

  @override
  Widget build(BuildContext context, ref) {
    final value = ref.watch(provider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ToggleSwitch(
          checked: value != null,
          onChanged: (value) {
            ref.read(provider.notifier).state = value ? 600 : null;
          },
        ),
        if (value != null)
          Expanded(
            child: TextFormBox(
              header: label,
              initialValue: NumberFormat.decimalPattern().format(value),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                try {
                  final number = int.parse(value);
                  ref.read(provider.notifier).state = number;
                } catch (e) {
                  ref.read(provider.notifier).state = 0;
                }
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                try {
                  int.parse(value ?? '');
                  return null;
                } catch (e) {
                  return 'Digite um valor válido';
                }
              },
            ),
          ),
      ],
    );
  }
}

class FileWidget extends StatelessWidget {
  const FileWidget({
    super.key,
    required this.file,
    this.onTapDirectory,
  });

  final FileSystemEntity file;
  final void Function()? onTapDirectory;

  @override
  Widget build(BuildContext context) {
    final path = file.path.split('.');
    final isFile = path.isNotEmpty && path.length > 1;
    final isImage = isFile && imageTypes.contains(path.last);
    if (isImage) {
      return Column(
        children: [
          Expanded(
            child: Image.file(
              File(file.path),
              fit: BoxFit.contain,
              width: double.maxFinite,
              height: double.maxFinite,
            ),
          ),
          Text(
            file.path,
            style: const TextStyle(fontSize: 8),
          ),
        ],
      );
    }
    if (isFile) {
      return Card(
        child: Center(
          child: Text(file.path),
        ),
      );
    }
    return LayoutBuilder(builder: (context, constaints) {
      return HoverButton(
        onTapDown: onTapDirectory,
        builder: (p0, state) {
          return Stack(
            children: [
              Icon(
                FluentIcons.folder_fill,
                size: constaints.maxWidth,
                color: state.contains(ButtonStates.hovering)
                    ? FluentTheme.of(context).accentColor
                    : Colors.yellow.darkest,
              ),
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    file.path,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}
