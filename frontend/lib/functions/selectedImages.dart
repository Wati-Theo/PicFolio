// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photoz/globals.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

Future<bool> onSend(BuildContext context, List<int> allselected) async {
  // Implement your send logic here
  try {
    final tempDir = await getTemporaryDirectory();

    // Create temporary files for each image
    final tempFiles = <File>[];
    for (int i = 0; i < allselected.length; i++) {
      // Show progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20.0),
                  Text('Sharing image ${i + 1} of ${allselected.length}'),
                ],
              ),
            ),
          );
        },
      );

      final imageId = allselected[i];
      final mainImageBytes = await fetchMainImage(imageId);
      // Save the main image to a temporary file
      final tempFile = File('${tempDir.path}/temp_image_$i.png');
      await tempFile.writeAsBytes(mainImageBytes);
      tempFiles.add(tempFile);

      // Dismiss progress indicator
      Navigator.of(context).pop();
    }

    // Share the multiple images using the share_plus package
    // ignore: deprecated_member_use
    await Share.shareFiles(
      tempFiles.map((file) => file.path).toList(),
      text: 'I shared these images from my PicFolio app. Try them out!',
      subject: 'Image Sharing',
    );
    return true;
  } catch (e) {
    if (kDebugMode) print('Error sharing images: $e');
    // Handle the error, e.g., show a snackbar or log the error
    return false;
  }
}

Future<List<int>> fetchMainImage(int imageId) async {
  var url = '${Globals.ip}/api/asset/${Globals.username}/$imageId';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else {
    throw Exception('Failed to load preview image ${response.statusCode}');
  }
}

Future<bool> onDelete(BuildContext context, List<int> allselected) async {
  // ask for confirmation before deleting
  final bool delete = await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete Images'),
        content:
            const Text('Are you sure you want to delete the selected images?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('No'),
          ),
        ],
      );
    },
  );
  if (!delete) {
    return false;
  }
  // Call delete image API here
  var imgs = allselected.join(',');
  final response = await http
      .delete(Uri.parse('${Globals.ip}/api/delete/${Globals.username}/$imgs'));
  if (response.statusCode == 200) {
    // print('Image deleted');
    // remove the deleted images from the grid
    return true;
  } else {
    // print('Failed to delete image');
    return false;
  }
}

Future<bool> onAddToAlbum(String albumId, List<int> allselected) async {
  // Call add image API here
  var imgs = allselected.join(',');
  final response = await http.post(
    Uri.parse('${Globals.ip}/api/album/add'),
    body: {'username': Globals.username, 'album_id': albumId, 'asset_id': imgs},
  );

  if (response.statusCode == 200) {
    if (kDebugMode) print('Image added to album');
    return true;
  } else {
    if (kDebugMode) print('Failed to add image to album');
    return false;
  }
}

Future<bool> onRemoveFromAlbum(String albumId, List<int> allselected) async {
  // Call remove image API here
  var imgs = allselected.join(',');
  final response = await http.post(
    Uri.parse('${Globals.ip}/api/album/remove'),
    body: {
      'username': Globals.username,
      'album_id': albumId,
      'asset_ids': imgs
    },
  );

  if (response.statusCode == 200) {
    if (kDebugMode) print('Image removed from album');
    return true;
  } else {
    if (kDebugMode) print('Failed to remove image from album');
    return false;
  }
}

Future<bool> editDate(
  BuildContext context,
  List<int> allselected,
) async {
  // Implement your edit date logic here
  // get a date from calendar
  final DateTime? picked = await showDatePicker(
    context: context,
    // initialDate: selectedDate,
    firstDate: DateTime(2015, 8),
    lastDate: DateTime(2101),
  );
  if (picked == null) {
    return false;
  }
  var date = (picked.toString().split(" ")[0]);
  var imgs = allselected.join(',');
  final response = await http.post(
    Uri.parse('${Globals.ip}/api/redate'),
    body: {
      'username': Globals.username,
      'date': date,
      'id': imgs,
    },
  );
  if (response.statusCode == 200) {
    if (kDebugMode) print('Dates Updated');
    return true;
    // remove the deleted images from the grid
  } else {
    if (kDebugMode) print('Failed to update date');
    return false;
  }
}

Future<bool> moveToShared(List<int> allselected) async {
  // Implement your move to family logic here
  if (kDebugMode) print(allselected);
  final response = await http.post(
    Uri.parse('${Globals.ip}/api/shared/move'),
    body: {
      'username': Globals.username,
      'asset_id': allselected.join(','),
    },
  );
  if (response.statusCode == 200) {
    if (kDebugMode) print('Image Shared');
    return true;
  } else {
    if (kDebugMode) print('Failed to move to share');
  }
  return false;
}

Future<bool> unMoveToShared(List<int> allselected) async {
  // Implement your move to family logic here
  if (kDebugMode) print(allselected);
  final response = await http.post(
    Uri.parse('${Globals.ip}/api/shared/moveback'),
    body: {
      'username': Globals.username,
      'asset_id': allselected.join(','),
    },
  );
  if (response.statusCode == 200) {
    if (kDebugMode) print('Image Unshared');
    return true;
  } else {
    if (kDebugMode) print('Failed to unmove to share');
  }
  return false;
}

final _picker = ImagePicker();

Future<bool> getimage(
  String ip,
  BuildContext context,
) async {
  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    // print("picked");
    if (await _uploadimage(context, pickedFile)) {
      return true;
    }
  }
  return false;
}

Future<bool> _uploadimage(BuildContext context, XFile xFile) async {
  var url = Uri.parse('${Globals.ip}/api/upload');
  var formData = http.MultipartRequest('POST', url);
  formData.fields['username'] = Globals.username;

  final imageBytes = await xFile.readAsBytes();
  formData.files.add(
      http.MultipartFile.fromBytes('asset', imageBytes, filename: 'image.jpg'));

  try {
    final response = await formData.send();
    if (response.statusCode == 200) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Image uploaded successfully'),
      //     duration: Duration(seconds: 2),
      //   ),
      // );
      return true;
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Upload failed: ${response.reasonPhrase}'),
      //     duration: Duration(seconds: 2),
      //   ),
      // );
      return false;
    }
  } catch (e) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Error during upload: $e'),
    //     duration: Duration(seconds: 2),
    //   ),
    // );
    return false;
  }
}
