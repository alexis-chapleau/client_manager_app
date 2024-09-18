import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'models/client.dart';
import 'database/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ClientCreatePage extends StatefulWidget {
  @override
  _ClientCreatePageState createState() => _ClientCreatePageState();
}

class _ClientCreatePageState extends State<ClientCreatePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String patientId = '';
  String dateOfBirth = '';

  String? imagePath;

  @override
  void initState() {
    super.initState();
  }

  Future<void> saveClient() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Client client = Client(
        name: name,
        patientId: patientId,
        dateOfBirth: dateOfBirth,
      );

      await dbHelper.insertClient(client);

      // Navigate back to the clients list
      Navigator.pop(context, true);
    }
  }

  // Existing methods for image capture and OCR
  Future<void> captureAndExtractText() async {
    try {
      // Load image from assets and get file path
      imagePath = await getImageFileFromAssets('assets/laurie.jpeg');

      // Read the image as bytes
      final bytes = await File(imagePath!).readAsBytes();

      // Decode the image using image package
      img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        print('Could not decode image');
        return;
      }

      // Check and correct the orientation
      img.Image fixedImage = await fixImageOrientation(originalImage, bytes);

      // Preprocess the image
      img.Image preprocessedImage = preprocessImage(fixedImage);

      // Save the preprocessed image to a new file
      final preprocessedImagePath =
          '${(await getTemporaryDirectory()).path}/preprocessed_laura.jpeg';
      await File(preprocessedImagePath)
          .writeAsBytes(img.encodeJpg(preprocessedImage));

      // Update imagePath to display the preprocessed image
      imagePath = preprocessedImagePath;
      setState(() {});

      // Create InputImage from the preprocessed image
      final InputImage inputImage = InputImage.fromFilePath(imagePath!);

      // Initialize the text recognizer
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);

      // Process the image and extract text
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      // Print recognized text for debugging
      print('Recognized text: "${recognizedText.text}"');

      // Parse the extracted text to fill in the form fields
      parseExtractedText(recognizedText.text);

      // Close the text recognizer
      textRecognizer.close();
    } catch (e) {
      print('Error during text recognition: $e');
    }
  }

  Future<img.Image> fixImageOrientation(
      img.Image image, Uint8List bytes) async {
    // Read EXIF data
    final Map<String?, IfdTag>? exifData = await readExifFromBytes(bytes);

    if (exifData != null && exifData.isNotEmpty) {
      print('EXIF data found');
    } else {
      print('No EXIF data found');
    }

    // Check for Orientation tag
    if (exifData != null && exifData.containsKey('Image Orientation')) {
      int? orientation = exifData['Image Orientation']?.values?.first?.toInt();

      print('EXIF orientation: $orientation');

      switch (orientation) {
        case 1:
          // Do nothing, the image is already correctly oriented
          return image;
        case 3:
          // Rotate 180 degrees
          return img.copyRotate(image, 180);
        case 6:
          // Rotate 90 degrees clockwise
          return img.copyRotate(image, 90);
        case 8:
          // Rotate 90 degrees counter-clockwise
          return img.copyRotate(image, -90);
        default:
          return image;
      }
    } else {
      // If no EXIF orientation data, you may need to rotate manually
      print('No orientation data, rotating by 90 degrees');
      return img.copyRotate(image, 90);
    }
  }

  // Preprocess the image to improve OCR accuracy
  img.Image preprocessImage(img.Image image) {
    // Convert to grayscale
    img.Image grayscaleImage = img.grayscale(image);

    // Apply histogram equalization
    img.Image equalizedImage = histogramEqualization(grayscaleImage);

    // Adjust brightness and contrast
    img.Image adjustedImage =
        img.adjustColor(equalizedImage, brightness: 0.1, contrast: 1.5);

    // Resize image (optional, can improve OCR for small text)
    img.Image resizedImage = img.copyResize(adjustedImage,
        width: image.width * 2, height: image.height * 2);

    return resizedImage;
  }

  // Histogram equalization
  img.Image histogramEqualization(img.Image src) {
    img.Image dst = img.Image.from(src);

    int numPixels = src.width * src.height;
    List<int> histogram = List.filled(256, 0);
    List<int> cdf = List.filled(256, 0);

    // Calculate histogram
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        int pixel = src.getPixel(x, y);
        int intensity = img.getLuminance(pixel);
        histogram[intensity]++;
      }
    }

    // Calculate cumulative distribution function (cdf)
    cdf[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i];
    }

    // Normalize cdf
    List<int> cdfNormalized = List.filled(256, 0);
    int cdfMin = cdf.firstWhere((value) => value != 0);
    for (int i = 0; i < 256; i++) {
      cdfNormalized[i] = ((cdf[i] - cdfMin) * 255) ~/ (numPixels - cdfMin);
    }

    // Apply equalization
    for (int y = 0; y < dst.height; y++) {
      for (int x = 0; x < dst.width; x++) {
        int pixel = src.getPixel(x, y);
        int intensity = img.getLuminance(pixel);
        int newIntensity = cdfNormalized[intensity];

        dst.setPixelRgba(x, y, newIntensity, newIntensity, newIntensity);
      }
    }

    return dst;
  }

  Future<String> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load(path);

    final file = File('${(await getTemporaryDirectory()).path}/laurie.jpeg');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return file.path;
  }

  void parseExtractedText(String text) {
    // Simple parsing logic (adjust as needed)
    RegExp nameReg = RegExp(r'Name[:\-]?\s*(.*)', caseSensitive: false);
    RegExp idReg = RegExp(r'Patient ID[:\-]?\s*(.*)', caseSensitive: false);
    RegExp dobReg = RegExp(r'Date of Birth[:\-]?\s*(.*)', caseSensitive: false);

    setState(() {
      name = nameReg.firstMatch(text)?.group(1)?.trim() ?? name;
      patientId = idReg.firstMatch(text)?.group(1)?.trim() ?? patientId;
      dateOfBirth =
          dobReg.firstMatch(text)?.group(1)?.trim() ?? dateOfBirth;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Client'),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: captureAndExtractText,
          ),
          IconButton(
            icon: Icon(Icons.check),
            onPressed: saveClient,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Display the image if available
            if (imagePath != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.file(File(imagePath!)),
              ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name Field
                    TextFormField(
                      initialValue: name,
                      decoration: InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a name' : null,
                      onSaved: (value) => name = value!,
                    ),
                    // Patient ID Field
                    TextFormField(
                      initialValue: patientId,
                      decoration: InputDecoration(labelText: 'Patient ID'),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter a patient ID'
                          : null,
                      onSaved: (value) => patientId = value!,
                    ),
                    // Date of Birth Field
                    TextFormField(
                      initialValue: dateOfBirth,
                      decoration: InputDecoration(labelText: 'Date of Birth'),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter date of birth'
                          : null,
                      onSaved: (value) => dateOfBirth = value!,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
