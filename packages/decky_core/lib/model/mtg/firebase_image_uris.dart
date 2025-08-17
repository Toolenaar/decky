class FirebaseImageUris {
  final String? small;
  final String? normal;
  final String? large;
  final String? png;
  final String? artCrop;
  final String? borderCrop;

  FirebaseImageUris({
    this.small,
    this.normal,
    this.large,
    this.png,
    this.artCrop,
    this.borderCrop,
  });

  factory FirebaseImageUris.fromJson(Map<String, dynamic> json) {
    return FirebaseImageUris(
      small: json['small']?.toString(),
      normal: json['normal']?.toString(),
      large: json['large']?.toString(),
      png: json['png']?.toString(),
      artCrop: json['art_crop']?.toString(),
      borderCrop: json['border_crop']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (small != null) 'small': small,
      if (normal != null) 'normal': normal,
      if (large != null) 'large': large,
      if (png != null) 'png': png,
      if (artCrop != null) 'art_crop': artCrop,
      if (borderCrop != null) 'border_crop': borderCrop,
    };
  }

  bool get hasAnyImage => small != null || normal != null || large != null || png != null || artCrop != null || borderCrop != null;
}