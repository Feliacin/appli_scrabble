import 'dart:io';
import 'dart:math';
import 'package:appli_scrabble/board.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'useful_classes.dart';

class BoardScanner {
  final ImagePicker _picker = ImagePicker();
  int _size = 800; // Taille du plateau redressé (modifiable si besoin)

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



      final (debugSteps, cellImages) = await _extractCellImages(imageFile.path);

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
      // // Étape 1 : Conversion en gris
      // final gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY);
      // debugSteps.add((gray.clone(), 'Étape 1 : Conversion en gris'));

      // // Étape 2 : Flou gaussien
      // final blurred = cv.gaussianBlur(gray, (5, 5), 0);
      // debugSteps.add((blurred.clone(), 'Étape 2 : Flou gaussien'));

      // // Étape 3 : Seuil adaptatif pour une meilleure détection des contours
      // final thresh = cv.adaptiveThreshold(
      //   blurred, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY, 11, 2
      // );
      // debugSteps.add((thresh.clone(), 'Étape 3 : Seuil adaptatif'));

      // // Étape 4 : Détection d'arêtes Canny
      // final edges = cv.canny(thresh, 50, 150);
      // debugSteps.add((edges.clone(), 'Étape 4 : Détection d\'arêtes Canny'));

      // // Étape 5 : Détection du contour extérieur du plateau
      // var contours = cv.findContours(edges, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE).$1;
      // final outerBoardContour = contours.reduce((a, b) => cv.contourArea(a) > cv.contourArea(b) ? a : b);

      // final boardContourImg = img.clone();
      // cv.drawContours(boardContourImg, cv.VecVecPoint.fromVecPoint(outerBoardContour), -1, cv.Scalar(0, 255, 0, 0), thickness: 3);
      // debugSteps.add((boardContourImg.clone(), 'Étape 5 : Contour du plateau détecté'));

      // // Étape 6 : Redresser le plateau
      // final boardCorners = _getCorners(outerBoardContour);

      // final cornersDebugImg = img.clone();
      // for (int i = 0; i < boardCorners.length; i++) {
      //   cv.circle(cornersDebugImg, boardCorners[i], 10, cv.Scalar(0, 255, 0, 0), thickness: -1);
      // }
      // debugSteps.add((cornersDebugImg.clone(), 'DEBUG : Coins détectés du plateau'));
      
      // final warpedBoard = _warpBoard(img, boardCorners);
      // debugSteps.add((warpedBoard.clone(), 'Étape 8 : Plateau redressé'));
      
      // final warpedGray = cv.cvtColor(warpedBoard, cv.COLOR_BGR2GRAY);

      // // Flou léger pour cases fines
      // final warpedBlurred = cv.gaussianBlur(warpedGray, (3, 3), 0); 

      // final warpedThresh = cv.adaptiveThreshold(
      //   warpedBlurred, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY_INV, 7, 3 // Plus fin pour petites cases
      // );

      // final kernel = cv.getStructuringElement(cv.MORPH_RECT, (2, 2));
      // final morphed = cv.morphologyEx(warpedThresh, cv.MORPH_OPEN, kernel); // Nettoie bruit, préserve rectangles
      // debugSteps.add((morphed.clone(), 'Étape 9 : Morphologie pour contours de cases'));


      // contours = cv.findContours(morphed, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE).$1; // RETR_LIST pour tous
      // if (contours.isEmpty) throw Exception('Aucun contour de case détecté');

      // // final size = max(img.cols, img.rows); // Taille fixe du plateau redressé
      // final approxCellSize = _size / 15; // Taille estimée d'une case (~53 pour size=800)

      // final minCellArea = (approxCellSize * 0.7) * (approxCellSize * 0.7); // Tolérance
      // final maxCellArea = approxCellSize * approxCellSize;

      // List<cv.Rect> cellRects = [];
      // for (final contour in contours) {
      //   final approx = cv.approxPolyDP(contour, cv.arcLength(contour, true) * 0.03, true);
      //   if (approx.length == 4) { // Rectangle approximé
      //     final area = cv.contourArea(contour);
      //     if (area >= minCellArea && area <= maxCellArea) {
      //       cellRects.add(cv.boundingRect(contour));
      //     }
      //   }
      // }

