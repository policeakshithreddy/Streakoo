import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

/// Voice note model
class VoiceNote {
  final String id;
  final String habitId;
  final String filePath;
  final DateTime createdAt;
  final Duration duration;
  final String? transcript;

  const VoiceNote({
    required this.id,
    required this.habitId,
    required this.filePath,
    required this.createdAt,
    required this.duration,
    this.transcript,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'habitId': habitId,
        'filePath': filePath,
        'createdAt': createdAt.toIso8601String(),
        'duration': duration.inMilliseconds,
        'transcript': transcript,
      };

  factory VoiceNote.fromJson(Map<String, dynamic> json) => VoiceNote(
        id: json['id'] as String,
        habitId: json['habitId'] as String,
        filePath: json['filePath'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        duration: Duration(milliseconds: json['duration'] as int),
        transcript: json['transcript'] as String?,
      );
}

/// Widget for recording voice notes
class VoiceNoteRecorder extends StatefulWidget {
  final String habitId;
  final Function(VoiceNote)? onRecorded;

  const VoiceNoteRecorder({
    super.key,
    required this.habitId,
    this.onRecorded,
  });

  @override
  State<VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<VoiceNoteRecorder>
    with SingleTickerProviderStateMixin {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  String? _recordingPath;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    _durationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        _showPermissionDenied();
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/voice_notes/${widget.habitId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Create directory if needed
      await Directory('${dir.path}/voice_notes').create(recursive: true);

      await _recorder.start(const RecordConfig(), path: path);

      HapticFeedback.mediumImpact();
      _pulseController.repeat(reverse: true);

      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _recordingDuration = Duration.zero;
      });

      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _showError('Could not start recording');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _durationTimer?.cancel();
      _pulseController.stop();

      final path = await _recorder.stop();

      if (path != null && _recordingPath != null) {
        HapticFeedback.heavyImpact();

        final voiceNote = VoiceNote(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          habitId: widget.habitId,
          filePath: _recordingPath!,
          createdAt: DateTime.now(),
          duration: _recordingDuration,
        );

        widget.onRecorded?.call(voiceNote);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice note saved!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      }

      setState(() {
        _isRecording = false;
        _recordingPath = null;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _showError('Could not save recording');
    }
  }

  void _showPermissionDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Microphone permission required'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isRecording
            ? const Color(0xFFE91E63).withValues(alpha: 0.1)
            : (isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isRecording
              ? const Color(0xFFE91E63)
              : (isDark ? Colors.white12 : Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Recording indicator
          Row(
            children: [
              // Animated recording dot
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? Color.lerp(
                              Colors.red,
                              Colors.red.withValues(alpha: 0.3),
                              _pulseController.value,
                            )
                          : Colors.grey,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isRecording
                      ? _formatDuration(_recordingDuration)
                      : 'Record a voice note',
                  style: TextStyle(
                    fontWeight: _isRecording ? FontWeight.bold : null,
                    color: _isRecording ? const Color(0xFFE91E63) : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Record button
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isRecording ? 70 : 60,
              height: _isRecording ? 70 : 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isRecording
                      ? [const Color(0xFFE91E63), const Color(0xFFFF5252)]
                      : [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary
                        ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording
                            ? const Color(0xFFE91E63)
                            : theme.colorScheme.primary)
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: _isRecording ? 36 : 28,
              ),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            _isRecording ? 'Tap to stop' : 'Tap to record',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Widget to play a voice note
class VoiceNotePlayer extends StatefulWidget {
  final VoiceNote voiceNote;
  final VoidCallback? onDelete;

  const VoiceNotePlayer({
    super.key,
    required this.voiceNote,
    this.onDelete,
  });

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    HapticFeedback.selectionClick();
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(widget.voiceNote.filePath));
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = widget.voiceNote.duration.inMilliseconds > 0
        ? _position.inMilliseconds / widget.voiceNote.duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Progress bar and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[300],
                    valueColor:
                        AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 4),
                // Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      _formatDuration(widget.voiceNote.duration),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          if (widget.onDelete != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 20,
              ),
              onPressed: widget.onDelete,
            ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
