import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:meta/meta.dart';

/// A obfuscated copy of a bundled image, ready to share.
class ObfuscatedImage {
  const ObfuscatedImage(
    this.bytes, {
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;

  /// The requested name, with its extension corrected to the real format.
  final String fileName;

  /// Null when the format is unknown (the receiver guesses from the name).
  final String? mimeType;
}

enum _Format {
  gif(['gif'], 'image/gif'),
  png(['png'], 'image/png'),
  jpeg(['jpg', 'jpeg'], 'image/jpeg');

  const _Format(this.extensions, this.mimeType);

  final List<String> extensions;
  final String mimeType;

  /// Identifies the format from the file signature. A handful of bundled
  /// memes are PNGs or JPEGs that merely carry a .gif name, so the extension
  /// cannot be trusted.
  static _Format? sniff(Uint8List b) {
    if (b.length < 8) return null;
    if (b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x38) {
      return gif; // "GIF8"
    }
    if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
      return png; // "\x89PNG"
    }
    if (b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return jpeg; // SOI
    return null;
  }
}

/// Rewrites a bundled meme so that every share is a genuinely new file.
///
/// Messaging apps quietly drop pictures they have blocked before by matching
/// a hash of the file or of its pixels, so sharing the same asset bytes twice
/// is exactly what gets a meme swallowed. Every call therefore re-renders the
/// picture with a fresh set of tiny, randomised changes that stay below what
/// the eye notices. What that buys, honestly:
///
/// * The file hash and the exact pixel data are new every time, for every
///   format.
/// * Perceptual fingerprints (dHash / pHash style thumbnails) move by a few
///   bits for a photo, and by several more when the picture has flat edges
///   that can take a small margin, which shifts the whole thumbnail grid.
///   They are not pushed out of a matcher's radius; nothing invisible can.
///
/// JPEG / PNG go through one bilinear resampling pass ([warp]): a tilt so
/// small that no corner moves by more than half a pixel, a sliver of well
/// under a percent trimmed from each side, a margin of a few percent grown on
/// one or two sides whose outer strip is flat (the edge pixels are simply
/// repeated: a little more white around a white meme), a shrink of up to
/// three percent with a slightly different factor per axis, and a sub-pixel
/// shift. Then one tone pass ([tone]): a hue rotation of a degree or two and
/// a saturation nudge, both of which leave greys untouched, and a smooth
/// random gamma field of a few percent that moves mid-tones only, so black
/// stays black and white stays white. JPEGs are re-encoded at a random
/// quality.
///
/// GIF frames stay untouched (re-encoding an animation is slow and lossy):
/// every colour table entry goes through one random, order-preserving lookup
/// per channel, so identical colours move identically in every frame, and a
/// random comment block is inserted. For animations only the file hash and
/// the exact pixel values change.
class ImageObfuscator {
  ImageObfuscator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Parameter envelope of the still pipeline, as fractions of the size, so
  /// that tests can derive their bounds from it.
  static const double maxTrim = 0.005;
  static const double maxPad = 0.03;
  static const double minScale = 0.97;
  static const double maxScaleJitter = 0.004;

  /// Obfuscates [bytes] according to their real format and returns them under
  /// [fileName], with the extension fixed to match. Unknown or undecodable
  /// input is passed through unchanged.
  ObfuscatedImage obfuscate(Uint8List bytes, {required String fileName}) {
    final format = _Format.sniff(bytes);
    if (format == null) {
      return ObfuscatedImage(bytes, fileName: fileName, mimeType: null);
    }
    final dot = fileName.lastIndexOf('.');
    final extension = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
    final name = format.extensions.contains(extension)
        ? fileName
        : '${dot < 0 ? fileName : fileName.substring(0, dot)}'
              '.${format.extensions.first}';
    final obfuscated = switch (format) {
      _Format.gif => obfuscateGif(bytes),
      _Format.png => obfuscateStill(bytes, png: true) ?? bytes,
      _Format.jpeg => obfuscateStill(bytes, png: false) ?? bytes,
    };
    return ObfuscatedImage(
      obfuscated,
      fileName: name,
      mimeType: format.mimeType,
    );
  }

  Uint8List? obfuscateStill(Uint8List bytes, {required bool png}) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } on Object {
      return null; // the format sniffers throw on truncated input
    }
    if (decoded == null) return null;
    final ifd = decoded.exif.imageIfd;
    if (ifd.hasOrientation && ifd.orientation != 1) {
      decoded = img.bakeOrientation(decoded); // EXIF is not carried over
    }

    // Work on a plain 8-bit RGB(A) frame: palette pixels cannot be
    // interpolated, and only the first frame of an animated PNG is kept.
    final image = decoded.convert(
      format: img.Format.uint8,
      numChannels: decoded.hasAlpha ? 4 : 3,
      noAnimation: true,
    );
    final w = image.width;
    final h = image.height;

    // 1. Geometry, in a single resampling pass. Every parameter is tiny: the
    //    point is that every output pixel is a fresh blend of source pixels
    //    at a slightly different place each time, not a visible change. The
    //    tilt is bounded so that the corners move by at most half a pixel
    //    (a real tilt would have to drop a wedge of the picture at two
    //    corners). Sides with a flat outer strip may grow a small margin
    //    instead of losing a sliver; that margin is what moves perceptual
    //    fingerprints, because their thumbnails are taken over the whole
    //    frame.
    final maxTilt = asin(0.5 / (sqrt(w * w + h * h) / 2));
    final pads = [0.0, 0.0, 0.0, 0.0]; // left, top, right, bottom
    final candidates = [
      for (final (i, flat) in flatSides(image).indexed)
        if (flat) i,
    ]..shuffle(_random);
    for (final side in candidates.take(1 + _random.nextInt(2))) {
      pads[side] = _range(maxPad / 2, maxPad);
    }
    double edge(int side) =>
        pads[side] > 0 ? -pads[side] : _range(0.001, maxTrim);
    final scale = _range(minScale, 1.0);
    final warped = warp(
      image,
      radians: _signed(0.3, 1.0) * maxTilt,
      left: edge(0),
      top: edge(1),
      right: edge(2),
      bottom: edge(3),
      scaleX: scale,
      scaleY: scale * (1 + _signed(0.0, maxScaleJitter)),
      offsetX: _range(-0.5, 0.5),
      offsetY: _range(-0.5, 0.5),
    );

    // 2. Tone: hue / saturation nudges plus a smooth random gamma field.
    tone(
      warped,
      hueDegrees: _signed(0.5, 2.0),
      saturation: 1 + _signed(0.01, 0.04),
      field: GammaField(
        tiltX: _signed(0.01, 0.025),
        tiltY: _signed(0.01, 0.025),
        waves: [
          for (var i = 0; i < 2; i++)
            Wave(
              amplitude: _range(0.008, 0.02),
              cyclesX: _signed(0.3, 1.2),
              cyclesY: _signed(0.3, 1.2),
              phase: _range(0, 2 * pi),
            ),
        ],
      ),
    );

    // 3. Encode. JPEG quality and chroma subsampling vary as well, so the
    //    quantised DCT coefficients differ even for identical pixels.
    if (png) return img.encodePng(warped);
    return img.encodeJpg(
      warped,
      quality: 80 + _random.nextInt(9),
      chroma: _random.nextInt(10) < 7
          ? img.JpegChroma.yuv420
          : img.JpegChroma.yuv444,
    );
  }

