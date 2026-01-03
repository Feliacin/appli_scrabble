import 'dart:io';
import 'dart:math';
import 'package:appli_scrabble/board.dart';
import 'package:appli_scrabble/main.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'useful_classes.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

// =============================================================================
// 1. CONTROLLEUR PRINCIPAL
// =============================================================================

class BoardScanner {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  /// Lance le processus complet
  Future<void> scanBoard(BuildContext context, BoardState boardState) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // 1. Choix de l'image
    final source = await _showSourceDialog(context);
    if (source == null) return;

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (pickedFile == null) return;

    // 2. Affichage du Loader (Indispensable car le traitement est lourd)
    // On utilise un dialog bloquant pour éviter les interactions pendant le calcul
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const _ProcessingDialog(),
    );

    try {
      // 3. Traitement OpenCV (Découpage des cases)
      final result = await BoardImageProcessor.process(pickedFile.path);

      if (!context.mounted) return;

      // 4. BRANCHEMENT SELON LE MODE (DEBUG vs NORMAL)
      if (appState.debugMode) {
        // --- MODE DÉVELOPPEUR ---
        // On ferme le loader et on ouvre l'écran de visualisation des étapes
        Navigator.pop(context); 
        _navigateToDebugFlow(context, result, boardState);
      
      } else {
        // --- MODE NORMAL (SILENCIEUX) ---
        // On reste dans le loader, mais on lance l'OCR en fond
        
        // a. Reconnaissance OCR de toutes les cases
        final letters = await _ocrService.recognizeBatch(result.cellImages);
        
        // b. Mise à jour du plateau
        _applyLettersToBoardState(boardState, letters);
        
        // c. Fin : On ferme le loader et on notifie
        if (context.mounted) {
          Navigator.pop(context); // Ferme le loader
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Scan terminé : ${letters.where((l) => l.isNotEmpty).length} lettres trouvées"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Ferme le loader en cas d'erreur
        _showError(context, e.toString());
      }
    }
  }

  // --- Helpers privés pour le BoardScanner ---

  Future<ImageSource?> _showSourceDialog(BuildContext context) {
    return showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Source de l\'image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDebugFlow(BuildContext context, ScanResult result, BoardState boardState) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DebugStepsScreen(
          debugSteps: result.debugSteps,
          onComplete: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExtractedCellsPreview(
                cellImages: result.cellImages,
                boardState: boardState,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _applyLettersToBoardState(BoardState boardState, List<String> letters) {
    // Réinitialisation propre avant remplissage
    // Note: Adaptez selon votre implémentation exacte de clearBoard() si elle existe
    boardState.letters = List.generate(15, (_) => List.filled(15, null));
    boardState.blanks = []; 
    // boardState.tempLetters = []; // Si nécessaire

    for (int i = 0; i < letters.length; i++) {
      if (i >= 225) break;
      
      final letter = letters[i].toUpperCase();
      // On ignore les cases vides ou incertaines '?'
      if (letter.isNotEmpty && letter != '?') {
        final row = i ~/ 15;
        final col = i % 15;
        boardState.writeLetter(letter.toLowerCase(), Position(row, col));
      }
    }
    boardState.updatePossibleLetters();
    // Le notifyListeners() est généralement appelé dans writeLetter ou updatePossibleLetters
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur : $message"), backgroundColor: Colors.red),
    );
  }
}

// =============================================================================
// 2. SERVICES 
// =============================================================================

class ScanResult {
  final List<(cv.Mat, String)> debugSteps;
  final List<File> cellImages;
  ScanResult({required this.debugSteps, required this.cellImages});
}

