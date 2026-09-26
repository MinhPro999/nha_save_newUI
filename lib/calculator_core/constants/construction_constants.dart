/// Các hằng số kỹ thuật cho tính toán vật liệu xây dựng
/// Tuân thủ tiêu chuẩn Việt Nam (TCVN 9202:2012, TCKTXD01)
class ConstructionConstants {
  // ==================== HẰNG SỐ CHO VỮA XÂY VÀ TRÁT ====================

  /// Tỷ lệ nước trên xi măng (m³ nước / bao xi măng)
  static const double waterPerCement = 0.4;

  /// Tỷ lệ vữa trong khối xây (η = 30% thể tích khối xây là vữa)
  static const double mortarRatioInWall = 0.30;

  /// Độ dày lớp trát theo TCVN 9202:2012 (d_trát = 1.8cm = 0.018m)
  static const double plasterThickness = 0.018;

  /// Tỷ lệ cát trong vữa (75%)
  static const double sandRatioInMortar = 0.75;

  // ==================== HẰNG SỐ CHO XI MĂNG ====================

  /// Lượng xi măng cho vữa xây theo TCVN 9202:2012 (kg/m³ vữa xây mác 75)
  static const double cementForMortar = 250.0;

  /// Lượng xi măng cho vữa trát theo TCKTXD01 (kg/m²/10mm vữa trát mác 75)
  static const double cementForPlastering = 12.0;

  // ==================== HẰNG SỐ CHO CÁT TRÁT ====================

  /// Lượng cát trát theo công thức chuẩn TCVN 9202:2012 (m³ cát/m²)
  /// Công thức: Cát trát = A × d_trát × 0.75 = A × 0.018 × 0.75 = A × 0.0135
  static const double plasteringSandPerSquareMeter = 0.0135;

  // ==================== HẰNG SỐ CHO THÉP ====================

  /// Khối lượng trung bình thép Φ12 (kg/m)
  static const double averageSteelWeight = 0.888;

  // ==================== HẰNG SỐ CHO GẠCH ỐP LÁT ====================

  /// Diện tích gạch ốp lát tiêu chuẩn 60x60cm (m²)
  static const double standardTileArea = 0.36;

  // ==================== HẰNG SỐ HYBRID ALGORITHM ====================

  /// Tham số tối ưu từ thuật toán Hybrid (từ template)

  /// Tỷ lệ vữa trong tường (38% thể tích tường là vữa)
  static const double hybridMortarRatioInWall = 0.380;

  /// Tỷ lệ xi măng trong vữa (25% thể tích vữa là xi măng)
  static const double hybridCementRatioInMortar = 0.250;

  /// Khối lượng riêng xi măng (kg/m³)
  static const double hybridCementDensity = 1500.0;

  /// Hệ số nở rời cát (25%)
  static const double hybridSandBulkingFactor = 1.25;

  /// Khấu trừ cửa sổ/cửa ra vào (5%)
  static const double hybridOpeningsDeduction = 0.05;

  /// Hao hụt gạch (8%)
  static const double hybridBrickWaste = 0.08;

  /// Số viên gạch trên m² tường 10cm (viên/m²)
  static const double hybridBricksPerM2_10cm = 90.0;

  /// Số viên gạch trên m² tường 20cm (viên/m²)
  static const double hybridBricksPerM2_20cm = 190.0;

  /// Hệ số xi măng cho tường 10cm (tấn/m³)
  static const double hybridCementPerM3_10cm = 0.22;

  /// Hệ số xi măng cho tường 20cm (tấn/m³)
  static const double hybridCementPerM3_20cm = 0.23;

  /// Hệ số cát cho tường 10cm (m³/m³)
  static const double hybridSandPerM3_10cm = 0.54;

  /// Hệ số cát cho tường 20cm (m³/m³)
  static const double hybridSandPerM3_20cm = 0.52;

  /// Hệ số gạch cho tường 10cm (viên/m³)
  static const double hybridBrickPerM3_10cm = 550.0;

  /// Hệ số gạch cho tường 20cm (viên/m³)
  static const double hybridBrickPerM3_20cm = 520.0;

  /// Trọng số ensemble learning (25% M1 + 75% M2)
  static const double hybridEnsembleAlpha = 0.250;

  // ==================== HẰNG SỐ KHÁC ====================

  /// Khối lượng một bao xi măng (kg)
  static const double cementBagWeight = 50.0;

  /// Ngưỡng phân loại tường 10cm/20cm (m)
  static const double wallThicknessThreshold = 0.16;
}
