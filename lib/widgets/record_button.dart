import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kai/controllers/path_controller.dart';
import 'package:kai/controllers/record_controller.dart';
import 'package:kai/controllers/timer_controller.dart';
import 'package:kai/painters/ripple_painter.dart';
import 'package:kai/services/locator_service.dart';
import 'package:kai/services/logger_service.dart';
import 'package:kai/services/record_service.dart';
import 'package:kai/services/snackbar_service.dart';
import 'package:provider/provider.dart';

class RecordButton extends StatefulWidget {
  const RecordButton({
    Key? key,
  }) : super(key: key);

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;
  final Tween<double> _sizeTween = Tween(begin: .4, end: 1);
  bool glow = true;
  bool holding = false;
  // bool dragging = false;
  double x = 0;
  double y = 0;
  bool lock = false;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    animation = _sizeTween.animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    )..addListener(() {
        setState(() {
          if (controller.value >= 0.7) {
            glow = false;
          } else if (controller.value <= 0.1) {
            glow = true;
          }
        });
      });
    controller.repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final RecordController recordController =
        Provider.of<RecordController>(context);
    final PathController pathController = Provider.of<PathController>(context);
    final TimerController timerController =
        Provider.of<TimerController>(context);
    final SnackbarService _snackbarService = locator<SnackbarService>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              top: holding
                  ? lock
                      ? -90
                      : -70
                  : 56,
              height: holding
                  ? lock
                      ? 96
                      : 56
                  : 0,
              child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(lock ? 26 : 16.0),
                    child: Icon(
                      lock ? Icons.lock : Icons.lock_open,
                      size: holding
                          ? lock
                              ? 44
                              : 24
                          : 0,
                    ),
                  ))),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: RipplePainter(
                    color: Theme.of(context).colorScheme.secondary,
                    animationValue: animation.value,
                    width: width * 0.486),
                child: SizedBox(
                  height: width * 0.486,
                  width: width * 0.486,
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                top: holding ? y : (((width * 0.486) - (width * 0.218)) / 2),
                left: (((width * 0.486) - (width * 0.218)) / 2),
                child: SizedBox(
                  height: (width * 0.218),
                  width: (width * 0.218),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    // onVerticalDragStart: (details) {
                    //   if (holding) {
                    //     setState(() {
                    //       dragging = true;
                    //     });
                    //     logger.d("dragging: $dragging");
                    //   }
                    // },
                    // onVerticalDragEnd: (details) {
                    //   setState(() {
                    //     dragging = false;
                    //   });
                    //   logger.d("dragging: $dragging");
                    // },
                    onLongPressStart: (details) async {
                      setState(() {
                        x = details.localPosition.dx;
                        y = details.localPosition.dy;
                      });
                      logger.i("x: $x, y: $y");
                      switch (recordController.recordState) {
                        case RecordState.ready:
                          final permission =
                              await recordController.checkPermission();
                          logger.e(permission);
                          if (permission) {
                            setState(() {
                              holding = true;
                            });
                            final path = await pathController.getDocPath();
                            logger.e(path);
                            timerController.resetTimer();
                            timerController.startTimer();
                            timerController.startAmplitudeTimer(() {
                              recordController.getAmplitude();
                            });
                            recordController.startRecord(path);
                          } else {
                            recordController.recordState = RecordState.error;
                          }
                          break;
                        case RecordState.recording:
                          setState(() {
                            holding = true;
                          });
                          break;
                        case RecordState.paused:
                          break;
                        case RecordState.error:
                          break;
                        default:
                          final permission =
                              await recordController.checkPermission();
                          logger.e(permission);
                          if (permission) {
                            setState(() {
                              holding = true;
                            });
                            final path = await pathController.getDocPath();
                            logger.e(path);
                            timerController.resetTimer();
                            timerController.startTimer();
                            timerController.startAmplitudeTimer(() {
                              recordController.getAmplitude();
                            });
                            recordController.startRecord(path);
                          } else {
                            recordController.recordState = RecordState.error;
                          }
                          break;
                      }
                    },
                    onLongPressMoveUpdate: (details) {
                      setState(() {
                        x = details.localPosition.dx;
                        y = details.localPosition.dy;
                        lock = details.localOffsetFromOrigin.dy.abs() > 130 &&
                            details.localOffsetFromOrigin.direction.isNegative;
                      });
                      // logger.i(
                      //     "x: $x, y: $y offset:${details.localOffsetFromOrigin.dy.abs() > 130} direction:${details.localOffsetFromOrigin.direction.isNegative} lock:${details.localOffsetFromOrigin.dy.abs() > 130 && details.localOffsetFromOrigin.direction.isNegative}");
                    },
                    onLongPressEnd: (details) async {
                      // setState(() {
                      //   x = details.localPosition.dx;
                      //   y = details.localPosition.dy;
                      // });
                      // logger.i("x: $x, y: $y");
                      switch (recordController.recordState) {
                        case RecordState.ready:
                          break;
                        case RecordState.recording:
                          setState(() {
                            holding = false;
                          });
                          if (!lock) {
                            timerController.cancelAmplitudeTimer();
                            timerController.cancelTimer();
                            timerController.resetTimer();
                            final path = await recordController.stopRecord();
                            _snackbarService
                                .showHomeSnackBar("Recording save at $path");
                          }

                          break;
                        case RecordState.paused:
                          break;
                        case RecordState.error:
                          break;
                        default:
                          setState(() {
                            holding = false;
                          });
                          if (!lock) {
                            timerController.cancelAmplitudeTimer();
                            timerController.cancelTimer();
                            timerController.resetTimer();
                            final path = await recordController.stopRecord();
                            _snackbarService
                                .showHomeSnackBar("Recording save at $path");
                          }
                          break;
                      }
                    },
                    child: FloatingActionButton(
                      heroTag: "Record",
                      shape: const CircleBorder(),
                      child: StreamBuilder(
                        stream: recordController.recordStateStream,
                        builder: (context, snapshot) {
                          switch (snapshot.data) {
                            case RecordState.ready:
                              return const Icon(
                                Icons.mic,
                              );
                            case RecordState.recording:
                              return const Icon(
                                Icons.stop,
                              );
                            case RecordState.paused:
                              return const Icon(
                                Icons.stop,
                              );
                            case RecordState.error:
                              return const Icon(
                                Icons.error,
                              );
                            default:
                              return const Icon(
                                Icons.mic,
                              );
                          }
                        },
                      ),
                      elevation: recordController.recordState ==
                                  RecordState.recording &&
                              holding
                          ? 6
                          : 0,
                      onPressed: () async {
                        switch (recordController.recordState) {
                          case RecordState.ready:
                            final permission =
                                await recordController.checkPermission();
                            logger.e(permission);
                            if (permission) {
                              final path = await pathController.getDocPath();
                              logger.e(path);
                              timerController.resetTimer();
                              timerController.startTimer();
                              timerController.startAmplitudeTimer(() {
                                recordController.getAmplitude();
                              });
                              recordController.startRecord(path);
                            } else {
                              recordController.recordState = RecordState.error;
                            }
                            break;
                          case RecordState.recording:
                            timerController.cancelAmplitudeTimer();
                            timerController.cancelTimer();
                            timerController.resetTimer();
                            final path = await recordController.stopRecord();
                            _snackbarService
                                .showHomeSnackBar("Recording save at $path");
                            break;
                          case RecordState.paused:
                            timerController.cancelAmplitudeTimer();
                            timerController.cancelTimer();
                            timerController.resetTimer();
                            final path = await recordController.stopRecord();
                            _snackbarService
                                .showHomeSnackBar("Recording save at $path");
                            break;
                          case RecordState.error:
                            break;
                          default:
                            final permission =
                                await recordController.checkPermission();
                            logger.e(permission);
                            if (permission) {
                              final path = await pathController.getDocPath();
                              logger.e(path);
                              timerController.resetTimer();
                              timerController.startTimer();
                              timerController.startAmplitudeTimer(() {
                                recordController.getAmplitude();
                              });
                              recordController.startRecord(path);
                            } else {
                              recordController.recordState = RecordState.error;
                            }
                            break;
                        }
                      },
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: recordController.recordState == RecordState.recording
                    ? SizedBox(
                        height: (width * 0.258),
                        width: (width * 0.258),
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.secondary,
                        ))
                    : Container(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
