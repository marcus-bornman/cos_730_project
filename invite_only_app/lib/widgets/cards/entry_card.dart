import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:invite_only_repo/invite_only_repo.dart';

class EntryCard extends StatelessWidget {
  final Entry entry;

  const EntryCard({Key key, @required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.arrow_forward, color: Colors.green),
      title: _buildTitle(),
      subtitle: Text('Entered on ${_formattedEntryDate()}'),
    );
  }

  Widget _buildTitle() {
    final document = entry.idDocument;

    if (document is IdBook) {
      return Text(document.idNumber);
    }

    if (document is IdCard) {
      return Text('${document.firstNames} ${document.surname}');
    }

    if (document is DriversLicense) {
      return Text('${document.firstNames} ${document.surname}');
    }

    if (document is Passport) {
      return Text(document.idNumber);
    }

    return null;
  }

  String _formattedEntryDate() {
    return formatDate(entry.entryDate, [D, ' ', d, ' ', M, ' @ ', HH, ':', nn]);
  }
}
