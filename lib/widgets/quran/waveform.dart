import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Live Waveform visualization for recording
class LiveWaveform extends StatelessWidget {
  final List<double> levels;
  final Color? color;

  const LiveWaveform({
    super.key,
    required this.levels,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final waveColor = color ?? context.primaryColor;
    
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: levels.asMap().entries.map((entry) {
          final level = entry.value;
          final height = 12.0 + (level * 48);
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 4,
            height: height,
            decoration: BoxDecoration(
              color: waveColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Animated Waveform for playback display
class AnimatedWaveform extends StatelessWidget {
  final bool isPlaying;
  final Color? color;
  final int barCount;

  const AnimatedWaveform({
    super.key,
    required this.isPlaying,
    this.color,
    this.barCount = 24,
  });

  @override
  Widget build(BuildContext context) {
    final waveColor = color ?? context.primaryColor;
    
    return Expanded(
      child: SizedBox(
        height: 32,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (index) {
            // Create wave pattern
            final baseHeight = (index % 3 == 0) ? 24.0 : (index % 2 == 0) ? 16.0 : 12.0;
            
            return AnimatedContainer(
              duration: Duration(milliseconds: 100 + (index * 10)),
              width: 3,
              height: isPlaying ? baseHeight : 8,
              decoration: BoxDecoration(
                color: isPlaying 
                  ? waveColor
                  : waveColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }
}
