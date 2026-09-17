/// Model cho thông tin móng và kết cấu theo request17.md
library;

/// Enum cho loại móng mới theo request17.md
enum FoundationTypeNew {
  bang, // Móng băng
  be, // Móng bè
  coc, // Móng cốc
  coc_pile, // Móng cọc
}

/// Enum cho thuộc tính móng băng
enum FoundationBangAttribute {
  can_2_ben, // Cân 2 bên
  lech_1_ben, // Lệch 1 bên
  lech_2_ben, // Lệch 2 bên
}

/// Enum cho đường kính sắt chủ
enum SteelDiameter {
  d14(14),
  d16(16),
  d18(18),
  d20(20),
  d22(22);

  const SteelDiameter(this.value);
  final int value;
}

/// Model thông tin cột chịu lực
class ColumnInfo {
  /// Chiều rộng cột (m)
  double width;

  /// Chiều dày cột (m)
  double thickness;

  /// Số lượng cột
  int quantity;

  /// Số lượng sắt chủ trong cột
  int mainBarsCount;

  /// Đường kính sắt chủ (mm)
  SteelDiameter mainBarDiameter;

  ColumnInfo({
    required this.width,
    required this.thickness,
    required this.quantity,
    required this.mainBarsCount,
    required this.mainBarDiameter,
  });

  /// Tạo bản sao
  ColumnInfo copyWith({
    double? width,
    double? thickness,
    int? quantity,
    int? mainBarsCount,
    SteelDiameter? mainBarDiameter,
  }) {
    return ColumnInfo(
      width: width ?? this.width,
      thickness: thickness ?? this.thickness,
      quantity: quantity ?? this.quantity,
      mainBarsCount: mainBarsCount ?? this.mainBarsCount,
      mainBarDiameter: mainBarDiameter ?? this.mainBarDiameter,
    );
  }

  /// Chuyển từ Map
  factory ColumnInfo.fromMap(Map<String, dynamic> map) {
    return ColumnInfo(
      width: map['width']?.toDouble() ?? 0.0,
      thickness: map['thickness']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 0,
      mainBarsCount: map['mainBarsCount']?.toInt() ?? 0,
      mainBarDiameter: SteelDiameter.values[map['mainBarDiameter'] ?? 0],
    );
  }

  /// Chuyển sang Map
  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'thickness': thickness,
      'quantity': quantity,
      'mainBarsCount': mainBarsCount,
      'mainBarDiameter': mainBarDiameter.index,
    };
  }
}

/// Model thông tin móng băng
class FoundationBangInfo {
  /// Thuộc tính móng băng
  FoundationBangAttribute attribute;

  /// Đường kính sắt chủ
  SteelDiameter mainBarDiameter;

  FoundationBangInfo({required this.attribute, required this.mainBarDiameter});

  /// Tạo bản sao
  FoundationBangInfo copyWith({
    FoundationBangAttribute? attribute,
    SteelDiameter? mainBarDiameter,
  }) {
    return FoundationBangInfo(
      attribute: attribute ?? this.attribute,
      mainBarDiameter: mainBarDiameter ?? this.mainBarDiameter,
    );
  }

  /// Chuyển từ Map
  factory FoundationBangInfo.fromMap(Map<String, dynamic> map) {
    return FoundationBangInfo(
      attribute: FoundationBangAttribute.values[map['attribute'] ?? 0],
      mainBarDiameter: SteelDiameter.values[map['mainBarDiameter'] ?? 0],
    );
  }

  /// Chuyển sang Map
  Map<String, dynamic> toMap() {
    return {
      'attribute': attribute.index,
      'mainBarDiameter': mainBarDiameter.index,
    };
  }
}

/// Model thông tin móng bè
class FoundationBeInfo {
  /// Đường kính sắt chủ
  SteelDiameter mainBarDiameter;

  FoundationBeInfo({required this.mainBarDiameter});

  /// Tạo bản sao
  FoundationBeInfo copyWith({SteelDiameter? mainBarDiameter}) {
    return FoundationBeInfo(
      mainBarDiameter: mainBarDiameter ?? this.mainBarDiameter,
    );
  }