      // // Debug : Dessiner les cases détectées
      // final cellsDebug = warpedBoard.clone();
      // for (final rect in cellRects) {
      //   cv.rectangle(cellsDebug, rect, cv.Scalar(0, 255, 0, 0), thickness: 2);
      // }
      // debugSteps.add((cellsDebug.clone(), 'Étape 10 : Cases vides détectées'));

      // if (cellRects.isEmpty) throw Exception('Aucune case valide pour extrapoler la grille');

      // int minX = cellRects.map((r) => r.x).reduce(min);
      // int maxX = cellRects.map((r) => r.x + r.width).reduce(max);
      // int minY = cellRects.map((r) => r.y).reduce(min);
      // int maxY = cellRects.map((r) => r.y + r.height).reduce(max);

      // final gridRect = cv.Rect(minX, minY, maxX - minX, maxY - minY);

      // // Vérifie aspect ratio ~1 (carré)
      // // if ((gridRect.width / gridRect.height).abs() - 1 > 0.05) throw Exception('Grille extrapolée non carrée');

      // // Taille de cellule moyenne (plus précise maintenant)
      // final cellSizeW = gridRect.width / 15;
      // final cellSizeH = gridRect.height / 15;

      // // Debug : Bordures extrapolées
      // final bordersDebug = warpedBoard.clone();
      // cv.rectangle(bordersDebug, gridRect, cv.Scalar(255, 0, 0, 0), thickness: 3);
      // debugSteps.add((bordersDebug.clone(), 'Étape 11 : Bordures de grille extrapolées'));
    // Étapes de préparation (identiques)
    final gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY);
    debugSteps.add((gray.clone(), 'Étape 1 : Conversion en gris'));
    
    final blurred = cv.gaussianBlur(gray, (5, 5), 0);
    debugSteps.add((blurred.clone(), 'Étape 2 : Flou gaussien'));
    
    final thresh = cv.adaptiveThreshold(
      blurred, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY_INV, 11, 8
    );
    debugSteps.add((thresh.clone(), 'Étape 3 : Seuil adaptatif'));

 final kernel2 = cv.getStructuringElement(cv.MORPH_RECT, (3, 3)); // Noyau 3x3
    final eroded = cv.erode(thresh, kernel2, iterations: 1); 
    debugSteps.add((eroded.clone(), 'Étape 3c : Erosion pour réduire le bruit'));
final dilated = cv.dilate(eroded, kernel2, iterations: 1);
    debugSteps.add((dilated.clone(), 'Étape 3d : Dilatation pour restaurer les formes'));
    
    // Nouvelle étape : Opérations morphologiques pour nettoyer et régulariser
    final kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
    final morphed = cv.morphologyEx(thresh, cv.MORPH_CLOSE, kernel);
    debugSteps.add((morphed.clone(), 'Étape 3b : Nettoyage morphologique'));

       
    
    // NOUVELLE APPROCHE : Détecter les coins à partir des cases
    final cellDetectionDebug = img.clone();
    final boardCorners = _getBoardCornersFromCells(morphed, cellDetectionDebug, debugSteps);
    debugSteps.add((cellDetectionDebug.clone(), 'Étape 4 : Détection des coins via les cases'));
    
    // Redressement et extraction des cellules (identique au code existant)
    final warpedBoard = _warpBoard(img, boardCorners);
    debugSteps.add((warpedBoard.clone(), 'Étape 5 : Plateau redressé'));
    

      cellImages = [];
      // final margin = 0.08 * cellSizeW; // Marge pour éviter bordures
      // for (int row = 0; row < 15; row++) {
      //   for (int col = 0; col < 15; col++) {
          
      //     final left = (gridRect.x + col * cellSizeW - margin).round();
      //     final top = (gridRect.y + row * cellSizeH - margin).round();
      //     final width = (cellSizeW + 2 * margin).round();
      //     final height = (cellSizeH + 2 * margin).round();
          
      //     final cellRectLocal = cv.Rect(left, top, width, height);
      //     final cellMat = warpedBoard.clone().region(cellRectLocal);
          
      //     final tempPath = '${Directory.systemTemp.path}/cell_${row}_$col.png';
      //     cv.imwrite(tempPath, cellMat);
      //     cellImages.add(File(tempPath));
          
      //     cellMat.release();
          
      //   }
      // }
      
      // Libération des ressources
      // _releaseResources([img, gray, blurred, thresh, edges, warpedBoard, cornersDebugImg, boardContourImg]);


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
    _size = max(max(img.cols, img.rows), 600); // Taille minimale pour OCR fiable
