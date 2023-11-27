import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({
    required this.player,
    this.title = '',
    this.colorButton,
    this.activePlayerColor,
    this.inactivePlayerColor,
    this.activeVolumeColor,
    this.inactiveVolumeColor,
    super.key,
  });

  final AudioPlayer player;
  final String title;
  final Color? colorButton;
  final Color? activePlayerColor;
  final Color? inactivePlayerColor;
  final Color? activeVolumeColor;
  final Color? inactiveVolumeColor;

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  PlayerState? _playerState;
  late final Source _source;

  Duration? _duration;
  Duration? _position;

  double currentVolume = 1;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get _isPlaying => _playerState == PlayerState.playing;
  String get _durationText => getDurationString(_duration);
  String get _positionText => getDurationString(_position);
  AudioPlayer get player => widget.player;

  @override
  void initState() {
    super.initState();
    _source = player.source ?? UrlSource('');
    _playerState = player.state;
    player.getDuration().then(
          (value) => setState(() {
            _duration = value;
          }),
        );
    player.getCurrentPosition().then(
          (value) => setState(() {
            _position = value;
          }),
        );
    _initStreams();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  String getDurationString(Duration? value) {
    String durationToString = '';

    if (value == Duration.zero || value == null) {
      durationToString == '00:00';
    } else {
      if (value.inHours > 0 && value.inHours < 10) {
        durationToString = '${durationToString}0${value.inHours}:';
      } else if (value.inHours >= 10) {
        durationToString = '$durationToString${value.inHours}:';
      }
      if (value.inMinutes < 10) {
        durationToString = '${durationToString}0${value.inMinutes}:';
      } else {
        durationToString = '$durationToString${value.inMinutes}:';
      }
      if (value.inSeconds < 10) {
        durationToString = '${durationToString}0${value.inSeconds}';
      } else {
        durationToString = '$durationToString${value.inSeconds}';
      }
    }

    return durationToString;
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    widget.player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Stack(
      children: [
        (_isPlaying)
            ? InkWell(
                key: const Key('pause_button'),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: _pause,
                child: Icon(
                  Icons.pause,
                  size: 48.0,
                  opticalSize: 48.0,
                  color: widget.colorButton ?? color,
                ),
              )
            : InkWell(
                key: const Key('play_button'),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: _play,
                child: Icon(
                  Icons.play_arrow,
                  size: 48.0,
                  opticalSize: 48.0,
                  color: widget.colorButton ?? color,
                ),
              ),
        Padding(
          padding: const EdgeInsets.only(left: 36, right: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24, right: 12),
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Text(
                      '$_positionText / $_durationText',
                    ),
                  ),
                ],
              ),
              Slider(
                activeColor: widget.activePlayerColor ?? color,
                inactiveColor: widget.inactivePlayerColor,
                onChanged: (v) {
                  final duration = _duration;
                  if (duration == null) {
                    return;
                  }
                  final position = v * duration.inMilliseconds;
                  player.seek(Duration(milliseconds: position.round()));
                },
                value: (_position != null &&
                        _duration != null &&
                        _position!.inMilliseconds > 0 &&
                        _position!.inMilliseconds < _duration!.inMilliseconds)
                    ? _position!.inMilliseconds / _duration!.inMilliseconds
                    : 0.0,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: SizedBox(
            width: 100,
            height: 50,
            child: Slider(
              activeColor: widget.activeVolumeColor ?? color,
              inactiveColor: widget.inactiveVolumeColor,
              onChanged: (v) {
                player.setVolume(v);
                setState(() {
                  currentVolume = v;
                });
              },
              value: (currentVolume),
            ),
          ),
        ),
      ],
    );
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });
  }

  Future<void> _play() async {
    final position = _position;
    if (position != null && position.inMilliseconds > 0) {
      await player.seek(position);
    }
    await player.resume();
    await player.play(_source);
    setState(() => _playerState = PlayerState.playing);
  }

  Future<void> _pause() async {
    await player.pause();
    setState(() => _playerState = PlayerState.paused);
  }
}