  /// Chuyển từ Map
  factory FoundationBeInfo.fromMap(Map<String, dynamic> map) {
    return FoundationBeInfo(
      mainBarDiameter: SteelDiameter.values[map['mainBarDiameter'] ?? 0],
    );
  }

  /// Chuyển sang Map
  Map<String, dynamic> toMap() {
    return {'mainBarDiameter': mainBarDiameter.index};
  }
}

/// Model thông tin móng cốc
class FoundationCocInfo {
  /// Chiều dài cốc (m)
  double length;

  /// Chiều rộng cốc (m)
  double width;

  /// Chiều cao cốc (m)
  double height;

  /// Đường kính sắt chủ
  SteelDiameter mainBarDiameter;

  FoundationCocInfo({
    required this.length,
    required this.width,
    required this.height,
    required this.mainBarDiameter,
  });

  /// Tạo bản sao
  FoundationCocInfo copyWith({
    double? length,
    double? width,
    double? height,
    SteelDiameter? mainBarDiameter,
  }) {
    return FoundationCocInfo(
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      mainBarDiameter: mainBarDiameter ?? this.mainBarDiameter,
    );
  }

  /// Chuyển từ Map
  factory FoundationCocInfo.fromMap(Map<String, dynamic> map) {
    return FoundationCocInfo(
      length: map['length']?.toDouble() ?? 0.0,
      width: map['width']?.toDouble() ?? 0.0,
      height: map['height']?.toDouble() ?? 0.0,
      mainBarDiameter: SteelDiameter.values[map['mainBarDiameter'] ?? 0],
    );
  }

  /// Chuyển sang Map
  Map<String, dynamic> toMap() {
    return {
      'length': length,
      'width': width,
      'height': height,
      'mainBarDiameter': mainBarDiameter.index,
    };
  }
}

/// Model thông tin đài móng cọc
class FoundationPileCapInfo {
  /// Chiều rộng đài móng (m)
  double width;

  /// Chiều dài đài móng (m)
  double length;

  /// Chiều cao đài móng (m)
  double height;

  FoundationPileCapInfo({
    required this.width,
    required this.length,
    required this.height,
  });

  /// Tạo bản sao
  FoundationPileCapInfo copyWith({
    double? width,
    double? length,
    double? height,
  }) {
    return FoundationPileCapInfo(
      width: width ?? this.width,
      length: length ?? this.length,
      height: height ?? this.height,
    );
  }

  /// Chuyển từ Map
  factory FoundationPileCapInfo.fromMap(Map<String, dynamic> map) {
    return FoundationPileCapInfo(
      width: map['width']?.toDouble() ?? 0.0,
      length: map['length']?.toDouble() ?? 0.0,
      height: map['height']?.toDouble() ?? 0.0,
    );
  }

  /// Chuyển sang Map
  Map<String, dynamic> toMap() {
    return {'width': width, 'length': length, 'height': height};
  }
}

/// Model thông tin móng cọc
class FoundationCocPileInfo {
  /// Danh sách đài móng
  List<FoundationPileCapInfo> pileCaps;

  /// Đường kính sắt chủ
  SteelDiameter mainBarDiameter;

  FoundationCocPileInfo({
    required this.pileCaps,
    required this.mainBarDiameter,
  });

  /// Tạo bản sao
  FoundationCocPileInfo copyWith({
    List<FoundationPileCapInfo>? pileCaps,
    SteelDiameter? mainBarDiameter,
  }) {
    return FoundationCocPileInfo(
      pileCaps: pileCaps ?? List.from(this.pileCaps),
      mainBarDiameter: mainBarDiameter ?? this.mainBarDiameter,
    );
  }

  /// Chuyển từ Map
  factory FoundationCocPileInfo.fromMap(Map<String, dynamic> map) {
    List<FoundationPileCapInfo> pileCaps = [];
    if (map['pileCaps'] != null) {
      final pileCapsList = List<Map<String, dynamic>>.from(map['pileCaps']);
      pileCaps =
          pileCapsList
              .map((capMap) => FoundationPileCapInfo.fromMap(capMap))
              .toList();
    }

    return FoundationCocPileInfo(
      pileCaps: pileCaps,
      mainBarDiameter: SteelDiameter.values[map['mainBarDiameter'] ?? 0],
    );
  }