print(_size) ;
    final dstPoints = cv.VecPoint.fromList([
      cv.Point(0, 0),        // top-left
      cv.Point(_size, 0),     // top-right
      cv.Point(_size, _size),  // bottom-right
      cv.Point(0, _size),     // bottom-left
    ]);
    
    try {
      final transform = cv.getPerspectiveTransform(srcPoints, dstPoints);
      final warped = cv.warpPerspective(img, transform, (_size, _size));
      
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
  



// Nouvelle méthode pour détecter les coins du plateau à partir des cases
List<cv.Point> _getBoardCornersFromCells(cv.Mat warpedThresh, cv.Mat debugImage, List<(cv.Mat, String)> debugSteps) {
  final contours = cv.findContours(warpedThresh, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE).$1;
  
  if (contours.isEmpty) throw Exception('Aucun contour détecté');
  
  print('Nombre total de contours détectés : ${contours.length}');
  
  // DEBUG: Dessiner TOUS les contours
  final allContoursDebug = debugImage.clone();
  for (int i = 0; i < contours.length; i++) {
    cv.drawContours(allContoursDebug, cv.VecVecPoint.fromVecPoint(contours[i]), 0, 
                   cv.Scalar(255, 0, 0, 0), thickness: 1);
  }
  debugSteps.add((allContoursDebug.clone(), 'DEBUG: Tous les contours (${contours.length})'));
  
  // 1. Détecter toutes les cases potentielles (quadrilatères)
  List<cv.Rect> validCells = [];
  List<List<cv.Point>> validCellCorners = [];
  
  final imageArea = warpedThresh.cols * warpedThresh.rows;
  final minCellArea = imageArea / 500; // ~1/500 de l'image pour une case (plus permissif)
  final maxCellArea = imageArea / 80;  // ~1/80 de l'image pour une case (plus permissif)
  
  print('Image: ${warpedThresh.cols}x${warpedThresh.rows}, aire: $imageArea');
  print('Aire min/max pour cases: $minCellArea / $maxCellArea');
  
  // DEBUG: Contours filtrés par aire
  final areaFilteredDebug = debugImage.clone();
  int areaFilteredCount = 0;
  
  for (final contour in contours) {
    final area = cv.contourArea(contour);
    
    if (area >= minCellArea && area <= maxCellArea) {
      cv.drawContours(areaFilteredDebug, cv.VecVecPoint.fromVecPoint(contour), -1, 
                     cv.Scalar(0, 255, 255, 0), thickness: 2);
      areaFilteredCount++;
    }
  }
  debugSteps.add((areaFilteredDebug.clone(), 'DEBUG: Contours filtrés par aire ($areaFilteredCount)'));
  print('Contours après filtre d\'aire: $areaFilteredCount');
  
  // DEBUG: Quadrilatères détectés avec différents epsilons
  final quadDebug = debugImage.clone();
  int quadCount = 0;
  
  for (final contour in contours) {
    final area = cv.contourArea(contour);
    if (area < minCellArea || area > maxCellArea) continue;
    
    final rect = cv.boundingRect(contour);
    final aspectRatio = rect.width / rect.height;
    
    // Vérifier que c'est approximativement carré d'abord
    if (aspectRatio < 0.5 || aspectRatio > 1.5) continue;
    
    // Essayer avec un epsilon plus grand pour simplifier davantage
    final epsilon = cv.arcLength(contour, true) * 0.05; // Plus grand (0.05 au lieu de 0.02)
    final approx = cv.approxPolyDP(contour, epsilon, true);
    
    // Accepter les quadrilatères ET les contours qui s'en rapprochent
    if (approx.length >= 4 && approx.length <= 8) {
      cv.drawContours(quadDebug, cv.VecVecPoint.fromVecPoint(approx), -1, 
                     cv.Scalar(255, 255, 0, 0), thickness: 2);
      quadCount++;
      
      // Si c'est assez carré, on le garde
      if (aspectRatio > 0.6 && aspectRatio < 1.4) {
        validCells.add(rect);
        validCellCorners.add(approx.toList());
        
        // Debug: dessiner les cases valides en vert
        cv.drawContours(debugImage, cv.VecVecPoint.fromVecPoint(approx), -1, 
                       cv.Scalar(0, 255, 0, 0), thickness: 2);
      }
    }
  }
  debugSteps.add((quadDebug.clone(), 'DEBUG: Quadrilatères détectés ($quadCount)'));
  print('Quadrilatères détectés: $quadCount');
  
  debugSteps.add((debugImage.clone(), 'DEBUG: Cases valides carrées (${validCells.length})'));
  print('Cases valides finales: ${validCells.length}');
  
  // Ne pas lancer d'exception ici pour pouvoir voir le debug
  // On retournera une liste vide et gérera l'erreur plus tard
  if (validCells.length < 10) {
    print('ATTENTION: Seulement ${validCells.length} cases détectées (minimum recommandé: 10)');
    // Retourner des coins par défaut pour ne pas bloquer le debug
    return [
      cv.Point(0, 0),
      cv.Point(warpedThresh.cols, 0),
      cv.Point(warpedThresh.cols, warpedThresh.rows),
      cv.Point(0, warpedThresh.rows),
    ];
  }
  
  // 2. Trouver les cases extrêmes
  if (validCells.length < 10) {
    // Pas assez de cases pour faire l'extrapolation, on s'arrête ici
    return [
      cv.Point(0, 0),
      cv.Point(debugImage.cols, 0),
      cv.Point(debugImage.cols, debugImage.rows),
      cv.Point(0, debugImage.rows),
    ];
  }
  
  final sortedByX = List<cv.Rect>.from(validCells)..sort((a, b) => a.x.compareTo(b.x));
  final sortedByY = List<cv.Rect>.from(validCells)..sort((a, b) => a.y.compareTo(b.y));
  
  final leftmostCells = sortedByX.take(3).toList();
  final rightmostCells = sortedByX.reversed.take(3).toList();
  final topmostCells = sortedByY.take(3).toList();
  final bottommostCells = sortedByY.reversed.take(3).toList();
  
  // 3. Extraire les lignes des bords à partir des cases extrêmes
  final leftLine = _fitLineFromCells(leftmostCells, isVertical: true);
  final rightLine = _fitLineFromCells(rightmostCells, isVertical: true);
  final topLine = _fitLineFromCells(topmostCells, isVertical: false);
  final bottomLine = _fitLineFromCells(bottommostCells, isVertical: false);
  
  // Debug: dessiner les lignes extrapolées
  _drawLine(debugImage, leftLine, cv.Scalar(255, 0, 0, 0));
  _drawLine(debugImage, rightLine, cv.Scalar(255, 0, 0, 0));
  _drawLine(debugImage, topLine, cv.Scalar(0, 0, 255, 0));
  _drawLine(debugImage, bottomLine, cv.Scalar(0, 0, 255, 0));
  
  // 4. Calculer les intersections pour obtenir les coins
  final topLeft = _getLineIntersection(leftLine, topLine);
  final topRight = _getLineIntersection(rightLine, topLine);
  final bottomRight = _getLineIntersection(rightLine, bottomLine);
  final bottomLeft = _getLineIntersection(leftLine, bottomLine);
  
  if (topLeft == null || topRight == null || bottomRight == null || bottomLeft == null) {
    throw Exception('Impossible de calculer les intersections des lignes');
  }
  
  // Debug: marquer les coins calculés
  cv.circle(debugImage, topLeft, 8, cv.Scalar(0, 255, 255, 0), thickness: -1);
  cv.circle(debugImage, topRight, 8, cv.Scalar(0, 255, 255, 0), thickness: -1);
  cv.circle(debugImage, bottomRight, 8, cv.Scalar(0, 255, 255, 0), thickness: -1);
  cv.circle(debugImage, bottomLeft, 8, cv.Scalar(0, 255, 255, 0), thickness: -1);
  
  return [topLeft, topRight, bottomRight, bottomLeft];
}

// Ajuster une ligne à partir des centres des cases
(cv.Point, cv.Point) _fitLineFromCells(List<cv.Rect> cells, {required bool isVertical}) {
  final points = cells.map((rect) => cv.Point(
    rect.x + rect.width ~/ 2,
    rect.y + rect.height ~/ 2,
  )).toList();
  
  if (points.length < 2) throw Exception('Pas assez de points pour ajuster une ligne');
  
  // Régression linéaire simple
  final n = points.length;
  final sumX = points.fold(0.0, (sum, p) => sum + p.x);
  final sumY = points.fold(0.0, (sum, p) => sum + p.y);
  final sumXY = points.fold(0.0, (sum, p) => sum + p.x * p.y);
  final sumX2 = points.fold(0.0, (sum, p) => sum + p.x * p.x);
  final sumY2 = points.fold(0.0, (sum, p) => sum + p.y * p.y);
  
  final meanX = sumX / n;
  final meanY = sumY / n;
  
  if (isVertical) {
    // Pour une ligne verticale, on utilise X = a*Y + b
    final slope = (sumXY - n * meanX * meanY) / (sumY2 - n * meanY * meanY);
    final intercept = meanX - slope * meanY;
    
    // Étendre la ligne sur toute la hauteur de l'image
    final y1 = 0;
    final y2 = 1000; // Suffisamment grand
    final x1 = (slope * y1 + intercept).round();
    final x2 = (slope * y2 + intercept).round();
    
    return (cv.Point(x1, y1), cv.Point(x2, y2));
  } else {
    // Pour une ligne horizontale, on utilise Y = a*X + b
    final slope = (sumXY - n * meanX * meanY) / (sumX2 - n * meanX * meanX);
    final intercept = meanY - slope * meanX;
    
    // Étendre la ligne sur toute la largeur de l'image
    final x1 = 0;
    final x2 = 1000; // Suffisamment grand
    final y1 = (slope * x1 + intercept).round();
    final y2 = (slope * x2 + intercept).round();
    
    return (cv.Point(x1, y1), cv.Point(x2, y2));
  }
}

// Calculer l'intersection de deux lignes
cv.Point? _getLineIntersection((cv.Point, cv.Point) line1, (cv.Point, cv.Point) line2) {
  final (p1, p2) = line1;
  final (p3, p4) = line2;
  
  final denom = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x);
  
  if (denom.abs() < 1e-10) return null; // Lignes parallèles
  
  final t = ((p1.x - p3.x) * (p3.y - p4.y) - (p1.y - p3.y) * (p3.x - p4.x)) / denom;
  
  final intersectionX = p1.x + t * (p2.x - p1.x);
  final intersectionY = p1.y + t * (p2.y - p1.y);
  
  return cv.Point(intersectionX.round(), intersectionY.round());
}

