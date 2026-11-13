import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum VocabularyPlaybackState { idle, loading, playing }

abstract interface class VocabularyPronunciationService {
  Stream<VocabularyPlaybackState> get playbackStates;

  Future<void> pronounce({
    required String word,
    required String languageCode,
    String? audioAsset,
  });

  Future<void> stop();

  Future<void> dispose();
}

class DeviceVocabularyPronunciationService
    implements VocabularyPronunciationService {
  DeviceVocabularyPronunciationService()
    : _audioPlayer = AudioPlayer(),
      _textToSpeech = FlutterTts() {
    _audioStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        _emit(VocabularyPlaybackState.playing);
      } else if (state == PlayerState.stopped ||
          state == PlayerState.completed ||
          state == PlayerState.paused) {
        _emit(VocabularyPlaybackState.idle);
      }
    });
    _audioCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      _emit(VocabularyPlaybackState.idle);
    });
    _textToSpeech
      ..setStartHandler(() => _emit(VocabularyPlaybackState.playing))
      ..setCompletionHandler(() => _emit(VocabularyPlaybackState.idle))
      ..setCancelHandler(() => _emit(VocabularyPlaybackState.idle))
      ..setErrorHandler((_) => _emit(VocabularyPlaybackState.idle));
  }

  final AudioPlayer _audioPlayer;
  final FlutterTts _textToSpeech;
  final StreamController<VocabularyPlaybackState> _stateController =
      StreamController<VocabularyPlaybackState>.broadcast();
  late final StreamSubscription<PlayerState> _audioStateSubscription;
  late final StreamSubscription<void> _audioCompleteSubscription;
  bool _isDisposed = false;

  @override
  Stream<VocabularyPlaybackState> get playbackStates => _stateController.stream;

  void _emit(VocabularyPlaybackState state) {
    if (!_isDisposed && !_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  @override
  Future<void> pronounce({
    required String word,
    required String languageCode,
    String? audioAsset,
  }) async {
    final trimmedWord = word.trim();
    if (trimmedWord.isEmpty) {
      throw ArgumentError.value(word, 'word', 'Pronunciation cannot be empty.');
    }

    await _stopOutput();
    _emit(VocabularyPlaybackState.loading);

    if (audioAsset != null && audioAsset.trim().isNotEmpty) {
      try {
        await _audioPlayer.play(AssetSource(_assetSource(audioAsset)));
        return;
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'vocabulary pronunciation',
            context: ErrorDescription(
              'while playing recorded pronunciation "$audioAsset"',
            ),
          ),
        );
      }
    }

    await _speak(trimmedWord, languageCode);
  }

  String _assetSource(String assetPath) {
    const assetPrefix = 'assets/';
    return assetPath.startsWith(assetPrefix)
        ? assetPath.substring(assetPrefix.length)
        : assetPath;
  }

  Future<void> _speak(String word, String languageCode) async {
    final locales = switch (languageCode) {
      'en' => const ['en-US', 'en-PH'],
      'tl' => const ['fil-PH', 'tl-PH', 'en-US'],
      _ => const ['fil-PH', 'tl-PH', 'en-US'],
    };

    String? selectedLocale;
    Object? availabilityError;
    for (final locale in locales) {
      try {
        final availability = await _textToSpeech.isLanguageAvailable(locale);
        if (availability == true || availability == 1) {
          selectedLocale = locale;
          break;
        }
      } catch (error) {
        availabilityError = error;
      }
    }
    if (selectedLocale == null) {
      throw StateError(
        availabilityError == null
            ? 'No installed speech voice supports ${locales.take(2).join(' or ')}.'
            : 'Could not find an installed speech voice: $availabilityError',
      );
    }

    await _textToSpeech.setLanguage(selectedLocale);
    await _textToSpeech.setSpeechRate(0.45);
    await _textToSpeech.awaitSpeakCompletion(true);
    await _textToSpeech.speak(word);
    _emit(VocabularyPlaybackState.idle);
  }

  @override
  Future<void> stop() async {
    await _stopOutput();
    _emit(VocabularyPlaybackState.idle);
  }

  Future<void> _stopOutput() async {
    await _audioPlayer.stop();
    await _textToSpeech.stop();
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _textToSpeech.stop();
    await _audioStateSubscription.cancel();
    await _audioCompleteSubscription.cancel();
    await _audioPlayer.dispose();
    await _stateController.close();
  }
}
