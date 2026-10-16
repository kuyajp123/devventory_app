import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:devventory_app/shared/presentation/companion_style.dart';

/// A tactile primary action, retaining FilledButton's input and semantics model.
class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  final _states = WidgetStatesController();
  PointerDownEvent? _touch;

  void _release(PointerEvent event) {
    if (_touch?.pointer != event.pointer) return;
    _touch = null;
    _states.update(WidgetState.pressed, false);
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = widget.label;
    final busy = widget.busy;
    final icon = widget.icon;
    final onPressed = widget.onPressed;
    final enabled = !busy && onPressed != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // A scrolling gesture arena delays tap-down. Begin visual feedback now;
    // the FilledButton still owns activation, cancellation, focus and semantics.
    return Listener(
      onPointerDown: enabled
          ? (event) {
              if (_touch != null) return;
              _touch = event;
              _states.update(WidgetState.pressed, true);
            }
          : null,
      onPointerMove: (event) {
        if (_touch?.pointer == event.pointer &&
            (event.position - _touch!.position).distance > kTouchSlop) {
          _states.update(WidgetState.pressed, false);
        }
      },
      onPointerUp: _release,
      onPointerCancel: _release,
      child: Semantics(
        liveRegion: busy,
        child: FilledButton(
          statesController: _states,
          onPressed: enabled ? onPressed : null,
          clipBehavior: Clip.none,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: colors.onPrimary,
            disabledForegroundColor: busy
                ? colors.onPrimary
                : colors.onSurfaceVariant,
            overlayColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: EdgeInsets.zero,
            minimumSize: const Size(48, 62),
            animationDuration: Duration.zero,
            splashFactory: NoSplash.splashFactory,
            // Keep the hit target stationary while only the visual face moves.
            // https://api.flutter.dev/flutter/material/ButtonStyle/backgroundBuilder.html
            backgroundBuilder: (context, states, child) => _ButtonFace(
              pressed: enabled && states.contains(WidgetState.pressed),
              focused: states.contains(WidgetState.focused),
              highlighted: enabled && states.contains(WidgetState.hovered),
              available: enabled || busy,
              reduceMotion: reduceMotion,
              child: child!,
            ),
          ),
          child: Semantics(
            label: busy ? '$label. In progress' : label,
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (busy && !reduceMotion)
                    SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  else if (busy || icon != null)
                    Icon(busy ? Icons.more_horiz_rounded : icon, size: 20),
                  Text(label, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonFace extends StatelessWidget {
  const _ButtonFace({
    required this.pressed,
    required this.focused,
    required this.highlighted,
    required this.available,
    required this.reduceMotion,
    required this.child,
  });

  final bool pressed, focused, highlighted, available, reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: CompanionStyle.buttonDepth),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: pressed ? 1 : 0),
        duration: reduceMotion
            ? Duration.zero
            : pressed
            ? CompanionStyle.pressDuration
            : CompanionStyle.releaseDuration,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Transform.translate(
          offset: Offset(
            0,
            reduceMotion ? 0 : value * CompanionStyle.buttonDepth,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: available
                  ? (pressed || highlighted ? colors.secondary : colors.primary)
                  : colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(CompanionStyle.controlRadius),
              border: Border.all(
                color: focused ? colors.onSurface : Colors.transparent,
                width: 2,
              ),
              boxShadow: available && value < 1
                  ? [
                      BoxShadow(
                        color: CompanionStyle.accentDepth,
                        offset: Offset(
                          0,
                          (1 - value) * CompanionStyle.buttonDepth,
                        ),
                      ),
                    ]
                  : const [],
            ),
            child: child,
          ),
        ),
        child: child,
      ),
    );
  }
}
