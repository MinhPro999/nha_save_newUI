import '../utils/calculation_utils.dart';

/// Calculator chuyên dụng cho tính toán sơn
class PaintCalculator {
  /// Tính diện tích sơn ngoại thất
  ///
  /// Dựa trên diện tích cần sơn
  static double calculateExteriorPaintQuantity(
    Map<String, dynamic> parameters,
  ) {
    final double area = parameters['area'] ?? 0.0;

    // Validation
    CalculationUtils.validateArea(area);

    return area;
  }

  /// Tính diện tích sơn nội thất
  ///
  /// Tính toán dựa trên diện tích tường đã trát từ project wizard
  /// Kết quả trả về là tổng diện tích cần sơn (m²) để tích hợp với hệ thống tính giá
  static double calculateInteriorPaintQuantity(
    Map<String, dynamic> parameters,
  ) {
    // Kiểm tra xem có dữ liệu từ project wizard không
    if (parameters.containsKey('walls')) {
      return _calculateInteriorPaintFromWalls(parameters);
    }

    // Tương thích ngược: sử dụng tham số area trực tiếp
    final double area = parameters['area'] ?? 0.0;
    CalculationUtils.validateArea(area);
    return area;
  }

  /// Tính diện tích sơn nội thất từ dữ liệu tường chi tiết
  ///
  /// Sử dụng diện tích trát (plasteringArea) từ wall_calculator.dart
  /// Trừ đi diện tích cửa sổ và cửa ra vào để có diện tích sơn chính xác
  static double _calculateInteriorPaintFromWalls(
    Map<String, dynamic> parameters,
  ) {
    final wallsData = parameters['walls'];
    double totalPaintArea = 0.0;

    // Lấy diện tích cửa để trừ đi (nếu có)
    double totalDoorWindowArea = 0.0;
    if (parameters.containsKey('doors')) {
      totalDoorWindowArea = _calculateTotalDoorWindowArea(parameters['doors']);
    }

    if (wallsData.containsKey('walls')) {
      final List<dynamic> walls = wallsData['walls'] as List<dynamic>;

      for (final wall in walls) {
        final double length = CalculationUtils.toDouble(wall['length']);
        final double height = CalculationUtils.toDouble(wall['height']);
        final int plasterSides = wall['plasterSides'] ?? 2;

        // Validation cho từng tường
        CalculationUtils.validateNonNegative(length, 'Chiều dài tường');
        CalculationUtils.validateNonNegative(height, 'Chiều cao tường');

        if (plasterSides < 0 || plasterSides > 2) {
          throw ArgumentError('Số mặt trát phải từ 0-2: $plasterSides');
        }

        // Tính diện tích trát cho tường này (tương đương plasteringArea)
        final double wallArea = length * height;
        final double plasteringArea = wallArea * plasterSides;

        totalPaintArea += plasteringArea;
      }
    }

    // Trừ diện tích cửa sổ và cửa ra vào
    // Chỉ trừ nếu diện tích cửa không vượt quá 80% tổng diện tích tường
    if (totalDoorWindowArea > 0 && totalDoorWindowArea < totalPaintArea * 0.8) {
      totalPaintArea -= totalDoorWindowArea;
    }

    // Validation kết quả cuối cùng
    if (totalPaintArea <= 0) {
      throw ArgumentError('Diện tích sơn nội thất phải lớn hơn 0');
    }

    return totalPaintArea;
  }

  /// Tính tổng diện tích cửa sổ và cửa ra vào
  ///
  /// Sử dụng để trừ khỏi diện tích sơn
  static double _calculateTotalDoorWindowArea(Map<String, dynamic> doorsData) {
    double totalArea = 0.0;

    // Cửa sổ
    if (doorsData.containsKey('windows')) {
      final List<dynamic> windows = doorsData['windows'] as List<dynamic>;
      for (final window in windows) {
        final double width = CalculationUtils.toDouble(window['width']);
        final double height = CalculationUtils.toDouble(window['height']);
        final int quantity = window['quantity'] ?? 1;
        totalArea += width * height * quantity;
      }
    }

    // Cửa ra vào
    if (doorsData.containsKey('doors')) {
      final List<dynamic> doors = doorsData['doors'] as List<dynamic>;
      for (final door in doors) {
        final double width = CalculationUtils.toDouble(door['width']);
        final double height = CalculationUtils.toDouble(door['height']);
        final int quantity = door['quantity'] ?? 1;
        totalArea += width * height * quantity;
      }
    }

    // Cửa cuốn (thường không cần sơn nội thất nhưng vẫn tính để đảm bảo)
    if (doorsData.containsKey('rollingDoors')) {
      final List<dynamic> rollingDoors =
          doorsData['rollingDoors'] as List<dynamic>;
      for (final rollingDoor in rollingDoors) {
        final double width = CalculationUtils.toDouble(rollingDoor['width']);
        final double height = CalculationUtils.toDouble(rollingDoor['height']);
        final int quantity = rollingDoor['quantity'] ?? 1;
        totalArea += width * height * quantity;
      }
    }

    return totalArea;
  }