  /// Which sides (left, top, right, bottom) have an outer strip flat enough
  /// to be extended by repeating its edge: luminance (transparent pixels
  /// count as white) with a standard deviation under 3 levels and no pixel
  /// more than 24 levels away from the mean. Text, frames and watermarks
  /// inside the strip disqualify the side.
  @visibleForTesting
  static List<bool> flatSides(img.Image image) {
    final w = image.width;
    final h = image.height;
    final channels = image.numChannels;
    final data = image.toUint8List();
    final stripX = max(2, (w * 0.015).round());
    final stripY = max(2, (h * 0.015).round());
    if (w < 4 * stripX || h < 4 * stripY) return [false, false, false, false];

    bool flat(int x0, int y0, int x1, int y1) {
      var sum = 0.0;
      var sumOfSquares = 0.0;
      var lowest = 255.0;
      var highest = 0.0;
      for (var y = y0; y < y1; y++) {
        var i = (y * w + x0) * channels;
        for (var x = x0; x < x1; x++, i += channels) {
          var luma =
              0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];
          if (channels == 4) {
            final alpha = data[i + 3] / 255;
            luma = luma * alpha + 255 * (1 - alpha);
          }
          sum += luma;
          sumOfSquares += luma * luma;
          lowest = min(lowest, luma);
          highest = max(highest, luma);
        }
      }
      final n = (x1 - x0) * (y1 - y0);
      final mean = sum / n;
      final variance = max(0.0, sumOfSquares / n - mean * mean);
      return sqrt(variance) < 3 && highest - mean < 24 && mean - lowest < 24;
    }

