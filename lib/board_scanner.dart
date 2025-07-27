import 'dart:io';
import 'package:appli_scrabble/board.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class BoardScanner {
  final ImagePicker _picker = ImagePicker();

  Future<void> scanBoard(BuildContext context, BoardState boardState) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir dans la galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (pickedFile == null) return;
    final File imageFile = File(pickedFile.path);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GridAdjustmentScreen(
          imageFile: imageFile,
          boardState: boardState,
        ),
      ),
    );
  }
}

class GridAdjustmentScreen extends StatefulWidget {
  final File imageFile;
  final BoardState boardState;

  const GridAdjustmentScreen({
    super.key,
    required this.imageFile,
    required this.boardState,
  });

  @override
  _GridAdjustmentScreenState createState() => _GridAdjustmentScreenState();
}

class _GridAdjustmentScreenState extends State<GridAdjustmentScreen> {
  ui.Image? _image;
  bool _isLoading = true;
  List<Offset> _cornerPoints = [
    const Offset(100, 100),
    const Offset(300, 100),
    const Offset(300, 300),
    const Offset(100, 300),
  ];
  int? _selectedCornerIndex;
  
  // Paramètres de transformation pour l'affichage de l'image
  double _scale = 1.0;
  double _dx = 0.0;
  double _dy = 0.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    
    setState(() {
      _image = frame.image;
      
      // Initialiser les coins pour qu'ils couvrent une grande partie de l'image
      final width = _image!.width.toDouble();
      final height = _image!.height.toDouble();
      
      final padding = min(width, height) * 0.1;
      
      _cornerPoints = [
        Offset(padding, padding), // Top-left
        Offset(width - padding, padding), // Top-right
        Offset(width - padding, height - padding), // Bottom-right
        Offset(padding, height - padding), // Bottom-left
      ];
      
      _isLoading = false;
    });
  }

  double min(double a, double b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ajustement de la grille'),
          backgroundColor: Colors.brown[300],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Positionnez les 4 coins de la grille sur les bords du plateau'),
        backgroundColor: Colors.brown[300],
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _processImage,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculer les paramètres de transformation ici pour pouvoir les utiliser 
          // dans les gestionnaires d'événements
          final imageWidth = _image!.width.toDouble();
          final imageHeight = _image!.height.toDouble();
          
          final scaleX = constraints.maxWidth / imageWidth;
          final scaleY = constraints.maxHeight / imageHeight;
          _scale = scaleX < scaleY ? scaleX : scaleY;
          
          _dx = (constraints.maxWidth - imageWidth * _scale) / 2;
          _dy = (constraints.maxHeight - imageHeight * _scale) / 2;
          
          return GestureDetector(
            onPanDown: (details) {
              _selectCorner(details.localPosition);
            },
            onPanUpdate: (details) {
              _moveCorner(details.localPosition);
            },
            onPanEnd: (_) {
              setState(() {
                _selectedCornerIndex = null;
              });
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: GridPainter(
                image: _image!,
                cornerPoints: _cornerPoints,
                selectedCornerIndex: _selectedCornerIndex,
              ),
            ),
          );
        },
      ),
    );
  }

  // Convertit une position d'écran en coordonnées d'image originale
  Offset _screenToImageCoordinates(Offset screenPosition) {
    return Offset(
      (screenPosition.dx - _dx) / _scale,
      (screenPosition.dy - _dy) / _scale,
    );
  }
  
  // Convertit des coordonnées d'image originale en position d'écran
  Offset _imageToScreenCoordinates(Offset imagePosition) {
    return Offset(
      imagePosition.dx * _scale + _dx,
      imagePosition.dy * _scale + _dy,
    );
  }

  void _selectCorner(Offset screenPosition) {
    final double touchRadius = 40.0;
    int? closestCornerIndex;
    double closestDistance = touchRadius;

    for (int i = 0; i < _cornerPoints.length; i++) {
      // Convertir le point de coin en coordonnées d'écran pour la comparaison
      final cornerScreenPos = _imageToScreenCoordinates(_cornerPoints[i]);
      final distance = (screenPosition - cornerScreenPos).distance;
      
      if (distance < closestDistance) {
        closestDistance = distance;
        closestCornerIndex = i;
      }
    }

    setState(() {
      _selectedCornerIndex = closestCornerIndex;
    });
  }

  void _moveCorner(Offset screenPosition) {
    if (_selectedCornerIndex != null) {
      // Convertir la position d'écran en coordonnées d'image
      final imagePosition = _screenToImageCoordinates(screenPosition);
      
      setState(() {
        _cornerPoints[_selectedCornerIndex!] = imagePosition;
      });
    }
  }

  Future<void> _processImage() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Traitement de l\'image...'),
          ],
        ),
      ),
    );

    try {
      final cellImages = await _extractCellImages();
      
      Navigator.pop(context);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExtractedCellsPreview(
            cellImages: cellImages,
            boardState: widget.boardState,
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du traitement de l\'image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<File>> _extractCellImages() async {
    final data = await widget.imageFile.readAsBytes();
    final image = img.decodeImage(data);
    if (image == null) throw Exception('Impossible de décoder l\'image');
    
    final List<File> cellImages = [];
    final tempDir = await getTemporaryDirectory();
    
    // S'assurer que les coins sont dans le bon ordre
    _sortCornerPoints();
    
    final targetWidth = 15 * 50; // 15 cellules de 50 pixels
    final targetHeight = 15 * 50;
    
    // Simplification - ici nous devrions idéalement utiliser une transformation perspective
    final scaledImage = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
    );
    
    final cellWidth = targetWidth ~/ 15;
    final cellHeight = targetHeight ~/ 15;
    
    for (int y = 0; y < 15; y++) {
      for (int x = 0; x < 15; x++) {
        final cellImage = img.copyCrop(
          scaledImage,
          x: x * cellWidth,
          y: y * cellHeight,
          width: cellWidth,
          height: cellHeight,
        );
        
        final cellFile = File('${tempDir.path}/cell_${y}_$x.png');
        await cellFile.writeAsBytes(img.encodePng(cellImage));
        cellImages.add(cellFile);
      }
    }
    
    return cellImages;
  }

  void _sortCornerPoints() {
    // Calculer le centre des points
    final center = _cornerPoints.fold<Offset>(
      Offset.zero,
      (sum, point) => sum + point,
    ) / 4;
    
    // Trier les points selon leur angle par rapport au centre
    _cornerPoints.sort((a, b) {
      final angleA = (a - center).direction;
      final angleB = (b - center).direction;
      return angleA.compareTo(angleB);
    });
    
    // Réarranger pour que le premier point soit en haut à gauche (min x, min y)
    final minYPoint = _cornerPoints.reduce(
      (current, next) => current.dy < next.dy ? current : next,
    );
    
    final index = _cornerPoints.indexOf(minYPoint);
    if (index > 0) {
      final newPoints = _cornerPoints.sublist(index)
        ..addAll(_cornerPoints.sublist(0, index));
      _cornerPoints = newPoints;
    }
  }
}

class GridPainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> cornerPoints;
  final int? selectedCornerIndex;
  
  GridPainter({
    required this.image,
    required this.cornerPoints,
    this.selectedCornerIndex,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Calculer les facteurs d'échelle pour adapter l'image à l'écran
    final double scaleX = size.width / image.width;
    final double scaleY = size.height / image.height;
    final double scale = scaleX < scaleY ? scaleX : scaleY;
    
    final double scaledWidth = image.width * scale;
    final double scaledHeight = image.height * scale;
    
    // Centrer l'image
    final double dx = (size.width - scaledWidth) / 2;
    final double dy = (size.height - scaledHeight) / 2;
    
    // Dessiner l'image
    final paint = Paint();
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);
    canvas.drawImage(image, Offset.zero, paint);
    canvas.restore();
    
    // Transformer les coins en fonction de l'échelle et du déplacement
    final transformedCorners = cornerPoints.map((point) {
      return Offset(
        point.dx * scale + dx,
        point.dy * scale + dy,
      );
    }).toList();
    
    // Dessiner le quadrilatère
    final path = Path()
      ..moveTo(transformedCorners[0].dx, transformedCorners[0].dy)
      ..lineTo(transformedCorners[1].dx, transformedCorners[1].dy)
      ..lineTo(transformedCorners[2].dx, transformedCorners[2].dy)
      ..lineTo(transformedCorners[3].dx, transformedCorners[3].dy)
      ..close();
    
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
    
    // Dessiner les lignes de la grille avec un meilleur contraste
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    // Effet d'ombre pour améliorer la visibilité
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    
    // Lignes horizontales
    for (int i = 0; i <= 15; i++) {
      final t = i / 15;
      final p1 = _interpolate(transformedCorners[0], transformedCorners[3], t);
      final p2 = _interpolate(transformedCorners[1], transformedCorners[2], t);
      
      // Dessiner l'ombre d'abord
      canvas.drawLine(p1, p2, shadowPaint);
      // Puis la ligne blanche
      canvas.drawLine(p1, p2, linePaint);
    }
    
    // Lignes verticales
    for (int i = 0; i <= 15; i++) {
      final t = i / 15;
      final p1 = _interpolate(transformedCorners[0], transformedCorners[1], t);
      final p2 = _interpolate(transformedCorners[3], transformedCorners[2], t);
      
      // Dessiner l'ombre d'abord
      canvas.drawLine(p1, p2, shadowPaint);
      // Puis la ligne blanche
      canvas.drawLine(p1, p2, linePaint);
    }
    
    // Dessiner les points de contrôle
    for (int i = 0; i < transformedCorners.length; i++) {
      final point = transformedCorners[i];
      final isSelected = i == selectedCornerIndex;
      
      // Ajouter une ombre pour les points
      canvas.drawCircle(
        point,
        isSelected ? 24.0 : 18.0,
        Paint()
          ..color = Colors.black.withOpacity(0.5),
      );
      
      // Point principal
      canvas.drawCircle(
        point,
        isSelected ? 20.0 : 14.0,
        Paint()
          ..color = isSelected
              ? Colors.red.withOpacity(0.8)
              : Colors.blue.withOpacity(0.8),
      );
      
      // Point central blanc
      canvas.drawCircle(
        point,
        isSelected ? 8.0 : 6.0,
        Paint()..color = Colors.white,
      );
    }
  }
  
  Offset _interpolate(Offset p1, Offset p2, double t) {
    return Offset(
      p1.dx + (p2.dx - p1.dx) * t,
      p1.dy + (p2.dy - p1.dy) * t,
    );
  }
  
  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.image != image ||
           oldDelegate.cornerPoints != cornerPoints ||
           oldDelegate.selectedCornerIndex != selectedCornerIndex;
  }
}

class ExtractedCellsPreview extends StatelessWidget {
  final List<File> cellImages;
  final BoardState boardState;
  
  const ExtractedCellsPreview({
    super.key,
    required this.cellImages,
    required this.boardState,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cellules extraites'),
        backgroundColor: Colors.brown[300],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 15,
                childAspectRatio: 1.0,
                crossAxisSpacing: 2.0,
                mainAxisSpacing: 2.0,
              ),
              itemCount: 225, // 15x15
              itemBuilder: (context, index) {
                final row = index ~/ 15;
                final col = index % 15;
                final imageIndex = row * 15 + col;
                
                if (imageIndex < cellImages.length) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown[300]!),
                    ),
                    child: Image.file(
                      cellImages[imageIndex],
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  return Container(
                    color: Colors.brown[100],
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[300],
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Réajuster'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[700],
                  ),
                  onPressed: () {
                    Navigator.popUntil(
                      context, 
                      (route) => route.isFirst,
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reconnaissance OCR à implémenter dans une prochaine version.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  child: const Text(
                    'Reconnaître les lettres',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}