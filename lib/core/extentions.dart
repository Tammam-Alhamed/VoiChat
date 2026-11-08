import 'package:flutter/material.dart';

extension WhiteTextExtension on Text {
  Text get white {
    return Text(
      data ?? '',
      style: (style ?? const TextStyle()).copyWith(color: Colors.white),
    );
  }
}

extension WhiteIconExtension on Icon {
  Icon get white {
    return Icon(
      icon,
      color: Colors.white,
      size: size,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
    );
  }
}

extension FontSizeExtension on Text {
  // A custom method for each font size
  Text get fs16 {
    return Text(
      data ?? '',
      style: (style ?? const TextStyle()).copyWith(fontSize: 16),
    );
  }

  Text get fs18 {
    return Text(
      data ?? '',
      style: (style ?? const TextStyle()).copyWith(fontSize: 18),
    );
  }

  Text get fs20 {
    return Text(
      data ?? '',
      style: (style ?? const TextStyle()).copyWith(fontSize: 20),
    );
  }

  Text get fs22 {
    return Text(
      data ?? '',
      style: (style ?? const TextStyle()).copyWith(fontSize: 22),
    );
  }

  Text get fs24 {
    return Text(
      data ?? '',
      style: (style ?? const TextStyle()).copyWith(fontSize: 24),
    );
  }

  Text get fs26 {
    return Text(
      data ?? '',
      style: (style ?? const TextStyle()).copyWith(fontSize: 26),
    );
  }

  Text get fs14 {
    return Text(
      data ?? '',
      style: (style ?? const TextStyle()).copyWith(fontSize: 14),
    );
  }

  Text get fs12 {
    return Text(
      data ?? '',
      style: (style ?? const TextStyle()).copyWith(fontSize: 12),
    );
  }

  Text get fs10 {
    return Text(
      data ?? '',
      style: (style ?? const TextStyle()).copyWith(fontSize: 10),
    );
  }

  // You can add more sizes as needed, like fs20, fs24, etc.

  Text get bold {
    return Text(
      data ?? '',
      style: (style ?? const TextStyle()).copyWith(fontWeight: FontWeight.bold),
    );
  }
}

extension PaddingWed on Widget {
  Widget pt(double p) {
    return Padding(
      padding: EdgeInsets.only(top: p),
      child: this,
    );
  }

  Widget pb(double p) {
    return Padding(
      padding: EdgeInsets.only(bottom: p),
      child: this,
    );
  }

  Widget pl(double p) {
    return Padding(
      padding: EdgeInsets.only(left: p),
      child: this,
    );
  }

  Widget prb(double p) {
    return Padding(
      padding: EdgeInsets.only(right: p),
      child: this,
    );
  }
}

extension OnPressed on Widget {
  Widget ripple(
    Function onPressed, {
    BorderRadiusGeometry borderRadius = const BorderRadius.all(
      Radius.circular(5),
    ),
  }) => Stack(
    children: <Widget>[
      this,
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        child: TextButton(
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: borderRadius),
            ),
          ),
          onPressed: () {
            onPressed();
          },
          child: Container(),
        ),
      ),
    ],
  );
}