  /// Tính lượng sơn cần thiết theo loại sơn
  /// [area]: Diện tích cần sơn (m²)
  /// [paintType]: Loại sơn ('primer', 'topcoat', 'emulsion')
  /// [coats]: Số lớp sơn (mặc định 2 lớp)
  /// [coverage]: Độ phủ sơn (m²/lít), mặc định 12 m²/lít
  static double calculatePaintVolume({
    required double area,
    required String paintType,
    int coats = 2,
    double coverage = 12.0,
  }) {
    // Validation
    CalculationUtils.validateArea(area);
    CalculationUtils.validateNonNegative(coverage, 'Độ phủ sơn');
    if (coats <= 0) {
      throw ArgumentError('Số lớp sơn phải lớn hơn 0: $coats');
    }

    // Hệ số điều chỉnh theo loại sơn
    double paintFactor;
    switch (paintType.toLowerCase()) {
      case 'primer': // Sơn lót
        paintFactor = 1.2; // Sơn lót thường cần nhiều hơn
        break;
      case 'topcoat': // Sơn phủ
        paintFactor = 1.0;
        break;
      case 'emulsion': // Sơn nước
        paintFactor = 0.9;
        break;
      case 'enamel': // Sơn dầu
        paintFactor = 1.1;
        break;
      default:
        paintFactor = 1.0;
    }

    // Tính lượng sơn cần thiết (lít)
    final double paintVolume = (area * coats * paintFactor) / coverage;

    // Thêm 10% dự phòng
    return paintVolume * 1.1;
  }

  /// Tính lượng sơn cho tường ngoại thất
  /// [wallArea]: Diện tích tường (m²)
  /// [windowArea]: Diện tích cửa sổ (m²)
  /// [doorArea]: Diện tích cửa ra vào (m²)
  /// [coats]: Số lớp sơn (mặc định 3 lớp: 1 lót + 2 phủ)
  static double calculateExteriorWallPaint({
    required double wallArea,
    double windowArea = 0.0,
    double doorArea = 0.0,
    int coats = 3,
  }) {
    // Validation
    CalculationUtils.validateArea(wallArea);
    CalculationUtils.validateArea(windowArea);
    CalculationUtils.validateArea(doorArea);

    // Tính diện tích thực tế cần sơn (trừ cửa sổ và cửa ra vào)
    final double actualArea = wallArea - windowArea - doorArea;

    if (actualArea <= 0) {
      throw ArgumentError('Diện tích cần sơn phải lớn hơn 0');
    }

    // Tính lượng sơn lót (1 lớp)
    final double primerVolume = calculatePaintVolume(
      area: actualArea,
      paintType: 'primer',
      coats: 1,
      coverage: 10.0, // Sơn lót có độ phủ thấp hơn
    );

    // Tính lượng sơn phủ (2 lớp)
    final double topcoatVolume = calculatePaintVolume(
      area: actualArea,
      paintType: 'topcoat',
      coats: coats - 1,
      coverage: 12.0,
    );

    return primerVolume + topcoatVolume;
  }

  /// Tính lượng sơn cho tường nội thất
  /// [wallArea]: Diện tích tường (m²)
  /// [ceilingArea]: Diện tích trần (m²)
  /// [openingArea]: Diện tích các lỗ mở (cửa, cửa sổ) (m²)
  /// [coats]: Số lớp sơn (mặc định 2 lớp)
  static double calculateInteriorWallPaint({
    required double wallArea,
    double ceilingArea = 0.0,
    double openingArea = 0.0,
    int coats = 2,
  }) {
    // Validation
    CalculationUtils.validateArea(wallArea);
    CalculationUtils.validateArea(ceilingArea);
    CalculationUtils.validateArea(openingArea);

    // Tính tổng diện tích cần sơn
    final double totalArea = wallArea + ceilingArea - openingArea;

    if (totalArea <= 0) {
      throw ArgumentError('Diện tích cần sơn phải lớn hơn 0');
    }

    // Sơn nội thất thường dùng sơn nước
    return calculatePaintVolume(
      area: totalArea,
      paintType: 'emulsion',
      coats: coats,
      coverage: 14.0, // Sơn nước có độ phủ cao hơn
    );
  }