// Dessiner une ligne sur l'image de debug
void _drawLine(cv.Mat image, (cv.Point, cv.Point) line, cv.Scalar color) {
  final (p1, p2) = line;
  
  // Clipper la ligne aux dimensions de l'image
  final clippedP1 = cv.Point(
    p1.x.clamp(0, image.cols - 1),
    p1.y.clamp(0, image.rows - 1),
  );
  final clippedP2 = cv.Point(
    p2.x.clamp(0, image.cols - 1),
    p2.y.clamp(0, image.rows - 1),
  );
  
  cv.line(image, clippedP1, clippedP2, color, thickness: 3);
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

Future<String> recognizeLetter(File cellImage) async {
    final inputImage = InputImage.fromFilePath(cellImage.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    textRecognizer.close();
    
    // Pour une case Scrabble : prend le premier bloc, premier texte
    if (recognizedText.blocks.isNotEmpty) {
      final text = recognizedText.blocks.first.text.trim().toUpperCase();
      final cleanText = text.replaceAll(RegExp(r'[^A-Z]'), '');
      return cleanText.isNotEmpty ? cleanText[0] : '?';
    }
    return '?'; // Fallback pour vide ou erreur
}
class ExtractedCellsPreview extends StatefulWidget {
  final List<File> cellImages;
  final BoardState boardState;

  const ExtractedCellsPreview({
    super.key,
    required this.cellImages,
    required this.boardState,
  });

  @override
  _ExtractedCellsPreviewState createState() => _ExtractedCellsPreviewState();
}

class _ExtractedCellsPreviewState extends State<ExtractedCellsPreview> {
  late Future<List<String>> _letterFutures;
  bool _showImages = true;

  @override
  void initState() {
    super.initState();
    _letterFutures = _recognizeAllLetters();
  }

  Future<List<String>> _recognizeAllLetters() async {
    List<String> letters = [];
    for (final image in widget.cellImages) {
      final letter = await recognizeLetter(image);
      letters.add(letter);
    }
    return letters;
  }

  Color _getCellBackgroundColor(int row, int col, String letter) {
    // Couleurs pour les cases spéciales (adaptez selon votre logique)
    if (letter.isEmpty || letter == '?') {
      return Colors.grey[100]!;
    }
    return Colors.brown[50]!;
  }

  Color _getLetterColor(String letter) {
    if (letter.isEmpty || letter == '?') {
      return Colors.grey[400]!;
    }
    return Colors.brown[800]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détection OCR - Plateau'),
        backgroundColor: Colors.brown[300],
        actions: [
          IconButton(
            icon: Icon(_showImages ? Icons.text_fields : Icons.image),
            onPressed: () {
              setState(() {
                _showImages = !_showImages;
              });
            },
            tooltip: _showImages ? 'Afficher lettres uniquement' : 'Afficher images',
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de progression et statistiques
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.brown[100],
            child: FutureBuilder<List<String>>(
              future: _letterFutures,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Reconnaissance en cours...'),
                    ],
                  );
                } else if (snapshot.hasData) {
                  final letters = snapshot.data!;
                  final detectedCount = letters.where((l) => l.isNotEmpty && l != '?').length;
                  final totalCount = widget.cellImages.length;
                  
                  return Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Lettres détectées : $detectedCount/$totalCount',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        'Taux : ${(detectedCount / totalCount * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.brown[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          
          // Grille du plateau
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _letterFutures,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Analyse des lettres en cours...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 48, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur lors de la reconnaissance',
                          style: TextStyle(fontSize: 18, color: Colors.red[700]),
                        ),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}'),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData) {
                  return const Center(
                    child: Text(
                      'Aucune donnée disponible',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final letters = snapshot.data!;
                return Container(
                  padding: const EdgeInsets.all(8.0),
                  child: AspectRatio(
                    aspectRatio: 1.0, // Garde le plateau carré
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 15,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 1.0,
                        mainAxisSpacing: 1.0,
                      ),
                      itemCount: 225,
                      itemBuilder: (context, index) {
                        final row = index ~/ 15;
                        final col = index % 15;
                        final imageIndex = row * 15 + col;

                        if (imageIndex < widget.cellImages.length) {
                          final letter = imageIndex < letters.length ? letters[imageIndex] : '?';
                          
                          return GestureDetector(
                            onTap: () {
                              // Afficher un dialogue avec l'image agrandie et la lettre détectée
                              _showCellDetail(context, imageIndex, letter);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getCellBackgroundColor(row, col, letter),
                                border: Border.all(
                                  color: Colors.brown[300]!,
                                  width: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: _showImages ? _buildImageCell(imageIndex, letter) : _buildLetterCell(letter),
                            ),
                          );
                        } else {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Légende
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.brown[50]!, 'Lettre détectée'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.grey[100]!, 'Non détectée'),
              ],
            ),
          ),
          
          // Boutons d'action
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.brown[50],
              border: Border(top: BorderSide(color: Colors.brown[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.brown[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.tune),
                    label: const Text('Réajuster'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      final letters = await _letterFutures;
                      _applyRecognizedLettersToBoard(letters);
                      Navigator.popUntil(
                        context,
                        (route) => route.isFirst,
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Valider les lettres'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCell(int imageIndex, String letter) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: Image.file(
            widget.cellImages[imageIndex],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              letter.isEmpty ? '?' : letter,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLetterCell(String letter) {
    return Center(
      child: Text(
        letter.isEmpty ? '?' : letter.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _getLetterColor(letter),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.brown[300]!),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  void _showCellDetail(BuildContext context, int imageIndex, String letter) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Case ${imageIndex + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.brown[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      widget.cellImages[imageIndex],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.brown[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Lettre détectée :',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        letter.isEmpty ? '?' : letter.toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // board_scanner.dart

void _applyRecognizedLettersToBoard(List<String> letters) {
  // Clear the board's state before applying new letters.
  widget.boardState.letters = List.generate(BoardState.boardSize, (_) => List.filled(BoardState.boardSize, null));
  widget.boardState.blanks = [];
  widget.boardState.tempLetters = [];

  for (int i = 0; i < letters.length; i++) {
    final row = i ~/ BoardState.boardSize;
    final col = i % BoardState.boardSize;
    final letter = letters[i].toUpperCase();

    if (letter.isNotEmpty && letter != '?') {
      final pos = Position(row, col);
      widget.boardState.writeLetter(letter.toLowerCase(), pos);
      // As the letters from the scanner are part of the permanent board state,
      // they do not need to be marked as temporary.
    }
  }

  // Update the possible letters for the next move
  widget.boardState.updatePossibleLetters();
  
  // No need to notify here, `writeLetter` already does it.
}
}