  /// Chuyển sang Map
  Map<String, dynamic> toMap() {
    return {
      'pileCaps': pileCaps.map((cap) => cap.toMap()).toList(),
      'mainBarDiameter': mainBarDiameter.index,
    };
  }
}

/// Model tổng hợp thông tin móng và kết cấu cho Step3
class FoundationStructureData {
  /// Loại móng được chọn
  FoundationTypeNew? foundationType;

  /// Danh sách thông tin cột
  List<ColumnInfo> columns;

  /// Thông tin móng băng (nếu chọn móng băng)
  FoundationBangInfo? bangInfo;

  /// Thông tin móng bè (nếu chọn móng bè)
  FoundationBeInfo? beInfo;

  /// Thông tin móng cốc (nếu chọn móng cốc)
  FoundationCocInfo? cocInfo;

  /// Thông tin móng cọc (nếu chọn móng cọc)
  FoundationCocPileInfo? cocPileInfo;

  FoundationStructureData({
    this.foundationType,
    List<ColumnInfo>? columns,
    this.bangInfo,
    this.beInfo,
    this.cocInfo,
    this.cocPileInfo,
  }) : columns = columns ?? [];

  /// Tạo bản sao
  FoundationStructureData copyWith({
    FoundationTypeNew? foundationType,
    List<ColumnInfo>? columns,
    FoundationBangInfo? bangInfo,
    FoundationBeInfo? beInfo,
    FoundationCocInfo? cocInfo,
    FoundationCocPileInfo? cocPileInfo,
  }) {
    return FoundationStructureData(
      foundationType: foundationType ?? this.foundationType,
      columns: columns ?? List.from(this.columns),
      bangInfo: bangInfo ?? this.bangInfo,
      beInfo: beInfo ?? this.beInfo,
      cocInfo: cocInfo ?? this.cocInfo,
      cocPileInfo: cocPileInfo ?? this.cocPileInfo,
    );
  }

  /// Chuyển từ Map
  factory FoundationStructureData.fromMap(Map<String, dynamic> map) {
    List<ColumnInfo> columns = [];
    if (map['columns'] != null) {
      final columnsList = List<Map<String, dynamic>>.from(map['columns']);
      columns =
          columnsList.map((colMap) => ColumnInfo.fromMap(colMap)).toList();
    }

    return FoundationStructureData(
      foundationType:
          map['foundationType'] != null
              ? FoundationTypeNew.values[map['foundationType']]
              : null,
      columns: columns,
      bangInfo:
          map['bangInfo'] != null
              ? FoundationBangInfo.fromMap(
                Map<String, dynamic>.from(map['bangInfo']),
              )
              : null,
      beInfo:
          map['beInfo'] != null
              ? FoundationBeInfo.fromMap(
                Map<String, dynamic>.from(map['beInfo']),
              )
              : null,
      cocInfo:
          map['cocInfo'] != null
              ? FoundationCocInfo.fromMap(
                Map<String, dynamic>.from(map['cocInfo']),
              )
              : null,
      cocPileInfo:
          map['cocPileInfo'] != null
              ? FoundationCocPileInfo.fromMap(
                Map<String, dynamic>.from(map['cocPileInfo']),
              )
              : null,
    );
  }

  /// Chuyển sang Map
  Map<String, dynamic> toMap() {
    return {
      'foundationType': foundationType?.index,
      'columns': columns.map((col) => col.toMap()).toList(),
      'bangInfo': bangInfo?.toMap(),
      'beInfo': beInfo?.toMap(),
      'cocInfo': cocInfo?.toMap(),
      'cocPileInfo': cocPileInfo?.toMap(),
    };
  }

  /// Kiểm tra dữ liệu có hợp lệ không
  bool get isValid {
    if (foundationType == null || columns.isEmpty) return false;

    switch (foundationType!) {
      case FoundationTypeNew.bang:
        return bangInfo != null;
      case FoundationTypeNew.be:
        return beInfo != null;
      case FoundationTypeNew.coc:
        return cocInfo != null;
      case FoundationTypeNew.coc_pile:
        return cocPileInfo != null && cocPileInfo!.pileCaps.isNotEmpty;
    }
  }
}