class OcrService {
  /// Reconnaît une seule image
  Future<String> predict(File imageFile) async {
    try {
      final img = cv.imread(imageFile.path, flags: cv.IMREAD_GRAYSCALE);
      if (img.isEmpty) return ""; // Image invalide

      final letter = _fastClassify(img);
      if (letter != null) return letter;

      String text = await FlutterTesseractOcr.extractText(
        imageFile.path, 
        language: 'eng',
        args: {
          "psm": "10", // Single character mode
          "tessedit_char_whitelist": "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        }
      );
      if (text.length > 1) text = ""; // Confusion
      return text;
    } catch (e) {
      return "";
    }
  }

  String? _fastClassify(cv.Mat img) {
    try {
      final inverted = cv.bitwiseNOT(img); // Inversion pour contours

      // 1. Case blanche -> vide
      if (cv.countNonZero(inverted) == 0) {
        return "";
      }

      // 2. Plus grand contour
      final (contours, _) = cv.findContours(inverted, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
      inverted.release();
      if (contours.isEmpty) return null;
      
      int bestIdx = 0;
      double bestArea = 0.0;
      for (int i = 0; i < contours.length; i++) {
        final area = cv.contourArea(contours[i]).toDouble();
        if (area > bestArea) {
          bestArea = area;
          bestIdx = i;
        }
      }
      final rect = cv.boundingRect(contours[bestIdx]);

      final minWidthRatio = 0.2; // <20% largeur pour vertical fin
      final minHeightRatio = 0.2; // <20% hauteur pour horizontal fin
      final barRatioThreshold = 3; // Ratio pour confirmer barre

      // 3. Barre verticale -> 'I' (hauteur grande, largeur fine)
      if (rect.width < img.cols * minWidthRatio && rect.height / rect.width > barRatioThreshold) {
        return "I";
      }

      // 4. Barre horizontale -> vide (largeur grande, hauteur fine)
      if (rect.height < img.rows * minHeightRatio && rect.width / rect.height > barRatioThreshold) {
        return "";
      }

      return null;
    } finally {
      img.release();
    }
  }

  /// Reconnaît une liste d'images (pour le mode silencieux)
  Future<List<String>> recognizeBatch(List<File> images) async {
    // Future.wait permet de paralléliser autant que possible
    return await Future.wait(images.map((file) => predict(file)));
  }
}

class BoardImageProcessor {
  static const int _targetSize = 800;
  static const int _gridSize = 15;

  static Future<ScanResult> process(String imagePath) async {
    final List<(cv.Mat, String)> steps = [];
    final img = cv.imread(imagePath);
    if (img.isEmpty) throw Exception('Impossible de charger l\'image');

    try {
      // 1. Prétraitements
      final gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY);
      steps.add((gray.clone(), '0. Grayscale')); // Clone pour affichage debug
      
      final blurred = cv.gaussianBlur(gray, (5, 5), 0);
      final edges = cv.canny(blurred, 50, 150);
      
      final kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
      final closedEdges = cv.morphologyEx(edges, cv.MORPH_CLOSE, kernel);
      steps.add((closedEdges.clone(), '1. Contours (Canny)'));

      // 2. Détection Grille
      final debugMat = img.clone();
      final corners = _findGridCorners(closedEdges, debugMat, steps);
      steps.add((debugMat, '2. Coins détectés'));

      // 3. Perspective Warp
      final warped = _warpPerspective(img, corners);
      steps.add((warped.clone(), '3. Plateau redressé'));

      // 4. Découpage Cellules
      final cells = _sliceCells(warped);
      
      return ScanResult(debugSteps: steps, cellImages: cells);
    } catch (e) {
      // On relance l'erreur pour que le controller gère l'UI
      rethrow; 
    }
  }

  // --- Méthodes privées de Logique Mathématique (Static) ---

  static List<File> _sliceCells(cv.Mat board) {
    final List<File> files = [];
    final double step = _targetSize / _gridSize;
    final tempDir = Directory.systemTemp.path;

    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        final rect = cv.Rect(
          (col * step).round(),
          (row * step).round(),
          step.round(),
          step.round(),
        );
        
        // Vérification des bornes
        if (rect.x + rect.width > board.cols || rect.y + rect.height > board.rows) {
          // Création d'une image blanche si hors bornes (rare si warp ok)
          files.add(File('$tempDir/empty_${row}_$col.png')..writeAsBytesSync([0])); // Fallback
          continue;
        }

        final cellMat = board.region(rect);
        final cleanCell = _cleanCellForOcr(cellMat); // Ancien _preprocessCell
        
        final path = '$tempDir/cell_${row}_$col.png';
        cv.imwrite(path, cleanCell);
        files.add(File(path));
        
        cellMat.release();
        cleanCell.release();
      }
    }
    return files;
  }

  static cv.Mat _cleanCellForOcr(cv.Mat cell) {
    final gray = cv.cvtColor(cell, cv.COLOR_BGR2GRAY);
    final (_, binary) = cv.threshold(gray, 0, 255, cv.THRESH_BINARY_INV + cv.THRESH_OTSU);

    // Si trop sombre -> case vide
    if (_countNonZeroRatio(binary) > 0.5) {
      return _createWhiteMat(binary.rows, binary.cols);
    }

    // Gestion contours pour centrer la lettre
    final (contours, hierarchy) = cv.findContours(binary, cv.RETR_CCOMP, cv.CHAIN_APPROX_SIMPLE);
    if (contours.isEmpty) return _createWhiteMat(binary.rows, binary.cols);

    // 3. Zone centrale
    final int centX = (binary.cols * 0.25).toInt();
    final int centY = (binary.rows * 0.25).toInt();
    final int centW = (binary.cols * 0.50).toInt();
    final int centH = (binary.rows * 0.50).toInt();
    final centerRect = cv.Rect(centX, centY, centW, centH);

    int bestContourIdx = -1;
    double maxArea = 0;
    final tempMask = cv.Mat.zeros(binary.rows, binary.cols, cv.MatType.CV_8UC1);

    // 4. Sélectionne la bonne lettre (inchangé : test pixel-perfect)
    for (int i = 0; i < contours.length; i++) {
      if (hierarchy[i].val4 != -1) continue; // Parents seulement

      final rect = cv.boundingRect(contours[i]);
      if (!_rectHasIntersection(rect, centerRect)) continue;

      tempMask.setTo(cv.Scalar.all(0));
      cv.drawContours(tempMask, contours, i, cv.Scalar.all(255), thickness: -1);
      
      final centerRoi = tempMask.region(centerRect);
      final pixelsInCenter = cv.countNonZero(centerRoi);
      centerRoi.release(); 

      if (pixelsInCenter > 0) {
        double area = cv.contourArea(contours[i]);
        if (area > maxArea) {
          maxArea = area;
          bestContourIdx = i;
        }
      }
    }
    tempMask.release();

    // 5. Reconstruction et affinage
    final mask = cv.Mat.zeros(binary.rows, binary.cols, cv.MatType.CV_8UC1);

    if (bestContourIdx != -1) {
      cv.drawContours(mask, contours, bestContourIdx, cv.Scalar.all(255), thickness: -1);
      int childIdx = hierarchy[bestContourIdx].val3;
      while (childIdx != -1) {
        cv.drawContours(mask, contours, childIdx, cv.Scalar.all(0), thickness: -1);
        childIdx = hierarchy[childIdx].val1;
      }

      final kernel = cv.getStructuringElement(cv.MORPH_ELLIPSE, (3, 3));
      final closed = cv.morphologyEx(mask, cv.MORPH_CLOSE, kernel);
      mask.release();

      final smallKernel = cv.getStructuringElement(cv.MORPH_ELLIPSE, (2, 2));
      final eroded = cv.erode(closed, smallKernel, iterations: 1);
      closed.release();

      // Si presque vide après érosion -> case vide
      if (_countNonZeroRatio(eroded) < 0.03) {
        return _createWhiteMat(binary.rows, binary.cols);
      }

      return cv.bitwiseNOT(eroded); 
    } else {
      return _createWhiteMat(binary.rows, binary.cols);
    }
  }

  static List<cv.Point> _findGridCorners(cv.Mat edges, cv.Mat debugViz, List<(cv.Mat, String)> steps) {
    final contours = cv.findContours(edges, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE).$1;
    final List<cv.Rect> validCells = [];
    final imageArea = edges.cols * edges.rows;
    
    final minArea = imageArea / 1200;
    final maxArea = imageArea / 225;

    // Détection des cases
    for (final contour in contours) {
      final area = cv.contourArea(contour);
      if (area < minArea || area > maxArea) continue;

      // Calcul de l'enveloppe convexe
      final hull = cv.VecPoint.fromMat(cv.convexHull(contour));
      final peri = cv.arcLength( hull, true);
      final approx = cv.approxPolyDP(hull, 0.04 * peri, true);

      // On vérifie si la forme simplifiée est un quadrilatère convexe
      if (approx.length == 4 && cv.isContourConvex(approx)) {
        final rect = cv.boundingRect(approx);
        final ratio = rect.width / rect.height;
        
        if (ratio >= 0.75 && ratio <= 1.2) { // Un Scrabble a des cases carrées
          validCells.add(rect);
          cv.drawContours(debugViz, cv.VecVecPoint.fromVecPoint(approx), -1, cv.Scalar(0, 255, 0, 0), thickness: 2);
        }
      }
    }

    // Suppression des cases imbriquées
    validCells.removeWhere((a) {
      return validCells.any((b) {
        if (identical(a, b)) return false;

        return a.x >= b.x - 2 &&
              a.y >= b.y - 2 &&
              (a.x + a.width)  <= (b.x + b.width)  + 2 &&
              (a.y + a.height) <= (b.y + b.height) + 2 &&
              (a.width * a.height) < (b.width * b.height);
      });
    });


    // Suppression des outliers qui se rencontrent parfois sur les bords du plateau    
    List<int> widths = validCells.map((c) => c.width).toList()..sort();
    int medianWidth = widths[widths.length ~/ 2];
    double gapThreshold = medianWidth * 0.1;
    
    _filterEdgeOutliers(validCells, medianWidth, gapThreshold, 'left');
    _filterEdgeOutliers(validCells, medianWidth, gapThreshold, 'right');
    _filterEdgeOutliers(validCells, medianWidth, gapThreshold, 'top');
    _filterEdgeOutliers(validCells, medianWidth, gapThreshold, 'bottom');

    if (validCells.length < 10) {
      throw Exception('Trop peu de cases détectées (${validCells.length}). Rapprochez-vous.');
    }

    // 1. Récupération de tous les coins de toutes les cases détectées
    List<cv.Point> allPoints = [];
    for (var rect in validCells) {
      allPoints.add(cv.Point(rect.x, rect.y));
      allPoints.add(cv.Point(rect.x + rect.width, rect.y));
      allPoints.add(cv.Point(rect.x, rect.y + rect.height));
      allPoints.add(cv.Point(rect.x + rect.width, rect.y + rect.height));
    }

    // 2. Calcul de l'enveloppe convexe de l'ensemble des cases
    final hullVec = cv.VecPoint.fromMat(cv.convexHull(cv.VecPoint.fromList(allPoints)));
    final hullVertices = hullVec.toList();

    // 3. On garde les points proches des segments de l'enveloppe convexes. Cela permet de récupérer tous les points le long des bords, pas seulement les sommets.
    double tolerance = (edges.cols / 15) * 0.3;

    List<cv.Point> candidates = allPoints.where((p) {
      for (int i = 0; i < hullVertices.length; i++) {
        var p1 = hullVertices[i];
        var p2 = hullVertices[(i + 1) % hullVertices.length];
        if (_distPointToSegment(p, p1, p2) < tolerance) return true;
      }
      return false;
    }).toList();
  

    // 4. Filtre des points par clustering pour exclure ceux des lignes intérieures
    double margin = (edges.cols / 15) * 1.5; 

    int minY = candidates.map((p) => p.y).reduce(min);
    List<cv.Point> topP = candidates.where((p) => p.y < minY + margin).toList(); // les points proches du Y min

    int maxY = candidates.map((p) => p.y).reduce(max);
    List<cv.Point> bottomP = candidates.where((p) => p.y > maxY - margin).toList(); // les points proches du Y max

    int minX = candidates.map((p) => p.x).reduce(min);
    List<cv.Point> leftP = candidates.where((p) => p.x < minX + margin).toList(); // les points proches du X minimum 

    int maxX = candidates.map((p) => p.x).reduce(max);
    List<cv.Point> rightP = candidates.where((p) => p.x > maxX - margin).toList(); // les points proches du X maximum

    // Dessin des points pour le debug
    final Map<cv.Point, int> pointUsage = {};
    void countPoint(List<cv.Point> list) {
      for (var p in list) {
        pointUsage[p] = (pointUsage[p] ?? 0) + 1;
      }
    }

    countPoint(topP);
    countPoint(bottomP);
    countPoint(leftP);
    countPoint(rightP);

    for (var entry in pointUsage.entries) {
      final p = entry.key;
      final count = entry.value;
      
      if (count > 1) {
        cv.circle(debugViz, p, 5, cv.Scalar(255, 255, 255, 0), thickness: -1); // Blanc (point appartenant à deux bords)
      } else {
        if (topP.contains(p)) cv.circle(debugViz, p, 4, cv.Scalar(0, 0, 255, 0), thickness: -1); // Rouge
        if (bottomP.contains(p)) cv.circle(debugViz, p, 4, cv.Scalar(0, 255, 255, 0), thickness: -1); // Jaune
        if (leftP.contains(p)) cv.circle(debugViz, p, 4, cv.Scalar(255, 0, 0, 0), thickness: -1); // Bleu
        if (rightP.contains(p)) cv.circle(debugViz, p, 4, cv.Scalar(255, 0, 255, 0), thickness: -1); // Violet
      }
    }

    // 5. Régression linéaire
    final topLine = _fitLineRansac(topP, isVertical: false);
    final bottomLine = _fitLineRansac(bottomP, isVertical: false);
    final leftLine = _fitLineRansac(leftP, isVertical: true);
    final rightLine = _fitLineRansac(rightP, isVertical: true);

    _drawLine(debugViz, topLine, cv.Scalar(0, 0, 255, 0));    // Rouge
    _drawLine(debugViz, bottomLine, cv.Scalar(0, 255, 255, 0)); // Jaune
    _drawLine(debugViz, leftLine, cv.Scalar(255, 0, 0, 0));   // Bleu
    _drawLine(debugViz, rightLine, cv.Scalar(255, 0, 255, 0)); // Violet

    // 6. Intersections pour les coins finaux
    final topLeft = _getLineIntersection(leftLine, topLine);
    final topRight = _getLineIntersection(rightLine, topLine);
    final bottomRight = _getLineIntersection(rightLine, bottomLine);
    final bottomLeft = _getLineIntersection(leftLine, bottomLine);

    if (topLeft == null || topRight == null || bottomRight == null || bottomLeft == null) {
      throw Exception('Échec de l\'intersection des bords');
    }

    return [topLeft, topRight, bottomRight, bottomLeft];
  }

  static cv.Mat _warpPerspective(cv.Mat img, List<cv.Point> corners) {
    final src = cv.VecPoint.fromList(corners);
    final dst = cv.VecPoint.fromList([
      cv.Point(0, 0), cv.Point(_targetSize, 0),
      cv.Point(_targetSize, _targetSize), cv.Point(0, _targetSize)
    ]);
    final m = cv.getPerspectiveTransform(src, dst);
    return cv.warpPerspective(img, m, (_targetSize, _targetSize));
  }

  static void _filterEdgeOutliers(
    List<cv.Rect> cells, int medianWidth, double gapThreshold, String edge, {int searchLimit = 10}) {
    if (cells.isEmpty) return;
    
    // Tri selon le bord à traiter
    switch (edge) {
      case 'left':
        cells.sort((a, b) => a.x.compareTo(b.x));
        break;
      case 'right':
        cells.sort((a, b) => b.x.compareTo(a.x)); // Ordre décroissant
        break;
      case 'top':
        cells.sort((a, b) => a.y.compareTo(b.y));
        break;
      case 'bottom':
        cells.sort((a, b) => b.y.compareTo(a.y)); // Ordre décroissant
        break;
    }
    
    searchLimit = min(cells.length, searchLimit);
    int cutIndex = -1;
    
    // Calcul de la position maximale selon le bord
    int maxPosition = _getMaxPosition(cells[0], edge);
    
    for (int i = 1; i < searchLimit; i++) {
      cv.Rect current = cells[i];
      int gap = _calculateGap(current, maxPosition, edge);
      
      if (gap > gapThreshold) {
        cutIndex = i;
        break;
      }
      
      maxPosition = max(maxPosition, _getMaxPosition(current, edge));
    }
    
    if (cutIndex != -1) {
      cells.removeRange(0, cutIndex);
    }
  }

  static int _getMaxPosition(cv.Rect rect, String edge) {
    switch (edge) {
      case 'left':
        return rect.x + rect.width;
      case 'right':
        return -rect.x; // Négatif pour cohérence avec l'ordre décroissant
      case 'top':
        return rect.y + rect.height;
      case 'bottom':
        return -rect.y; // Négatif pour cohérence avec l'ordre décroissant
      default:
        return 0;
    }
  }

  static int _calculateGap(cv.Rect current, int maxPosition, String edge) {
    switch (edge) {
      case 'left':
        return current.x - maxPosition;
      case 'right':
        return (-current.x - current.width) - maxPosition;
      case 'top':
        return current.y - maxPosition;
      case 'bottom':
        return (-current.y - current.height) - maxPosition;
      default:
        return 0;
    }
  }

  static (cv.Point, cv.Point) _fitLineRansac(List<cv.Point> points, {
    required bool isVertical, 
    double threshold = 4.0,
    int iterations = 100
  }) {
    if (points.length < 2) return (cv.Point(0, 0), cv.Point(0, 0));

    Random rng = Random();
    List<cv.Point> bestInliers = [];
    
    for (int i = 0; i < iterations; i++) {
      // 1. Sélectionner 2 points au hasard pour créer un modèle candidat
      var p1 = points[rng.nextInt(points.length)];
      var p2 = points[rng.nextInt(points.length)];
      if (p1 == p2) continue;

      // 2. Compter combien de points "adhèrent" à cette ligne
      List<cv.Point> currentInliers = [];
      for (var p in points) {
        if (_distPointToLine(p, p1, p2) < threshold) {
          currentInliers.add(p);
        }
      }

      // 3. Si on a trouvé un meilleur modèle, on le garde
      if (currentInliers.length > bestInliers.length) {
        bestInliers = currentInliers;
      }
    }

    // 4. On refait la régression finale uniquement sur les meilleurs points trouvés
    return _fitLine(bestInliers.isNotEmpty ? bestInliers : points, isVertical: isVertical);
  }
  
  // Helpers utilitaires
  static double _countNonZeroRatio(cv.Mat m) => cv.countNonZero(m) / (m.rows * m.cols);
  static cv.Mat _createWhiteMat(int r, int c) => cv.Mat.fromScalar(r, c, cv.MatType.CV_8UC1, cv.Scalar.all(255));
  static bool _rectHasIntersection(cv.Rect a, cv.Rect b) {
    return a.x < b.x + b.width &&
           a.x + a.width > b.x &&
           a.y < b.y + b.height &&
           a.y + a.height > b.y;
  }
  static double _distPointToLine(cv.Point p, cv.Point a, cv.Point b) {
    final double numerator = ((b.x - a.x) * (a.y - p.y) - (a.x - p.x) * (b.y - a.y)).abs().toDouble();
    final double denominator = sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2));
    return denominator == 0 ? 0 : numerator / denominator;
  }
  static double _distPointToSegment(cv.Point p, cv.Point a, cv.Point b) {
    final double dx = (b.x - a.x).toDouble();
    final double dy = (b.y - a.y).toDouble();
    final double l2 = dx * dx + dy * dy;
    
    if (l2 == 0) return sqrt(pow(p.x - a.x, 2) + pow(p.y - a.y, 2));
    
    // t est la projection du point sur la droite, bridée entre 0 et 1
    double t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / l2;
    t = t.clamp(0.0, 1.0);
    
    return sqrt(pow(p.x - (a.x + t * dx), 2) + pow(p.y - (a.y + t * dy), 2));
  }
  static (cv.Point, cv.Point) _fitLine(List<cv.Point> points, {required bool isVertical}) { // Régression linéaire simple
    int n = points.length;
    double sumX = 0, sumY = 0;
    for (var p in points) { sumX += p.x; sumY += p.y; }
    double meanX = sumX / n;
    double meanY = sumY / n;

    double sxx = 0, sxy = 0, syy = 0;
    for (var p in points) {
      sxx += (p.x - meanX) * (p.x - meanX);
      sxy += (p.x - meanX) * (p.y - meanY);
      syy += (p.y - meanY) * (p.y - meanY);
    }

    // Angle de la ligne (PCA / Total Least Squares)
    double angle = 0.5 * atan2(2 * sxy, sxx - syy);
    double vx = cos(angle);
    double vy = sin(angle);

    // Projection directe vers les coordonnées extrêmes (-2000, 4000)
    if (isVertical) {
      // x = meanX + (vx/vy) * (y - meanY)
      if (vy.abs() < 1e-6) return (cv.Point(meanX.round(), -2000), cv.Point(meanX.round(), 4000));
      double slope = vx / vy;
      int x1 = (meanX + slope * (-2000 - meanY)).round();
      int x2 = (meanX + slope * (4000 - meanY)).round();
      return (cv.Point(x1, -2000), cv.Point(x2, 4000));
    } else {
      // y = meanY + (vy/vx) * (x - meanX)
      if (vx.abs() < 1e-6) return (cv.Point(-2000, meanY.round()), cv.Point(4000, meanY.round()));
      double slope = vy / vx;
      int y1 = (meanY + slope * (-2000 - meanX)).round();
      int y2 = (meanY + slope * (4000 - meanX)).round();
      return (cv.Point(-2000, y1), cv.Point(4000, y2));
    }
  }
  static cv.Point? _getLineIntersection((cv.Point, cv.Point) l1, (cv.Point, cv.Point) l2) {
    final d = (l1.$1.x - l1.$2.x) * (l2.$1.y - l2.$2.y) - (l1.$1.y - l1.$2.y) * (l2.$1.x - l2.$2.x);
    if (d == 0) return null;
    final x = ((l1.$1.x * l1.$2.y - l1.$1.y * l1.$2.x) * (l2.$1.x - l2.$2.x) - (l1.$1.x - l1.$2.x) * (l2.$1.x * l2.$2.y - l2.$1.y * l2.$2.x)) / d;
    final y = ((l1.$1.x * l1.$2.y - l1.$1.y * l1.$2.x) * (l2.$1.y - l2.$2.y) - (l1.$1.y - l1.$2.y) * (l2.$1.x * l2.$2.y - l2.$1.y * l2.$2.x)) / d;
    return cv.Point(x.round(), y.round());
  }
  static void _drawLine(cv.Mat img, (cv.Point, cv.Point) line, cv.Scalar color) {
    cv.line(img, line.$1, line.$2, color, thickness: 3);
  }
}

