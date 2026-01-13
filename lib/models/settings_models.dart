class ShippingZone {
  final String id;
  final String name;
  final List<String> countries;
  final List<ShippingRate> rates;
  final bool isActive;

  ShippingZone({
    required this.id,
    required this.name,
    required this.countries,
    required this.rates,
    this.isActive = true,
  });

  factory ShippingZone.fromJson(Map<String, dynamic> json) {
    return ShippingZone(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      countries: List<String>.from(json['countries'] ?? []),
      rates: (json['rates'] as List? ?? [])
          .map((r) => ShippingRate.fromJson(r as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'countries': countries,
      'rates': rates.map((r) => r.toJson()).toList(),
      'isActive': isActive,
    };
  }
}

class ShippingRate {
  final String name;
  final double price;
  final double minWeight; // in kg
  final double? maxWeight;
  final int estimatedDaysMin;
  final int estimatedDaysMax;

  ShippingRate({
    required this.name,
    required this.price,
    this.minWeight = 0,
    this.maxWeight,
    this.estimatedDaysMin = 3,
    this.estimatedDaysMax = 7,
  });

  factory ShippingRate.fromJson(Map<String, dynamic> json) {
    return ShippingRate(
      name: json['name'] as String? ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      minWeight: (json['minWeight'] ?? 0.0).toDouble(),
      maxWeight: json['maxWeight'] != null
          ? (json['maxWeight'] as num).toDouble()
          : null,
      estimatedDaysMin: json['estimatedDaysMin'] as int? ?? 3,
      estimatedDaysMax: json['estimatedDaysMax'] as int? ?? 7,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'minWeight': minWeight,
      'maxWeight': maxWeight,
      'estimatedDaysMin': estimatedDaysMin,
      'estimatedDaysMax': estimatedDaysMax,
    };
  }
}

class TaxRule {
  final String id;
  final String name;
  final double rate; // e.g., 0.15 for 15%
  final String country;
  final String? state;
  final bool isActive;

  TaxRule({
    required this.id,
    required this.name,
    required this.rate,
    required this.country,
    this.state,
    this.isActive = true,
  });

  factory TaxRule.fromJson(Map<String, dynamic> json) {
    return TaxRule(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rate: (json['rate'] ?? 0.0).toDouble(),
      country: json['country'] as String? ?? '',
      state: json['state'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rate': rate,
      'country': country,
      'state': state,
      'isActive': isActive,
    };
  }
}

class ReturnPolicyTemplate {
  final String id;
  final String title;
  final String content;
  final int returnWindowDays;
  final bool restockingFee;
  final double restockingFeeAmount;

  ReturnPolicyTemplate({
    required this.id,
    required this.title,
    required this.content,
    this.returnWindowDays = 30,
    this.restockingFee = false,
    this.restockingFeeAmount = 0.0,
  });

  factory ReturnPolicyTemplate.fromJson(Map<String, dynamic> json) {
    return ReturnPolicyTemplate(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      returnWindowDays: json['returnWindowDays'] as int? ?? 30,
      restockingFee: json['restockingFee'] as bool? ?? false,
      restockingFeeAmount: (json['restockingFeeAmount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'returnWindowDays': returnWindowDays,
      'restockingFee': restockingFee,
      'restockingFeeAmount': restockingFeeAmount,
    };
  }
}

class AppChannel {
  final String id;
  final String name; // e.g., 'Web Store', 'Mobile App'
  final bool isEnabled;
  final Map<String, dynamic> config;

  AppChannel({
    required this.id,
    required this.name,
    this.isEnabled = true,
    this.config = const {},
  });

  factory AppChannel.fromJson(Map<String, dynamic> json) {
    return AppChannel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isEnabled': isEnabled,
      'config': config,
    };
  }
}
