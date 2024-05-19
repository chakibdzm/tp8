import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';


class MusicListScreen extends StatefulWidget {
  @override
  _MusicListScreenState createState() => _MusicListScreenState();
}

class _MusicListScreenState extends State<MusicListScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> songs = [];

  @override
  void initState() {
    super.initState();
    requestPermissionAndFetchSongs();
  }

  Future<void> requestPermissionAndFetchSongs() async {
    var status = await Permission.storage.status;
    if (status.isGranted) {
      fetchSongs();
    } else if (status.isDenied) {
      if (await Permission.storage.request().isGranted) {
        fetchSongs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission is required to access music files.')),
        );
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> fetchSongs() async {
    Directory? downloadsDirectory = await getExternalStorageDirectory();
    if (downloadsDirectory != null) {
      String downloadsPath = "/storage/emulated/0/azza";
      print(downloadsPath);

      List<SongModel> allSongs = await _audioQuery.querySongs(
        uriType: UriType.EXTERNAL,
        sortType: SongSortType.DATE_ADDED,

      );

      setState(() {
        songs = allSongs.where((song) {
          return song.fileExtension == 'mp3' && song.data.contains(downloadsPath);
        }).toList();
      });
    } else {
      print('Downloads directory is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Music List")),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.music_note,color: Colors.purple,
            ),
            title: Text(songs[index].title),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(songs: songs, currentIndex: index),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final List<SongModel> songs;
  final int currentIndex;

  PlayerScreen({required this.songs, required this.currentIndex});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  late int currentIndex;

  bool isPlaying = false;


  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    currentIndex = widget.currentIndex;
    playCurrentSong();
  }


  void playCurrentSong() async {
    await _audioPlayer.setUrl(widget.songs[currentIndex].uri!);
    _audioPlayer.play();

    setState(() {
      isPlaying = true;
    });
  }

  void play() {
    _audioPlayer.play();

    setState(() {
      isPlaying = true;
    });
  }

  void pause() {
    _audioPlayer.pause();

    setState(() {
      isPlaying = false;
    });
  }

  void playNext() {
    if (currentIndex < widget.songs.length - 1) {
      currentIndex++;
      playCurrentSong();
    }
  }

  void playPrevious() {
    if (currentIndex > 0) {
      currentIndex--;
      playCurrentSong();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.songs[currentIndex].title)),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 80),
          child: Column(

            children: [
              Icon(Icons.music_video_outlined, size: 90, color: Colors.purple,),
              SizedBox(height: 30,),
              Text(widget.songs[currentIndex].title),
              SizedBox(height: 30,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.skip_previous, size: 40,),
                    onPressed: playPrevious,
                  ),
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow, size: 50,),
                    onPressed: isPlaying ? pause : play,
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next, size: 40,),
                    onPressed: playNext,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}