// =============================================================================
// 3. UI WIDGETS (Debug & Preview)
// =============================================================================

class _ProcessingDialog extends StatelessWidget {
  const _ProcessingDialog();

  @override
  Widget build(BuildContext context) {
    return const Dialog(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text("Analyse du plateau...")),
          ],
        ),
      ),
    );
  }
}

class DebugStepsScreen extends StatelessWidget {
  final List<(cv.Mat, String)> debugSteps;
  final String? errorMessage;
  final VoidCallback? onComplete;

  const DebugStepsScreen({
    super.key, 
    required this.debugSteps, 
    this.errorMessage, 
    this.onComplete
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Étapes Vision'),
        backgroundColor: Colors.red[100],
        actions: [
          if (onComplete != null)
            IconButton(icon: const Icon(Icons.forward), onPressed: onComplete),
        ],
      ),
      body: Column(
        children: [
          if (errorMessage != null)
            Container(
              color: Colors.red,
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: Text(errorMessage!, style: const TextStyle(color: Colors.white)),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: debugSteps.length,
              itemBuilder: (context, i) {
                final (mat, desc) = debugSteps[i];
                final (_, encoded) = cv.imencode('.png', mat);
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(desc, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Image.memory(encoded),
                  const Divider(),
                ]);
              },
            ),
          ),
        ],
      ),
    );
  }
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
  State<ExtractedCellsPreview> createState() => _ExtractedCellsPreviewState();
}

