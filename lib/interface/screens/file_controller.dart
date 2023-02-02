import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';

final directoryLoadingProvider = StateProvider<bool>((ref) {
  return true;
});

final directoryProvider =
    StateNotifierProvider<DirectoryNotifier, String>((ref) {
  return DirectoryNotifier(ref);
});

class DirectoryNotifier extends StateNotifier<String> {
  DirectoryNotifier(this.ref) : super('') {
    getBaseDirectory();
  }

  final Ref ref;

  getDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      state = path;
    }
  }

  getBaseDirectory() async {
    ref.read(directoryLoadingProvider.notifier).state = true;
    final path = await getApplicationDocumentsDirectory();
    ref.read(directoryLoadingProvider.notifier).state = false;
    state = path.path;
  }

  setDirectory(String path) {
    state = path;
  }
}

final filesProvider = Provider<List<FileSystemEntity>>((ref) {
  final directory = ref.watch(directoryProvider);
  final files = Directory(directory).listSync();
  return files;
});

final imagesProvider = Provider<List<FileSystemEntity>>((ref) {
  final files = ref.watch(filesProvider);
  return files.where((element) {
    final path = element.path.split('.');
    final isFile = path.isNotEmpty && path.length > 1;
    final isImage = isFile && imageTypes.contains(path.last);
    return isImage;
  }).toList();
});

final destinyDirectory =
    StateNotifierProvider<DirectoryNotifier, String>((ref) {
  return DirectoryNotifier(ref);
});

final widthProvider = StateProvider<int?>((ref) {
  return 600;
});

final heightProvider = StateProvider<int?>((ref) {
  return null;
});

final generationProvider =
    StateNotifierProvider<GenerationNotifier, double>((ref) {
  return GenerationNotifier(ref);
});

class GenerationNotifier extends StateNotifier<double> {
  GenerationNotifier(this.ref) : super(0);

  final Ref ref;

  generate() async {
    final images = ref.read(imagesProvider);
    final width = ref.read(widthProvider);
    final height = ref.read(heightProvider);
    final destity = ref.read(destinyDirectory);
    for (int index = 1; index <= images.length; index++) {
      state = index * 100 / images.length / 100;
      final file = images[index - 1];
      log(file.path);
      try {
        final cmd = Command();
        final fileName = file.path.split('\\').last;
        cmd.decodeImageFile(file.path);
        cmd.copyResize(
          height: height,
          width: width,
          interpolation: Interpolation.cubic,
        );
        cmd.writeToFile('$destity\\$fileName');
        await cmd.executeThread();
      } catch (e) {
        log('Imagem não convertida: ${file.path}');
      }
    }
  }
}
