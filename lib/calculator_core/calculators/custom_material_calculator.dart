import '../constants/construction_constants.dart';
import '../utils/calculation_utils.dart';

/// Calculator chuyên dụng cho tính toán vật liệu tùy chỉnh
class CustomMaterialCalculator {
  /// Tính khối lượng vật liệu tùy chỉnh
  ///
  /// Hỗ trợ nhiều đơn vị đo lường khác nhau
  static double calculateQuantity(
    Map<String, dynamic> parameters,
    String measurementUnit,
  ) {
    switch (measurementUnit) {
      case 'squareMeter':
        return _calculateByArea(parameters);
      case 'cubicMeter':
        return _calculateByVolume(parameters);
      case 'meter':
        return _calculateByLength(parameters);
      case 'piece':
        return _calculateByPiece(parameters);
      case 'ton':
        return _calculateByWeight(parameters);
      case 'kilogram':
        return _calculateByKilogram(parameters);
      case 'liter':
        return _calculateByLiter(parameters);
      default:
        return _calculateByQuantity(parameters);
    }
  }

  /// Tính theo diện tích (m²)
  static double _calculateByArea(Map<String, dynamic> parameters) {
    final double area = parameters['area'] ?? 0.0;
    CalculationUtils.validateArea(area);
    return area;
  }

  /// Tính theo thể tích (m³)
  static double _calculateByVolume(Map<String, dynamic> parameters) {
    final double volume = parameters['volume'] ?? 0.0;
    CalculationUtils.validateVolume(volume);
    return volume;
  }

  /// Tính theo chiều dài (m)
  static double _calculateByLength(Map<String, dynamic> parameters) {
    final double length = parameters['length'] ?? 0.0;
    CalculationUtils.validateNonNegative(length, 'Chiều dài');
    return length;
  }

  /// Tính theo số lượng viên/cái
  static double _calculateByPiece(Map<String, dynamic> parameters) {
    // Nếu có kích thước viên và có thông số tường, tính theo thể tích
    if (parameters.containsKey('pieceLength') &&
        parameters.containsKey('pieceWidth') &&
        parameters.containsKey('pieceHeight') &&
        parameters.containsKey('length') &&
        parameters.containsKey('width') &&
        parameters.containsKey('height')) {
      return _calculateCustomMaterialByDimensions(parameters);
    } else {
      final int quantity = parameters['quantity'] ?? 0;
      if (quantity < 0) {
        throw ArgumentError('Số lượng không thể âm: $quantity');
      }
      return quantity.toDouble();
    }
  }

  /// Tính theo khối lượng (tấn)
  static double _calculateByWeight(Map<String, dynamic> parameters) {
    final double weight = parameters['weight'] ?? 0.0;
    CalculationUtils.validateNonNegative(weight, 'Khối lượng');
    return weight;
  }

  /// Tính theo khối lượng (kg)
  static double _calculateByKilogram(Map<String, dynamic> parameters) {
    final double weight = parameters['weight'] ?? 0.0;
    CalculationUtils.validateNonNegative(weight, 'Khối lượng');
    // Chuyển từ kg sang tấn
    return CalculationUtils.kgToTon(weight);
  }

  /// Tính theo thể tích chất lỏng (lít)
  static double _calculateByLiter(Map<String, dynamic> parameters) {
    final double volume = parameters['volume'] ?? 0.0;
    CalculationUtils.validateNonNegative(volume, 'Thể tích');
    // Chuyển từ lít sang m³
    return volume / 1000.0;
  }

  /// Tính theo số lượng chung
  static double _calculateByQuantity(Map<String, dynamic> parameters) {
    final int quantity = parameters['quantity'] ?? 0;
    if (quantity < 0) {
      throw ArgumentError('Số lượng không thể âm: $quantity');
    }
    return quantity.toDouble();
  }

  /// Tính số lượng vật liệu tùy chỉnh dựa trên kích thước
  static double _calculateCustomMaterialByDimensions(
    Map<String, dynamic> parameters,
  ) {
    final double length = parameters['length'] ?? 0.0;
    final double width = parameters['width'] ?? 0.0;
    final double height = parameters['height'] ?? 0.0;
    final double pieceLength = parameters['pieceLength'] ?? 0.0;
    final double pieceWidth = parameters['pieceWidth'] ?? 0.0;
    final double pieceHeight = parameters['pieceHeight'] ?? 0.0;

    // Validation
    CalculationUtils.validateNonNegative(length, 'Chiều dài tường');
    CalculationUtils.validateNonNegative(width, 'Chiều rộng tường');
    CalculationUtils.validateNonNegative(height, 'Chiều cao tường');
    CalculationUtils.validateNonNegative(pieceLength, 'Chiều dài viên');
    CalculationUtils.validateNonNegative(pieceWidth, 'Chiều rộng viên');
    CalculationUtils.validateNonNegative(pieceHeight, 'Chiều cao viên');

    // Tính thể tích tường và viên
    final double wallVolume = length * width * height;
    final double pieceVolume = pieceLength * pieceWidth * pieceHeight;

    if (pieceVolume <= 0) {
      return 0.0;
    }

    // Tính số lượng viên cần thiết (thêm 5% cho hao hụt)
    return (wallVolume / pieceVolume) * 1.05;
  }

  /// Tính khối lượng xi măng và cát bê tông
  static double calculateConcreteSandQuantity(Map<String, dynamic> parameters) {
    final double volume = parameters['volume'] ?? 0.0;
    CalculationUtils.validateVolume(volume);
    
    // Tính lượng cát bê tông (0.7 m³ cát trên mỗi m³ bê tông)
    return volume * 0.7;
  }

