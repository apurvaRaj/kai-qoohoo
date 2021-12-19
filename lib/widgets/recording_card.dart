import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class RecordingCard extends StatelessWidget {
  const RecordingCard({
    Key? key,
    required this.file,
  }) : super(key: key);

  final FileSystemEntity file;

  @override
  Widget build(BuildContext context) {
    final String fileName = p.basename(file.path);
    final List<String> splitData = fileName.split("_");
    // logger.d(splitData);
    final DateFormat dateFormat = DateFormat("dd MMM yyyy");
    final DateTime dateTime = DateTime(
      int.parse(splitData[1].toString().split("-")[0]),
      int.parse(splitData[1].toString().split("-")[1]),
      int.parse(splitData[1].toString().split("-")[2]),
      int.parse(splitData[1].toString().split("-")[3]),
      int.parse(splitData[1].toString().split("-")[4]),
      int.parse(splitData[1].toString().split("-")[5]),
    );
    final int bitRate = int.parse(splitData[2].toString());
    final int samplingRate = int.parse(splitData[3].toString());
    final String fileFormat = splitData[4].split(".")[1];
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryVariant,
      child: ListTile(
        onTap: () {},
        leading: const Icon(Icons.music_note),
        title: Text(dateFormat.format(dateTime)),
        subtitle: Text("${samplingRate / 1000}   ${fileFormat.toUpperCase()}"),
        trailing: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.play_arrow,
              color: Theme.of(context).colorScheme.onSecondary,
            )),
      ),
    );
  }
}