  /// Tính lượng sơn cho cửa và khung cửa
  /// [doorCount]: Số lượng cửa
  /// [windowCount]: Số lượng cửa sổ
  /// [doorArea]: Diện tích trung bình một cửa (m²), mặc định 2.1m²
  /// [windowArea]: Diện tích trung bình một cửa sổ (m²), mặc định 1.5m²
  /// [coats]: Số lớp sơn (mặc định 3 lớp)
  static double calculateDoorWindowPaint({
    int doorCount = 0,
    int windowCount = 0,
    double doorArea = 2.1,
    double windowArea = 1.5,
    int coats = 3,
  }) {
    // Validation
    if (doorCount < 0 || windowCount < 0) {
      throw ArgumentError('Số lượng cửa không thể âm');
    }

    // Tính tổng diện tích cửa
    final double totalDoorArea = doorCount * doorArea;
    final double totalWindowArea = windowCount * windowArea;
    final double totalArea = totalDoorArea + totalWindowArea;

    if (totalArea <= 0) return 0.0;

    // Cửa thường sơn bằng sơn dầu hoặc sơn gỗ
    return calculatePaintVolume(
      area: totalArea,
      paintType: 'enamel',
      coats: coats,
      coverage: 10.0, // Sơn dầu có độ phủ thấp hơn
    );
  }

  /// Tính lượng sơn cho mái tôn
  /// [roofArea]: Diện tích mái (m²)
  /// [coats]: Số lớp sơn (mặc định 2 lớp)
  /// [slopeFactor]: Hệ số độ dốc mái (mặc định 1.1)
  static double calculateRoofPaint({
    required double roofArea,
    int coats = 2,
    double slopeFactor = 1.1,
  }) {
    // Validation
    CalculationUtils.validateArea(roofArea);
    CalculationUtils.validateNonNegative(slopeFactor, 'Hệ số độ dốc');

    // Điều chỉnh diện tích theo độ dốc mái
    final double adjustedArea = roofArea * slopeFactor;

    // Sơn mái tôn cần sơn chống rỉ
    return calculatePaintVolume(
      area: adjustedArea,
      paintType: 'primer', // Sơn chống rỉ
      coats: coats,
      coverage: 8.0, // Sơn chống rỉ có độ phủ thấp
    );
  }

  /// Tính tổng lượng sơn cho toàn bộ công trình
  /// [exteriorWallArea]: Diện tích tường ngoại thất (m²)
  /// [interiorWallArea]: Diện tích tường nội thất (m²)
  /// [ceilingArea]: Diện tích trần (m²)
  /// [roofArea]: Diện tích mái (m²)
  /// [doorCount]: Số lượng cửa
  /// [windowCount]: Số lượng cửa sổ
  static Map<String, double> calculateTotalPaint({
    double exteriorWallArea = 0.0,
    double interiorWallArea = 0.0,
    double ceilingArea = 0.0,
    double roofArea = 0.0,
    int doorCount = 0,
    int windowCount = 0,
  }) {
    Map<String, double> paintQuantities = {};

    // Sơn tường ngoại thất
    if (exteriorWallArea > 0) {
      paintQuantities['exterior_paint'] = calculateExteriorWallPaint(
        wallArea: exteriorWallArea,
      );
    }

    // Sơn tường nội thất
    if (interiorWallArea > 0 || ceilingArea > 0) {
      paintQuantities['interior_paint'] = calculateInteriorWallPaint(
        wallArea: interiorWallArea,
        ceilingArea: ceilingArea,
      );
    }

    // Sơn cửa
    if (doorCount > 0 || windowCount > 0) {
      paintQuantities['door_window_paint'] = calculateDoorWindowPaint(
        doorCount: doorCount,
        windowCount: windowCount,
      );
    }

    // Sơn mái
    if (roofArea > 0) {
      paintQuantities['roof_paint'] = calculateRoofPaint(roofArea: roofArea);
    }

    return paintQuantities;
  }

  /// Tính chi phí sơn
  /// [paintVolume]: Thể tích sơn (lít)
  /// [paintPrice]: Giá sơn (VND/lít)
  /// [laborCost]: Chi phí nhân công (VND/m²)
  /// [area]: Diện tích sơn (m²)
  static double calculatePaintCost({
    required double paintVolume,
    required double paintPrice,
    double laborCost = 0.0,
    double area = 0.0,
  }) {
    final double materialCost = paintVolume * paintPrice;
    final double totalLaborCost = laborCost * area;

    return materialCost + totalLaborCost;
  }
}