class _ExtractedCellsPreviewState extends State<ExtractedCellsPreview> {
  final OcrService _ocrService = OcrService();
  List<String> _recognizedLetters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _runOcrAnalysis();
  }

  Future<void> _runOcrAnalysis() async {
    final results = await _ocrService.recognizeBatch(widget.cellImages);
    if (mounted) {
      setState(() {
        _recognizedLetters = results;
        _isLoading = false;
      });
      // Rafraîchir le cache des images
      _evictCachedImages();
    }
  }

  Future<void> _evictCachedImages() async {
    for (final file in widget.cellImages) {
      await FileImage(file).evict();
    }
  }

  Future<void> _exportImages() async {
    final archive = Archive();
    for (int i = 0; i < widget.cellImages.length; i++) {
      final file = widget.cellImages[i];
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final row = i ~/ 15;
        final col = i % 15;
        final filename = 'cell_${row.toString().padLeft(2, '0')}_${col.toString().padLeft(2, '0')}.png';
        archive.addFile(ArchiveFile(filename, bytes.length, bytes));
      }
    }

    final zipEncoder = ZipEncoder();
    final encodedArchive = zipEncoder.encode(archive);
    
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/scrabble_debug_dataset.zip');
    await zipFile.writeAsBytes(encodedArchive);

    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [XFile(zipFile.path)],
      text: 'Dataset debug Scrabble',
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  void _applyRecognizedLettersToBoard(List<String> letters) {
    widget.boardState.letters = List.generate(15, (_) => List.filled(15, null));
    widget.boardState.blanks = [];
    
    for (int i = 0; i < letters.length; i++) {
      if (i >= 225) break;
      final letter = letters[i];
      if (letter.isNotEmpty && letter != '?') {
        final row = i ~/ 15;
        final col = i % 15;
        widget.boardState.writeLetter(letter.toLowerCase(), Position(row, col));
      }
    }
    widget.boardState.updatePossibleLetters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation'),
        backgroundColor: Colors.brown[300],
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter les images',
            onPressed: _exportImages,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Valider le plateau',
            onPressed: !_isLoading ? () {
              _applyRecognizedLettersToBoard(_recognizedLetters);
              Navigator.popUntil(context, (route) => route.isFirst);
            } : null,
          )
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 15,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
              childAspectRatio: 1.0, // Carré pour ne pas déformer
            ),
            itemCount: 225, 
            itemBuilder: (context, index) {
              if (index >= widget.cellImages.length) {
                 return Container(color: Colors.grey[200]);
              }

              final file = widget.cellImages[index];
              final rawLetter = (index < _recognizedLetters.length) ? _recognizedLetters[index] : '';
              final letter = rawLetter.trim().toUpperCase();
              final isDetected = letter.isNotEmpty && letter != '?';
              
              return GestureDetector(
                onTap: () => _showCellDetail(context, file, rawLetter, index),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.brown[200]!, width: 0.5),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image en fond complet
                      Image.file(
                        file, 
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 10),
                      ),
                      
                      // Lettre en overlay discret (coin bas-droit, fond semi-transparent marron)
                      if (isDetected)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[500]!.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              letter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9, 
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  void _showCellDetail(BuildContext context, File file, String letter, int index) {
      final cleanLetter = letter.trim().toUpperCase();
      final displayLetter = (cleanLetter.isNotEmpty && cleanLetter != '?') ? cleanLetter : "Aucune";

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: Text("Case ${index + 1}"),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.brown),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Image.file(file, fit: BoxFit.cover)
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Lettre détectée :"),
                    const SizedBox(height: 8),
                    Text(
                        displayLetter, 
                        style: TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.bold, 
                          color: displayLetter == "Aucune" ? Colors.grey : Colors.brown[800]
                        )
                    ),
                ],
            ),
            actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx), 
                    child: const Text("Fermer")
                )
            ],
        ),
      );
  }
}
