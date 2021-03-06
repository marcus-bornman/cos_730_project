import 'package:flutter/material.dart';

Future<void> showError(BuildContext context, String message) async {
  await showDialog(
    context: context,
    builder: (_) => ErrorDialog(message: message),
  );
}

class ErrorDialog extends StatelessWidget {
  final String message;

  const ErrorDialog({Key key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Oops, an error occurred!', textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actions: <Widget>[
        FlatButton(
          child: Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
