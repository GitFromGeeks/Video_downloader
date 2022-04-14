import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:android_path_provider/android_path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_downloader/downloadItem.dart';
import 'package:video_downloader/itemHolder.dart';
import 'package:video_downloader/taskInfo.dart';

class MyHomePage extends StatefulWidget with WidgetsBindingObserver {
  final TargetPlatform? platform;
  final String? title;

  MyHomePage({Key? key, this.platform, this.title}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // videos

  final videos = [
    {
      'name': 'Big Buck Bunny',
      'link':
          'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
    },
    {
      'name': 'Elephant Dream',
      'link':
          'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4'
    }
  ];

  //
  List<TaskInfo>? tasks;
  late List<ItemHolder> items;
  late String localPath;
  late bool isLoading;
  ReceivePort port = ReceivePort();

  @override
  void initState() {
    super.initState();
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
    isLoading = true;
    _prepare();
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    port.listen((dynamic data) {
      String? id = data[0];
      DownloadTaskStatus? status = data[1];
      int? progress = data[2];

      if (tasks != null && tasks!.isNotEmpty) {
        final task = tasks!.firstWhere((task) => task.taskId == id);
        setState(() {
          task.status = status;
          task.progress = progress;
        });
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  Future<void> _prepare() async {
    final dtasks = await FlutterDownloader.loadTasks();

    int count = 0;
    tasks = [];
    items = [];

    tasks!.addAll(videos
        .map((video) => TaskInfo(name: video['name'], link: video['link'])));

    items.add(ItemHolder(name: 'Videos'));
    for (int i = count; i < tasks!.length; i++) {
      items.add(ItemHolder(name: tasks![i].name, task: tasks![i]));
      count++;
    }

    for (var dtask in dtasks!) {
      for (TaskInfo info in tasks!) {
        if (info.link == dtask.url) {
          info.taskId = dtask.taskId;
          info.status = dtask.status;
          info.progress = dtask.progress;
        }
      }
    }

    await _prepareSaveDir();

    setState(() {
      isLoading = false;
    });
  }
  //  CODE FROM EXAMPUR TEAM
  /*Future<void> requestVideoDownload() async {
  final dir = await getApplicationDocumentsDirectory();

   var _localPath = dir.path + '/' + videoName;
  final savedDir = Directory(_localPath);
  await savedDir.create(recursive: true).then((value) async {
    String? _taskid = await FlutterDownloader.enqueue(
      url: videoLink,
      fileName: videoName,
      savedDir: _localPath,
      showNotification: false,
      openFileFromNotification: false,
      saveInPublicStorage: false,
    );
    AppConstants.printLog(_taskid);
    Navigator.push(context, MaterialPageRoute(builder: (_) =>
        Downloads(0)
    ));
  });
}*/

  Future<void> _prepareSaveDir() async {
    // localPath = (await _findLocalPath())!;
    final dir = await getApplicationDocumentsDirectory();
    localPath = dir.path;
    final savedDir = Directory(localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
  }

  // Future<String?> _findLocalPath() async {
  //   // ignore: prefer_typing_uninitialized_variables
  //   var externalStorageDirPath;
  //   if (Platform.isAndroid) {
  //     try {
  //       externalStorageDirPath = await AndroidPathProvider.downloadsPath;
  //     } catch (e) {
  //       final directory = await getExternalStorageDirectory();
  //       externalStorageDirPath = directory?.path;
  //     }
  //   } else if (Platform.isIOS) {
  //     externalStorageDirPath =
  //         (await getApplicationDocumentsDirectory()).absolute.path;
  //   }
  //   return externalStorageDirPath;
  // }

  // Build  Widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Builder(
        builder: (context) => isLoading
            ? const Center(child: CircularProgressIndicator())
            : buildDownloadList(),
      ),
    );
  }

  // buildDownloadList
  buildDownloadList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      children: [
        ...items
            .map((item) => item.task == null
                ? buildListSection(item.name!)
                : DownloadItem(
                    data: item,
                    onItemClick: (task) {
                      openDownloadedFile(task).then((success) {
                        if (!success) {
                          Scaffold.of(context).showSnackBar(const SnackBar(
                              content: Text('Cannot open this file')));
                        }
                      });
                    },
                    onActionClick: (task) {
                      if (task.status == DownloadTaskStatus.undefined) {
                        requestDownload(task);
                      } else if (task.status == DownloadTaskStatus.running) {
                        pauseDownload(task);
                      } else if (task.status == DownloadTaskStatus.paused) {
                        resumeDownload(task);
                      } else if (task.status == DownloadTaskStatus.complete) {
                        delete(task);
                      } else if (task.status == DownloadTaskStatus.failed) {
                        retryDownload(task);
                      }
                    },
                  ))
            .toList(),
      ],
    );
  }

  // List Section
  Widget buildListSection(String title) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18.0),
        ),
      );

  void requestDownload(TaskInfo task) async {
    task.taskId = await FlutterDownloader.enqueue(
      url: task.link!,
      headers: {"auth": "test_for_sql_encoding"},
      savedDir: localPath,
      showNotification: false,
      openFileFromNotification: false,
      saveInPublicStorage: false,
    );
  }

  // CANCEL DOWNLOAD

  void cancelDownload(TaskInfo task) async {
    await FlutterDownloader.cancel(taskId: task.taskId!);
  }

  // PAUSE DOWNLOAD
  void pauseDownload(TaskInfo task) async {
    await FlutterDownloader.pause(taskId: task.taskId!);
  }

  // RESUME DOWNLOAD
  void resumeDownload(TaskInfo task) async {
    String? newTaskId = await FlutterDownloader.resume(taskId: task.taskId!);
    task.taskId = newTaskId;
  }

  // RETRY DOWNLOAD
  void retryDownload(TaskInfo task) async {
    String? newTaskId = await FlutterDownloader.retry(taskId: task.taskId!);
    task.taskId = newTaskId;
  }

  // DELETE TASK
  void delete(TaskInfo task) async {
    await FlutterDownloader.remove(
        taskId: task.taskId!, shouldDeleteContent: true);
    await _prepare();
    setState(() {});
  }

  Future<bool> openDownloadedFile(TaskInfo? task) {
    if (task != null) {
      return FlutterDownloader.open(taskId: task.taskId!);
    } else {
      return Future.value(false);
    }
  }

  // Dispose
  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }
}
