import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/services/config_service.dart';
import 'package:nordplayer/widgets/frosted_glass.dart';

class ButtonContainer extends ConsumerStatefulWidget {
  final List<Widget> buttons;
  const ButtonContainer({super.key, required this.buttons});

  @override
  ConsumerState<ButtonContainer> createState() => _ButtonContainerState();
}

class _ButtonContainerState extends ConsumerState<ButtonContainer> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(configServiceProvider).requireValue;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: FrostedGlass(
          backgroundColor: appConfig.adaptiveBg
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : theme.colorScheme.surfaceContainerHigh,
          blurSigma: 20,
          child: Material(
            color: Colors.transparent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.buttons,
            ),
          ),
        ),
      ),
    );
  }
}
