import 'package:flutter/material.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';

/// Componente de slider personalizado para configurar límites de tiempo
/// Similar al diseño de la imagen proporcionada
class TimeLimitSlider extends StatefulWidget {
  final double value; // Valor en horas (0.0 a maxValue)
  final double minValue;
  final double maxValue;
  final int? divisions; // Número de divisiones para valores discretos
  final ValueChanged<double> onChanged;
  final String? leftLabel;
  final String? rightLabel;
  final Color? activeColor;
  final Color? inactiveColor;

  const TimeLimitSlider({
    super.key,
    required this.value,
    this.minValue = 0.0,
    this.maxValue = 24.0,
    this.divisions,
    required this.onChanged,
    this.leftLabel,
    this.rightLabel,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<TimeLimitSlider> createState() => _TimeLimitSliderState();
}

class _TimeLimitSliderState extends State<TimeLimitSlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value.clamp(widget.minValue, widget.maxValue);
  }

  @override
  void didUpdateWidget(TimeLimitSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _currentValue = widget.value.clamp(widget.minValue, widget.maxValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppColors.accentBlue;
    final inactiveColor = widget.inactiveColor ?? AppColors.accentPurple;
    
    // Calcular el porcentaje del valor actual
    final percentage = ((_currentValue - widget.minValue) / 
                       (widget.maxValue - widget.minValue)).clamp(0.0, 1.0);
    
    const double trackHeight = 8.0;
    const double thumbRadius = 10.0; // Reducido de 16 a 10
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slider personalizado
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: thumbRadius * 2, // Altura suficiente para el thumb
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Track de fondo (inactivo) - centrado verticalmente
                  Positioned(
                    left: 0,
                    right: 0,
                    top: (thumbRadius * 2 - trackHeight) / 2, // Centrar verticalmente
                    child: Container(
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: inactiveColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Track activo - centrado verticalmente
                  Positioned(
                    left: 0,
                    width: constraints.maxWidth * percentage,
                    top: (thumbRadius * 2 - trackHeight) / 2, // Centrar verticalmente
                    child: Container(
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Slider con handle personalizado
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 0,
                      thumbShape: _CustomSliderThumb(
                        thumbRadius: thumbRadius,
                        borderColor: activeColor,
                      ),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: thumbRadius + 4),
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: Colors.white,
                      overlayColor: activeColor.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _currentValue,
                      min: widget.minValue,
                      max: widget.maxValue,
                      divisions: widget.divisions,
                      onChanged: (value) {
                        setState(() {
                          _currentValue = value;
                        });
                        widget.onChanged(value);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Etiquetas opcionales
        if (widget.leftLabel != null || widget.rightLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.leftLabel != null)
                  Text(
                    widget.leftLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (widget.rightLabel != null)
                  Text(
                    widget.rightLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Handle personalizado para el slider
class _CustomSliderThumb extends SliderComponentShape {
  final double thumbRadius;
  final Color borderColor;

  const _CustomSliderThumb({
    required this.thumbRadius,
    required this.borderColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbRadius * 2, thumbRadius * 2);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Dibujar el círculo exterior (borde) - más delgado
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5; // Reducido de 2 a 1.5

    // Dibujar el círculo interior (blanco)
    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Dibujar primero el relleno y luego el borde para mejor apariencia
    canvas.drawCircle(center, thumbRadius, fillPaint);
    canvas.drawCircle(center, thumbRadius, borderPaint);
  }
}