    return [
      flat(0, 0, stripX, h),
      flat(0, 0, w, stripY),
      flat(w - stripX, 0, w, h),
      flat(0, h - stripY, w, h),
    ];
  }

  /// Resamples [src] (8-bit, interleaved channels) into a new image: the
  /// window that starts [left]/[top] and ends [right]/[bottom] fractions in
  /// from the edges (negative values grow the window outwards) is scaled by
  /// [scaleX]/[scaleY], shifted by [offsetX]/[offsetY] source pixels and
  /// rotated by [radians] about the picture's centre, with bilinear
  /// interpolation. Samples that fall outside the source clamp to its nearest
  /// edge pixel, so a grown window repeats the edge. Four-channel images are
  /// interpolated with premultiplied alpha, so whatever colour hides under
  /// transparent pixels never bleeds into the silhouette. The ICC profile is
  /// carried over.
  @visibleForTesting
  static img.Image warp(
    img.Image src, {
    required double radians,
    required double left,
    required double top,
    required double right,
    required double bottom,
    required double scaleX,
    required double scaleY,
    required double offsetX,
    required double offsetY,
  }) {
    final w = src.width;
    final h = src.height;
    final channels = src.numChannels;
    final outWidth = max(1, (w * (1 - left - right) * scaleX).round());
    final outHeight = max(1, (h * (1 - top - bottom) * scaleY).round());
    final icc = src.iccProfile;
    final out = img.Image(
      width: outWidth,
      height: outHeight,
      numChannels: channels,
      format: img.Format.uint8,
      // The JPEG encoder writes the profile as a single APP2 segment.
      iccp: icc != null && icc.data.length < 65000 ? icc.clone() : null,
    );
    var input = src.toUint8List();
    final output = out.toUint8List();
    final premultiplied = channels == 4;
    if (premultiplied) {
      input = Uint8List.fromList(input);
      for (var i = 0; i < input.length; i += 4) {
        final alpha = input[i + 3];
        if (alpha == 255) continue;
        input[i] = (input[i] * alpha + 127) ~/ 255;
        input[i + 1] = (input[i + 1] * alpha + 127) ~/ 255;
        input[i + 2] = (input[i + 2] * alpha + 127) ~/ 255;
      }
    }

    // Output pixel (x, y) -> un-rotated source point, then rotate that point
    // about the centre. Both steps are affine, so fold them into one:
    // u = ax * x + bx * y + cx, v = ay * x + by * y + cy.
    final cosA = cos(radians);
    final sinA = sin(radians);
    final centreX = (w - 1) / 2;
    final centreY = (h - 1) / 2;
    final startX = w * left + offsetX - centreX;
    final startY = h * top + offsetY - centreY;
    final ax = cosA / scaleX;
    final bx = -sinA / scaleY;
    final cx = startX * cosA - startY * sinA + centreX;
    final ay = sinA / scaleX;
    final by = cosA / scaleY;
    final cy = startX * sinA + startY * cosA + centreY;

    final maxX = w - 1;
    final maxY = h - 1;
    final sample = Float64List(4);
    var o = 0;
    for (var y = 0; y < outHeight; y++) {
      var u = bx * y + cx;
      var v = by * y + cy;
      for (var x = 0; x < outWidth; x++, u += ax, v += ay) {
        final su = u < 0 ? 0.0 : (u > maxX ? maxX.toDouble() : u);
        final sv = v < 0 ? 0.0 : (v > maxY ? maxY.toDouble() : v);
        final x0 = su.floor();
        final y0 = sv.floor();
        final x1 = x0 < maxX ? x0 + 1 : x0;
        final y1 = y0 < maxY ? y0 + 1 : y0;
        final fx = su - x0;
        final fy = sv - y0;
        final w00 = (1 - fx) * (1 - fy);
        final w10 = fx * (1 - fy);
        final w01 = (1 - fx) * fy;
        final w11 = fx * fy;
        final i00 = (y0 * w + x0) * channels;
        final i10 = (y0 * w + x1) * channels;
        final i01 = (y1 * w + x0) * channels;
        final i11 = (y1 * w + x1) * channels;
        for (var c = 0; c < channels; c++) {
          sample[c] =
              input[i00 + c] * w00 +
              input[i10 + c] * w10 +
              input[i01 + c] * w01 +
              input[i11 + c] * w11;
        }
        if (premultiplied) {
          final alpha = sample[3];
          if (alpha <= 0) {
            sample[0] = sample[1] = sample[2] = 0;
          } else if (alpha < 255) {
            for (var c = 0; c < 3; c++) {
              sample[c] = min(255, sample[c] * 255 / alpha);
            }
          }
        }
        for (var c = 0; c < channels; c++) {
          output[o++] = (sample[c] + 0.5).toInt();
        }
      }
    }
    return out;
  }

  /// Colour and tone in one pass over the raw bytes. Every pixel's RGB goes
  /// through the hue-rotation / saturation matrix ([colorMatrix]) and then
  /// through a gamma curve whose exponent is read from [field] at that
  /// position. Alpha is left alone; the results are rounded, not truncated.
  @visibleForTesting
  static void tone(
    img.Image image, {
    required double hueDegrees,
    required double saturation,
    required GammaField field,
  }) {
    final w = image.width;
    final h = image.height;
    final channels = image.numChannels;
    final data = image.toUint8List();
    final m = colorMatrix(hueDegrees, saturation);

    // The exponent is sampled on a grid of 4x4-pixel blocks and quantised to
    // a set of lookup tables; both steps are far finer than one 8-bit level.
    const block = 4;
    const levels = 48;
    final gridWidth = (w + block - 1) ~/ block;
    final gridHeight = (h + block - 1) ~/ block;
    final exponents = Float64List(gridWidth * gridHeight);
    var lowest = double.infinity;
    var highest = -double.infinity;
    for (var gy = 0; gy < gridHeight; gy++) {
      for (var gx = 0; gx < gridWidth; gx++) {
        final e = field.exponentAt(
          min(1, (gx * block + block / 2) / w),
          min(1, (gy * block + block / 2) / h),
        );
        exponents[gy * gridWidth + gx] = e;
        lowest = min(lowest, e);
        highest = max(highest, e);
      }
    }
    final span = highest - lowest;
    final tables = [
      for (var i = 0; i < levels; i++)
        _gammaTable(lowest + span * i / (levels - 1)),
    ];
    final tableIndex = Uint8List(exponents.length);
    for (var i = 0; i < exponents.length; i++) {
      tableIndex[i] = span == 0
          ? 0
          : ((exponents[i] - lowest) / span * (levels - 1)).round();
    }

    for (var y = 0; y < h; y++) {
      final row = (y ~/ block) * gridWidth;
      var o = y * w * channels;
      for (var x = 0; x < w; x++, o += channels) {
        final table = tables[tableIndex[row + x ~/ block]];
        final r = data[o];
        final g = data[o + 1];
        final b = data[o + 2];
        data[o] = table[_byte(m[0] * r + m[1] * g + m[2] * b)];
        data[o + 1] = table[_byte(m[3] * r + m[4] * g + m[5] * b)];
        data[o + 2] = table[_byte(m[6] * r + m[7] * g + m[8] * b)];
      }
    }
  }

  static int _byte(double v) =>
      v <= 0 ? 0 : (v >= 255 ? 255 : (v + 0.5).toInt());

  static Uint8List _gammaTable(double gamma) => Uint8List.fromList([
    for (var v = 0; v < 256; v++) (255 * pow(v / 255, gamma)).round(),
  ]);

  /// The 3x3 matrix that rotates hue by [degrees] and scales saturation by
  /// [saturation] (the SVG feColorMatrix formulas, Rec. 709 luma weights).
  /// Every row sums to one, so greys, black and white are fixed points.
  @visibleForTesting
  static Float64List colorMatrix(double degrees, double saturation) {
    final c = cos(degrees * pi / 180);
    final s = sin(degrees * pi / 180);
    final hue = [
      0.213 + c * 0.787 - s * 0.213,
      0.715 - c * 0.715 - s * 0.715,
      0.072 - c * 0.072 + s * 0.928,
      0.213 - c * 0.213 + s * 0.143,
      0.715 + c * 0.285 + s * 0.140,
      0.072 - c * 0.072 - s * 0.283,
      0.213 - c * 0.213 - s * 0.787,
      0.715 - c * 0.715 + s * 0.715,
      0.072 + c * 0.928 + s * 0.072,
    ];
    final sat = [
      0.213 + 0.787 * saturation,
      0.715 - 0.715 * saturation,
      0.072 - 0.072 * saturation,
      0.213 - 0.213 * saturation,
      0.715 + 0.285 * saturation,
      0.072 - 0.072 * saturation,
      0.213 - 0.213 * saturation,
      0.715 - 0.715 * saturation,
      0.072 + 0.928 * saturation,
    ];
    final product = Float64List(9);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        var sum = 0.0;
        for (var k = 0; k < 3; k++) {
          sum += hue[row * 3 + k] * sat[k * 3 + col];
        }
        product[row * 3 + col] = sum;
      }
    }
    return product;
  }

  Uint8List obfuscateGif(Uint8List bytes) {
    if (bytes.length < 13 ||
        bytes[0] != 0x47 ||
        bytes[1] != 0x49 ||
        bytes[2] != 0x46) {
      return bytes;
    }
    final out = Uint8List.fromList(bytes);
    final lookups = [for (var c = 0; c < 3; c++) _nudgeTable()];

    void nudgeColorTable(int start, int entries) {
      final end = min(start + entries * 3, out.length);
      for (var i = start; i < end; i++) {
        out[i] = lookups[(i - start) % 3][out[i]];
      }
    }

    // Logical screen descriptor: a global colour table follows it when bit 7
    // of the packed byte is set; bits 0-2 give its size as 2^(n+1) entries.
    var pos = 13;
    final screenPacked = out[10];
    if (screenPacked & 0x80 != 0) {
      final entries = 2 << (screenPacked & 0x07);
      nudgeColorTable(pos, entries);
      pos += entries * 3;
    }

    // Walk the data stream: extensions (0x21) carry sub-blocks, image
    // descriptors (0x2C) may carry a local colour table, 0x3B ends the file.
    while (pos < out.length) {
      final block = out[pos];
      if (block == 0x3B) break;
      if (block == 0x21) {
        pos = _skipSubBlocks(out, pos + 2);
      } else if (block == 0x2C) {
        if (pos + 10 > out.length) return out;
        final imagePacked = out[pos + 9];
        pos += 10;
        if (imagePacked & 0x80 != 0) {
          final entries = 2 << (imagePacked & 0x07);
          nudgeColorTable(pos, entries);
          pos += entries * 3;
        }
        pos = _skipSubBlocks(out, pos + 1); // skip the LZW minimum code size
      } else {
        return out; // unknown block: keep the rest of the file as it is
      }
    }
    if (pos >= out.length) return out;

    // Comment extension (0x21 0xFE, one sub-block of 1-32 random bytes,
    // terminator) inserted just before the trailer, so even the file length
    // differs between shares.
    final length = 1 + _random.nextInt(32);
    final comment = Uint8List.fromList([
      0x21,
      0xFE,
      length,
      for (var i = 0; i < length; i++) _random.nextInt(256),
      0x00,
    ]);
    final result = Uint8List(out.length + comment.length);
    result
      ..setRange(0, pos, out)
      ..setRange(pos, pos + comment.length, comment)
      ..setRange(pos + comment.length, result.length, out, pos);
    return result;
  }

  /// Advances over GIF data sub-blocks (length byte + data, ending with a
  /// zero length byte) and returns the position after the terminator.
  static int _skipSubBlocks(Uint8List data, int pos) {
    while (pos < data.length) {
      final length = data[pos];
      pos += 1 + length;
      if (length == 0) break;
    }
    return pos;
  }

  /// A lookup that moves byte values by up to two levels along a bounded
  /// random walk. Because consecutive offsets differ by at most one, the
  /// table never reorders values, so dithered gradients keep their order.
  Uint8List _nudgeTable() {
    final table = Uint8List(256);
    var offset = _random.nextBool() ? 1 : -1;
    for (var v = 0; v < 256; v++) {
      offset = (offset + _random.nextInt(3) - 1).clamp(-2, 2);
      table[v] = (v + offset).clamp(0, 255);
    }
    return table;
  }

  double _range(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  double _signed(double min, double max) =>
      _random.nextBool() ? _range(min, max) : -_range(min, max);
}

/// A smooth exponent field over the unit square: 1 plus a tilt along each
/// axis (+/-[tiltX], +/-[tiltY] at the edges) plus the sum of [waves].
class GammaField {
  const GammaField({
    required this.tiltX,
    required this.tiltY,
    required this.waves,
  });

  final double tiltX;
  final double tiltY;
  final List<Wave> waves;

  double exponentAt(double nx, double ny) {
    var e = 1 + tiltX * (2 * nx - 1) + tiltY * (2 * ny - 1);
    for (final wave in waves) {
      e +=
          wave.amplitude *
          sin(2 * pi * (wave.cyclesX * nx + wave.cyclesY * ny) + wave.phase);
    }
    return e;
  }
}

class Wave {
  const Wave({
    required this.amplitude,
    required this.cyclesX,
    required this.cyclesY,
    required this.phase,
  });

  final double amplitude;
  final double cyclesX;
  final double cyclesY;
  final double phase;
}