  /// Tính diện tích thạch cao
  ///
  /// Ưu tiên sử dụng giá trị gypsumCeilingArea từ Step5 nếu có
  static double calculateGypsumQuantity(Map<String, dynamic> parameters) {
    if (parameters.containsKey('gypsumCeilingArea')) {
      final double area = parameters['gypsumCeilingArea'] ?? 0.0;
      CalculationUtils.validateArea(area);
      return area;
    }
    // Nếu không có, sử dụng tham số area (tương thích ngược)
    final double area = parameters['area'] ?? 0.0;
    CalculationUtils.validateArea(area);
    return area;
  }

  /// Tính diện tích nhân công xây dựng
  ///
  /// Dựa trên diện tích xây dựng
  static double calculateLaborQuantity(Map<String, dynamic> parameters) {
    final double area = parameters['area'] ?? 0.0;
    CalculationUtils.validateArea(area);
    return area;
  }

  /// Tính diện tích nhân công điện nước
  ///
  /// Dựa trên diện tích thi công
  static double calculatePlumbingLaborQuantity(Map<String, dynamic> parameters) {
    final double area = parameters['area'] ?? 0.0;
    CalculationUtils.validateArea(area);
    return area;
  }

  /// Tính diện tích vật tư điện nước
  ///
  /// Dựa trên tổng diện tích sàn
  static double calculatePlumbingMaterialQuantity(Map<String, dynamic> parameters) {
    final double area = parameters['area'] ?? 0.0;
    CalculationUtils.validateArea(area);
    return area;
  }

  /// Tính khối lượng nước theo công thức cải tiến
  /// Nước = Xi măng × 0.4 m³/bao
  static double calculateWaterQuantity(
    Map<String, dynamic> parameters, {
    double brickLength = 0.22,
    double brickWidth = 0.10,
    double brickHeight = 0.05,
  }) {
    // Import CementCalculator để tính xi măng
    // Tính tổng xi măng cần thiết (tấn)
    final double totalCementTons = _calculateCementForWater(
      parameters,
      brickLength: brickLength,
      brickWidth: brickWidth,
      brickHeight: brickHeight,
    );

    // Chuyển đổi từ tấn sang kg
    final double totalCementKg = CalculationUtils.tonToKg(totalCementTons);

    // Giả định 1 bao xi măng = 50kg
    final double totalCementBags = CalculationUtils.kgToBags(totalCementKg);

    // Tính lượng nước: Nước = Xi măng × 0.4 m³/bao
    final double waterVolume = totalCementBags * ConstructionConstants.waterPerCement;

    return waterVolume;
  }

  /// Tính xi măng để tính nước (simplified version)
  static double _calculateCementForWater(
    Map<String, dynamic> parameters, {
    double brickLength = 0.22,
    double brickWidth = 0.10,
    double brickHeight = 0.05,
  }) {
    // Simplified cement calculation for water calculation
    if (parameters.containsKey('wallArea')) {
      final double wallArea = CalculationUtils.toDouble(parameters['wallArea']);
      // Ước tính xi măng: 0.25 tấn/m² tường
      return wallArea * 0.25;
    }
    return 0.0;
  }

  /// Tính vật liệu theo công thức tùy chỉnh
  /// [formula]: Công thức tính (ví dụ: "area * 0.5 + volume * 0.3")
  /// [parameters]: Các tham số đầu vào
  static double calculateByFormula({
    required String formula,
    required Map<String, dynamic> parameters,
  }) {
    // Đây là một implementation đơn giản
    // Trong thực tế có thể sử dụng expression parser phức tạp hơn
    
    double result = 0.0;
    
    // Xử lý một số công thức cơ bản
    if (formula.contains('area')) {
      final double area = CalculationUtils.toDouble(parameters['area']);
      if (formula.contains('* 0.5')) {
        result = area * 0.5;
      } else if (formula.contains('* 2')) {
        result = area * 2.0;
      } else {
        result = area;
      }
    } else if (formula.contains('volume')) {
      final double volume = CalculationUtils.toDouble(parameters['volume']);
      if (formula.contains('* 0.7')) {
        result = volume * 0.7;
      } else if (formula.contains('* 1.5')) {
        result = volume * 1.5;
      } else {
        result = volume;
      }
    }
    
    return result;
  }

  /// Validate tham số cho vật liệu tùy chỉnh
  static void validateCustomMaterialParameters(
    Map<String, dynamic> parameters,
    String measurementUnit,
  ) {
    switch (measurementUnit) {
      case 'squareMeter':
        CalculationUtils.validateParameters(parameters, ['area']);
        break;
      case 'cubicMeter':
        CalculationUtils.validateParameters(parameters, ['volume']);
        break;
      case 'meter':
        CalculationUtils.validateParameters(parameters, ['length']);
        break;
      case 'piece':
        if (parameters.containsKey('pieceLength')) {
          CalculationUtils.validateParameters(parameters, [
            'length', 'width', 'height',
            'pieceLength', 'pieceWidth', 'pieceHeight'
          ]);
        } else {
          CalculationUtils.validateParameters(parameters, ['quantity']);
        }
        break;
      case 'ton':
      case 'kilogram':
        CalculationUtils.validateParameters(parameters, ['weight']);
        break;
      case 'liter':
        CalculationUtils.validateParameters(parameters, ['volume']);
        break;
      default:
        CalculationUtils.validateParameters(parameters, ['quantity']);
    }
  }
}
