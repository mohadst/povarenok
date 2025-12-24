import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/retro_colors.dart';
import '../services/timer_manager.dart';

class TimerScreen extends StatefulWidget {
  final String title;
  final TimerManager timerManager;

  const TimerScreen({
    super.key,
    required this.title,
    required this.timerManager,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final List<StreamSubscription> _subscriptions = [];

  final List<Map<String, dynamic>> _presets = [
    {'name': 'Яйца всмятку', 'minutes': 3},
    {'name': 'Паста аль денте', 'minutes': 8},
    {'name': 'Рис', 'minutes': 15},
    {'name': 'Картофель', 'minutes': 25},
    {'name': 'Запеканка', 'minutes': 30},
    {'name': 'Суп', 'minutes': 40},
    {'name': 'Жаркое', 'minutes': 60},
  ];

  int _customMinutes = 25;
  int _customSeconds = 0;
  String _customName = '';
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _subscriptions.add(
      widget.timerManager.timerStream.listen((_) {
        if (mounted) setState(() {});
      }),
    );
  }

  void _addTimer(int minutes, int seconds, String name) {
    final timer = widget.timerManager.addTimer(
      name: name,
      minutes: minutes,
      seconds: seconds,
    );
    timer.start();
    _nameController.clear();
    _customName = '';
  }

  void _showPresetDialog(Map<String, dynamic> preset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RetroColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '${preset['name']}',
          style: TextStyle(
            color: RetroColors.cocoa,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${preset['minutes']} минут',
              style: TextStyle(
                color: RetroColors.cocoa.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: preset['name']),
              decoration: InputDecoration(
                hintText: 'Изменить название',
                filled: true,
                fillColor: RetroColors.cream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (v) => _customName = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(color: RetroColors.cocoa.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RetroColors.mustard,
              foregroundColor: RetroColors.paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              _addTimer(
                preset['minutes'],
                0,
                _customName.isNotEmpty ? _customName : preset['name'],
              );
            },
            child: const Text('Старт'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timers = widget.timerManager.timers;

    return Scaffold(
      backgroundColor: RetroColors.paper,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            color: RetroColors.paper,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        backgroundColor: RetroColors.cherryRed,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Быстрые таймеры',
                style: TextStyle(
                  color: RetroColors.cocoa,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _presets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final preset = _presets[index];
                  return GestureDetector(
                    onTap: () => _showPresetDialog(preset),
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: RetroColors.cream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            preset['name'],
                            style: TextStyle(
                              color: RetroColors.cocoa,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${preset['minutes']} мин',
                            style: TextStyle(
                              color: RetroColors.cocoa.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Создать свой',
                style: TextStyle(
                  color: RetroColors.cocoa,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: RetroColors.cream,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Название таймера',
                      filled: true,
                      fillColor: RetroColors.paper,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (v) => _customName = v,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TimePicker(
                        label: 'минут',
                        value: _customMinutes,
                        max: 120,
                        onChanged: (v) => setState(() => _customMinutes = v),
                      ),
                      const SizedBox(width: 12),
                      _TimePicker(
                        label: 'секунд',
                        value: _customSeconds,
                        max: 59,
                        onChanged: (v) => setState(() => _customSeconds = v),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RetroColors.mustard,
                            foregroundColor: RetroColors.paper,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _addTimer(
                            _customMinutes,
                            _customSeconds,
                            _customName,
                          ),
                          child: const Text(
                            'Создать',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'Активные',
                          style: TextStyle(
                            color: RetroColors.cocoa,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: RetroColors.cherryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${timers.length}',
                            style: TextStyle(
                              color: RetroColors.cherryRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (timers.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 64,
                              color: RetroColors.cocoa.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Нет активных таймеров',
                              style: TextStyle(
                                color: RetroColors.cocoa.withOpacity(0.4),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Таймеры продолжают работу в фоне',
                              style: TextStyle(
                                color: RetroColors.cocoa.withOpacity(0.3),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: timers.length,
                        itemBuilder: (_, index) {
                          final t = timers[index];
                          final progress = t.remainingSeconds / t.totalSeconds;
                          final minutes = t.remainingSeconds ~/ 60;
                          final seconds = t.remainingSeconds % 60;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: RetroColors.paper,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                color: RetroColors.cocoa
                                                    .withOpacity(0.6),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          t.isRunning
                                              ? Icons.pause_circle_outline
                                              : Icons.play_circle_outline,
                                          size: 24,
                                        ),
                                        color: RetroColors.mustard,
                                        onPressed: () => widget.timerManager
                                            .toggleTimer(t.id),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: RetroColors.cherryRed
                                            .withOpacity(0.7),
                                        onPressed: () => widget.timerManager
                                            .removeTimer(t.id),
                                      ),
                                    ],
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 3,
                                    backgroundColor: RetroColors.cream,
                                    color: t.isRunning
                                        ? RetroColors.mustard
                                        : RetroColors.cocoa.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _TimePicker({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: RetroColors.cocoa.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          decoration: BoxDecoration(
            color: RetroColors.paper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            items: List.generate(
              max + 1,
              (i) => DropdownMenuItem(
                value: i,
                child: Text(
                  i.toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            onChanged: (v) => onChanged(v!),
            selectedItemBuilder: (context) {
              return List.generate(
                max + 1,
                (i) => Center(
                  child: Text(
                    i.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}