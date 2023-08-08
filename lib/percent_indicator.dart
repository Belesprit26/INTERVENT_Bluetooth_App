import 'package:flutter/material.dart';

class PercentIndicator extends StatelessWidget {
  final double? percent;
  final double? degree;
  final Color? color;
  final String? _message;

  PercentIndicator.connected(
      {Key? key, required this.degree, required this.percent})
      : color = Colors.blue,
        _message = null,
        super(key: key);

  PercentIndicator.connecting({Key? key})
      : degree = null,
        percent = null,
        _message = 'Connecting...',
        color = Colors.grey.shade300,
        super(key: key);

  PercentIndicator.disconnected({Key? key})
      : percent = 1.0,
        degree = 1.0,
        _message = 'Disconnected',
        color = Colors.grey.shade500,
        super(key: key);

  PercentIndicator.error({Key? key})
      : percent = 1.0,
        degree = 1.0,
        _message = 'Error',
        color = Colors.red,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            SizedBox(
              height: 210,
              width: 210,
              child: CircularProgressIndicator(
                value: degree,
                color: color,
              ),
            ),
            SizedBox(
              height: 210,
              width: 210,
              child: Center(
                child: Text(
                  _message != null
                      ? _message!
                      : '${((degree ?? 0)).toStringAsFixed(1)}°C',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 90,
              width: 210,
              child: Center(
                child: Text(
                  "Temperature",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 20,
        ),
        Stack(
          children: [
            SizedBox(
              height: 210,
              width: 210,
              child: CircularProgressIndicator(
                value: percent,
                color: color,
              ),
            ),
            SizedBox(
              height: 210,
              width: 210,
              child: Center(
                child: Text(
                  _message != null
                      ? _message!
                      : '${((percent ?? 0)).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 90,
              width: 210,
              child: Center(
                child: Text(
                  "Humidity",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
