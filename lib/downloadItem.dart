import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:video_downloader/itemHolder.dart';
import 'package:video_downloader/taskInfo.dart';

class DownloadItem extends StatelessWidget {
  final ItemHolder? data;
  final Function(TaskInfo?)? onItemClick;
  final Function(TaskInfo)? onActionClick;
  const DownloadItem(
      {Key? key, this.data, this.onItemClick, this.onActionClick})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16.0, right: 8.0),
      child: InkWell(
        onTap: data!.task!.status == DownloadTaskStatus.complete
            ? () {
                onItemClick!(data!.task);
              }
            : null,
        child: Stack(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: 64.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      data!.name!,
                      maxLines: 1,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: _buildActionForTask(data!.task!, onActionClick),
                  ),
                ],
              ),
            ),
            data!.task!.status == DownloadTaskStatus.running ||
                    data!.task!.status == DownloadTaskStatus.paused
                ? Positioned(
                    left: 0.0,
                    right: 0.0,
                    bottom: 0.0,
                    child: LinearProgressIndicator(
                      value: data!.task!.progress! / 100,
                    ),
                  )
                : Container()
          ].toList(),
        ),
      ),
    );
  }
}

Widget? _buildActionForTask(TaskInfo task, Function(TaskInfo)? onActionClick) {
  if (task.status == DownloadTaskStatus.undefined) {
    return RawMaterialButton(
      onPressed: () {
        onActionClick!(task);
      },
      child: const Icon(Icons.file_download),
      shape: const CircleBorder(),
      constraints: const BoxConstraints(minHeight: 32.0, minWidth: 32.0),
    );
  } else if (task.status == DownloadTaskStatus.running) {
    return RawMaterialButton(
      onPressed: () {
        onActionClick!(task);
      },
      child: const Icon(
        Icons.pause,
        color: Colors.red,
      ),
      shape: const CircleBorder(),
      constraints: const BoxConstraints(minHeight: 32.0, minWidth: 32.0),
    );
  } else if (task.status == DownloadTaskStatus.paused) {
    return RawMaterialButton(
      onPressed: () {
        onActionClick!(task);
      },
      child: const Icon(
        Icons.play_arrow,
        color: Colors.green,
      ),
      shape: const CircleBorder(),
      constraints: const BoxConstraints(minHeight: 32.0, minWidth: 32.0),
    );
  } else if (task.status == DownloadTaskStatus.complete) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'Ready',
          style: TextStyle(color: Colors.green),
        ),
        RawMaterialButton(
          onPressed: () {
            onActionClick!(task);
          },
          child: const Icon(
            Icons.delete_forever,
            color: Colors.red,
          ),
          shape: const CircleBorder(),
          constraints: const BoxConstraints(minHeight: 32.0, minWidth: 32.0),
        )
      ],
    );
  } else if (task.status == DownloadTaskStatus.canceled) {
    return const Text('Canceled', style: TextStyle(color: Colors.red));
  } else if (task.status == DownloadTaskStatus.failed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Failed', style: TextStyle(color: Colors.red)),
        RawMaterialButton(
          onPressed: () {
            onActionClick!(task);
          },
          child: const Icon(
            Icons.refresh,
            color: Colors.green,
          ),
          shape: const CircleBorder(),
          constraints: const BoxConstraints(minHeight: 32.0, minWidth: 32.0),
        )
      ],
    );
  } else if (task.status == DownloadTaskStatus.enqueued) {
    return const Text('Pending', style: TextStyle(color: Colors.orange));
  } else {
    return null;
  }
}
