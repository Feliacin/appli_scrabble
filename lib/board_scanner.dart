import 'dart:io';
import 'dart:math';
import 'package:appli_scrabble/board.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Détection de la grille...'),
          ],
        ),
      ),
    );

      final (debugSteps, cellImages) = await _extractCellImages(imageFile.path);
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DebugStepsScreen(
            debugSteps: debugSteps,
            onComplete: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExtractedCellsPreview(
                  cellImages: cellImages,
                  boardState: boardState,
                ),
              ),
            ),
          ),
        ),
      );
  }

  Future<(List<(cv.Mat, String)>, List<File>)> _extractCellImages(String imagePath) async {
    final img = cv.imread(imagePath);
    if (img.isEmpty) throw Exception('Impossible de charger l\'image');

    final List<(cv.Mat, String)> debugSteps = [];
    List<File> cellImages = [];

    try {
      // Étape 1 : Conversion en gris
      final gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY);
      debugSteps.add((gray.clone(), 'Étape 1 : Conversion en gris'));

      // Étape 2 : Flou gaussien
      final blurred = cv.gaussianBlur(gray, (5, 5), 0);
      debugSteps.add((blurred.clone(), 'Étape 2 : Flou gaussien'));

      // Étape 3 : Seuil adaptatif pour une meilleure détection des contours
      final thresh = cv.adaptiveThreshold(
        blurred, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY, 11, 2
      );
      debugSteps.add((thresh.clone(), 'Étape 3 : Seuil adaptatif'));

      // Étape 4 : Détection d'arêtes Canny
      final edges = cv.canny(thresh, 50, 150);
      debugSteps.add((edges.clone(), 'Étape 4 : Détection d\'arêtes Canny'));

      // Étape 5 : Détection du contour extérieur du plateau
      var contours = cv.findContours(edges, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE).$1;
      final outerBoardContour = contours.reduce((a, b) => cv.contourArea(a) > cv.contourArea(b) ? a : b);

      final boardContourImg = img.clone();
      cv.drawContours(boardContourImg, cv.VecVecPoint.fromVecPoint(outerBoardContour), -1, cv.Scalar(0, 255, 0, 0), thickness: 3);
      debugSteps.add((boardContourImg.clone(), 'Étape 5 : Contour du plateau détecté'));

      // Étape 6 : Redresser le plateau
      final boardCorners = _getCorners(outerBoardContour);

      final cornersDebugImg = img.clone();
      for (int i = 0; i < boardCorners.length; i++) {
        cv.circle(cornersDebugImg, boardCorners[i], 10, cv.Scalar(0, 255, 0, 0), thickness: -1);
      }
      debugSteps.add((cornersDebugImg.clone(), 'DEBUG : Coins détectés du plateau'));
      
      final warpedBoard = _warpBoard(img, boardCorners);
      debugSteps.add((warpedBoard.clone(), 'Étape 8 : Plateau redressé'));
   final warpedGray = cv.cvtColor(warpedBoard, cv.COLOR_BGR2GRAY);
   final size = 800; // Taille fixe du plateau redressé


debugSteps.add((warpedGray.clone(), 'Étape 9 : Plateau en gris'));

final warpedBlurred = cv.gaussianBlur(warpedGray, (3, 3), 0); // Flou léger pour cases fines
debugSteps.add((warpedBlurred.clone(), 'Étape 10 : Flou sur plateau'));

final warpedThresh = cv.adaptiveThreshold(
  warpedBlurred, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY_INV, 7, 3 // Plus fin pour petites cases
);
debugSteps.add((warpedThresh.clone(), 'Étape 11 : Seuil adaptatif inversé'));

final kernel = cv.getStructuringElement(cv.MORPH_RECT, (2, 2));
final morphed = cv.morphologyEx(warpedThresh, cv.MORPH_OPEN, kernel); // Nettoie bruit, préserve rectangles
debugSteps.add((morphed.clone(), 'Étape 12 : Morphologie pour contours de cases'));


contours = cv.findContours(morphed, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE).$1; // RETR_LIST pour tous
if (contours.isEmpty) throw Exception('Aucun contour de case détecté');

final approxCellSize = size / 15; // Taille estimée d'une case (~53 pour size=800)
final minCellArea = (approxCellSize * 0.7) * (approxCellSize * 0.7); // Tolérance
final maxCellArea = (approxCellSize * 1.3) * (approxCellSize * 1.3);

List<cv.Rect> cellRects = [];
for (final contour in contours) {
  final approx = cv.approxPolyDP(contour, cv.arcLength(contour, true) * 0.03, true);
  if (approx.length == 4) { // Rectangle approximé
    final area = cv.contourArea(contour);
    if (area >= minCellArea && area <= maxCellArea) {
      cellRects.add(cv.boundingRect(contour));
    }
  }
}

// Debug : Dessiner les cases détectées
final cellsDebug = warpedBoard.clone();
for (final rect in cellRects) {
  cv.rectangle(cellsDebug, rect, cv.Scalar(0, 255, 0, 0), thickness: 2);
}
debugSteps.add((cellsDebug.clone(), 'Étape 13 : Cases vides détectées'));

if (cellRects.isEmpty) throw Exception('Aucune case valide pour extrapoler la grille');

int minX = cellRects.map((r) => r.x).reduce(min);
int maxX = cellRects.map((r) => r.x + r.width).reduce(max);
int minY = cellRects.map((r) => r.y).reduce(min);
int maxY = cellRects.map((r) => r.y + r.height).reduce(max);

final gridRect = cv.Rect(minX, minY, maxX - minX, maxY - minY);

// Vérifie aspect ratio ~1 (carré)
if ((gridRect.width / gridRect.height).abs() - 1 > 0.05) throw Exception('Grille extrapolée non carrée');

// Taille de cellule moyenne (plus précise maintenant)
final cellSizeW = gridRect.width / 15;
final cellSizeH = gridRect.height / 15;

// Debug : Bordures extrapolées
final bordersDebug = warpedBoard.clone();
cv.rectangle(bordersDebug, gridRect, cv.Scalar(255, 0, 0, 0), thickness: 3);
debugSteps.add((bordersDebug.clone(), 'Étape 14 : Bordures de grille extrapolées'));



cellImages = [];
for (int row = 0; row < 15; row++) {
  for (int col = 0; col < 15; col++) {
    final left = (gridRect.x + col * cellSizeW).round();
    final top = (gridRect.y + row * cellSizeH).round();
    final width = cellSizeW.round();
    final height = cellSizeH.round();
    
    final cellRectLocal = cv.Rect(left, top, width, height);
    final cellMat = warpedBoard.clone().region(cellRectLocal);
    
    final tempPath = '${Directory.systemTemp.path}/cell_${row}_$col.png';
    cv.imwrite(tempPath, cellMat);
    cellImages.add(File(tempPath));
    
    cellMat.release();
  }
}
      
      // Libération des ressources
      _releaseResources([img, gray, blurred, thresh, edges, warpedBoard, cornersDebugImg, boardContourImg]);


      return (debugSteps, cellImages);
    } catch (e) {
      img.release();
      rethrow;
    }
  }

  List<cv.Point> _getCorners(cv.VecPoint contour) {
    final points = contour.toList();
    
    
    // Trouver les 4 points les plus éloignés du centre
    final centerX = points.map((p) => p.x).reduce((a, b) => a + b) / points.length;
    final centerY = points.map((p) => p.y).reduce((a, b) => a + b) / points.length;
    final center = cv.Point(centerX.round(), centerY.round());
        
    // Trouver le point dans chaque quadrant
    cv.Point? topLeft, topRight, bottomRight, bottomLeft;
    double maxDistTL = 0, maxDistTR = 0, maxDistBR = 0, maxDistBL = 0;
    
    for (final point in points) {
      final dx = point.x - center.x;
      final dy = point.y - center.y;
      final dist = sqrt(dx*dx + dy*dy);
      
      if (dx <= 0 && dy <= 0) { // Top-left quadrant
        if (dist > maxDistTL) {
          maxDistTL = dist;
          topLeft = point;
        }
      } else if (dx >= 0 && dy <= 0) { // Top-right quadrant
        if (dist > maxDistTR) {
          maxDistTR = dist;
          topRight = point;
        }
      } else if (dx >= 0 && dy >= 0) { // Bottom-right quadrant
        if (dist > maxDistBR) {
          maxDistBR = dist;
          bottomRight = point;
        }
      } else if (dx <= 0 && dy >= 0) { // Bottom-left quadrant
        if (dist > maxDistBL) {
          maxDistBL = dist;
          bottomLeft = point;
        }
      }
    }
    
    if (topLeft == null || topRight == null || bottomRight == null || bottomLeft == null) {
      throw Exception('Impossible de trouver les 4 coins du contour');
    }
    
    return [topLeft, topRight, bottomRight, bottomLeft];
  }

  /// Redresse le plateau en utilisant une transformation perspective
  cv.Mat _warpBoard(cv.Mat img, List<cv.Point> corners) {
    
    final srcPoints = cv.VecPoint.fromList(corners);
    final size = 800; // Taille du plateau redressé
    final dstPoints = cv.VecPoint.fromList([
      cv.Point(0, 0),        // top-left
      cv.Point(size, 0),     // top-right
      cv.Point(size, size),  // bottom-right
      cv.Point(0, size),     // bottom-left
    ]);
    
    try {
      final transform = cv.getPerspectiveTransform(srcPoints, dstPoints);
      final warped = cv.warpPerspective(img, transform, (size, size));
      
      if (warped.isEmpty) {
        throw Exception('La transformation perspective a échoué - image vide');
      }
      
      return warped;
    } catch (e) {
      rethrow;
    }
  }


  void _releaseResources(List<cv.Mat> mats) {
    for (final mat in mats) {
      if (!mat.isEmpty) mat.release();
    }
  }
}

// Classes d'interface utilisateur inchangées
class DebugStepsScreen extends StatelessWidget {
  final List<(cv.Mat, String)> debugSteps;
  final VoidCallback onComplete;

  const DebugStepsScreen({
    super.key,
    required this.debugSteps,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Étapes de détection'),
        backgroundColor: Colors.brown[300],
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: onComplete,
            tooltip: 'Passer aux cellules extraites',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: debugSteps.length,
        itemBuilder: (context, index) {
  final (mat, description) = debugSteps[index];
  final (_, encoded) = cv.imencode('.png', mat);
  return Card(
    key: ValueKey(index), // Ajout de la clé unique ici
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.memory(
          encoded,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            description,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
},
      ),
    );
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
              itemCount: 225,
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