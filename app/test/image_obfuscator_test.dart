// Exercises ImageObfuscator on synthetic pictures and real bundled assets.
// Set OBFUSCATOR_OUT to a directory to also get the originals and two
// obfuscated copies written out for a visual comparison; set OBFUSCATOR_SWEEP=1
// to push every bundled image through the obfuscator (a minute or two).

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:mogicians_manual/utils/image_obfuscator.dart';

Uint8List _asset(String name) => File('assets/images/$name').readAsBytesSync();

/// What a viewer shows: the first frame composited over white, no alpha.
/// (Whatever colour hides under fully transparent pixels must not count.)
img.Image _opaque(img.Image image) {
  final frame = image.convert(numChannels: 4, noAnimation: true);
  final canvas = img.fill(
    img.Image(width: frame.width, height: frame.height, numChannels: 3),
    color: img.ColorRgb8(255, 255, 255),
  );
  return img.compositeImage(canvas, frame);
}

/// Grayscale thumbnail of [size] x [size] pixels.
img.Image _thumbnail(img.Image image, int size) => img.grayscale(
  img.copyResize(
    _opaque(image),
    width: size,
    height: size,
    interpolation: img.Interpolation.average,
  ),
);

/// 64-bit difference hash (9x8 grayscale, each bit compares horizontal
/// neighbours): the kind of perceptual fingerprint blockers match on.
int _dHash(img.Image image) {
  final gray = img.grayscale(
    img.copyResize(
      _opaque(image),
      width: 9,
      height: 8,
      interpolation: img.Interpolation.average,
    ),
  );
  var hash = 0;
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final bit = gray.getPixel(x, y).r > gray.getPixel(x + 1, y).r ? 1 : 0;
      hash = (hash << 1) | bit;
    }
  }
  return hash;
}

int _hamming(int a, int b) {
  var x = a ^ b;
  var count = 0;
  while (x != 0) {
    count += x & 1;
    x >>>= 1;
  }
  return count;
}

/// 64-bit DCT hash (32x32 grayscale, low 8x8 DCT coefficients vs their
/// median), the other common perceptual fingerprint.
int _pHash(img.Image image) {
  final gray = _thumbnail(image, 32);
  final values = List<double>.generate(
    1024,
    (i) => gray.getPixel(i % 32, i ~/ 32).r.toDouble(),
  );
  final dct = List<double>.filled(64, 0);
  for (var v = 0; v < 8; v++) {
    for (var u = 0; u < 8; u++) {
      var sum = 0.0;
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          sum +=
              values[y * 32 + x] *
              cos((2 * x + 1) * u * pi / 64) *
              cos((2 * y + 1) * v * pi / 64);
        }
      }
      dct[v * 8 + u] = sum;
    }
  }
  final coefficients = dct.sublist(1); // drop the DC term
  final sorted = List<double>.of(coefficients)..sort();
  final median = sorted[sorted.length ~/ 2];
  var hash = 0;
  for (final c in coefficients) {
    hash = (hash << 1) | (c > median ? 1 : 0);
  }
  return hash;
}

/// Alignment-independent tone statistics of the composited picture:
/// histograms of each pixel's darkest and brightest channel, so the share of
/// dark pixels (every channel <= t) and of bright pixels (every channel >= t)
/// can be read at any threshold, plus the mean of each channel.
class _ToneStats {
  _ToneStats(img.Image image) {
    final flat = _opaque(image);
    for (final p in flat) {
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      _darkest[max(r, max(g, b))]++;
      _brightest[min(r, min(g, b))]++;
      mean[0] += r;
      mean[1] += g;
      mean[2] += b;
    }
    _count = flat.width * flat.height;
    for (var c = 0; c < 3; c++) {
      mean[c] /= _count;
    }
  }

  final _darkest = List<int>.filled(256, 0);
  final _brightest = List<int>.filled(256, 0);
  final mean = [0.0, 0.0, 0.0];
  late final int _count;

  /// Share of pixels whose every channel is <= [threshold].
  double dark(int threshold) =>
      _darkest.take(threshold + 1).fold(0, (a, b) => a + b) / _count;

  /// Share of pixels whose every channel is >= [threshold].
  double bright(int threshold) =>
      _brightest.skip(threshold).fold(0, (a, b) => a + b) / _count;
}

/// The obfuscated picture must have the tones of the source. Shares are
/// compared with 10 levels of hysteresis (a gamma nudge moves a value near
/// the threshold by a few levels) and 7 points of tolerance (a grown margin
/// adds up to 6 % of background); every channel mean must stay within 12
/// levels. This is what catches a pipeline that turns black to white or
/// washes a white background grey.
void _expectSameTone(
  img.Image source,
  img.Image obfuscated, {
  required String reason,
}) {
  final a = _ToneStats(source);
  final b = _ToneStats(obfuscated);
  expect(
    b.dark(50),
    greaterThanOrEqualTo(a.dark(40) - 0.07),
    reason: '$reason: dark',
  );
  expect(
    b.dark(30),
    lessThanOrEqualTo(a.dark(40) + 0.07),
    reason: '$reason: dark',
  );
  expect(
    b.bright(205),
    greaterThanOrEqualTo(a.bright(215) - 0.07),
    reason: '$reason: bright',
  );
  expect(
    b.bright(225),
    lessThanOrEqualTo(a.bright(215) + 0.07),
    reason: '$reason: bright',
  );
  for (var c = 0; c < 3; c++) {
    expect(b.mean[c], closeTo(a.mean[c], 12), reason: '$reason: mean $c');
  }
}

/// Size and aspect ratio must stay within the pipeline's own envelope.
void _expectSizeInEnvelope(
  img.Image source,
  img.Image obfuscated, {
  required String reason,
}) {
  const shrink = (1 - 2 * ImageObfuscator.maxTrim) * ImageObfuscator.minScale;
  const grow =
      (1 + 2 * ImageObfuscator.maxPad) * (1 + ImageObfuscator.maxScaleJitter);
  expect(
    obfuscated.width,
    inInclusiveRange(source.width * shrink - 1, source.width * grow + 1),
    reason: '$reason: width',
  );
  expect(
    obfuscated.height,
    inInclusiveRange(source.height * shrink - 1, source.height * grow + 1),
    reason: '$reason: height',
  );
  final ratio =
      (obfuscated.width / obfuscated.height) / (source.width / source.height);
  expect(
    ratio,
    inInclusiveRange(shrink / grow * 0.99, grow / shrink * 1.01),
    reason: '$reason: aspect ratio',
  );
}

/// Decodes both GIFs frame by frame: same frame count, screen, geometry,
/// timing, disposal and transparency; raw frame pixels within 2 levels per
/// channel; most pixels changed; and pixels that are identical between two
/// consecutive original frames stay identical in the obfuscated copy (no
/// flicker in static regions).
void _expectSameAnimation(
  Uint8List original,
  Uint8List obfuscated, {
  required String reason,
}) {
  final a = img.GifDecoder();
  final b = img.GifDecoder();
  final infoA = a.startDecode(original)!;
  final infoB = b.startDecode(obfuscated)!;
  expect(infoB.numFrames, infoA.numFrames, reason: '$reason: frame count');
  expect(infoB.width, infoA.width, reason: '$reason: screen width');
  expect(infoB.height, infoA.height, reason: '$reason: screen height');
  img.Image? previousA;
  img.Image? previousB;
  var changed = 0;
  var total = 0;
  String? violation;
  for (var i = 0; i < infoA.numFrames && violation == null; i++) {
    final descA = infoA.frames[i];
    final descB = infoB.frames[i];
    List<Object> fields(img.GifImageDesc d) => [
      d.x,
      d.y,
      d.width,
      d.height,
      d.duration,
      d.disposal,
      d.transparent,
      d.interlaced,
    ];
    expect(fields(descB), fields(descA), reason: '$reason: frame $i');
    final frameA = a.decodeFrame(i)!;
    final frameB = b.decodeFrame(i)!;
    final sameGeometry =
        previousA != null &&
        previousA.width == frameA.width &&
        previousA.height == frameA.height;
    for (final p in frameA) {
      final q = frameB.getPixel(p.x, p.y);
      final dr = (p.r - q.r).abs();
      final dg = (p.g - q.g).abs();
      final db = (p.b - q.b).abs();
      if (dr > 2 || dg > 2 || db > 2) {
        violation =
            'frame $i pixel ${p.x},${p.y}: '
            '${[p.r, p.g, p.b]} -> ${[q.r, q.g, q.b]}';
        break;
      }
      if (dr + dg + db > 0) changed++;
      total++;
      if (sameGeometry) {
        final pp = previousA.getPixel(p.x, p.y);
        if (pp.r == p.r && pp.g == p.g && pp.b == p.b) {
          final qq = previousB!.getPixel(p.x, p.y);
          if (qq.r != q.r || qq.g != q.g || qq.b != q.b) {
            violation =
                'frame $i pixel ${p.x},${p.y} flickers: '
                '${[qq.r, qq.g, qq.b]} then ${[q.r, q.g, q.b]}';
            break;
          }
        }
      }
    }
    previousA = frameA;
    previousB = frameB;
  }
  expect(violation, isNull, reason: reason);
  expect(changed, greaterThan(total ~/ 2), reason: '$reason: pixels changed');
}

void _dump(String name, Uint8List original, List<ObfuscatedImage> copies) {
  final dir = Platform.environment['OBFUSCATOR_OUT'];
  if (dir == null) return;
  Directory(dir).createSync(recursive: true);
  File('$dir/$name').writeAsBytesSync(original);
  for (var i = 0; i < copies.length; i++) {
    final dot = name.lastIndexOf('.');
    File('$dir/${name.substring(0, dot)}_obfuscated$i${name.substring(dot)}')
        .writeAsBytesSync(copies[i].bytes);
  }
}

/// An 8-bit picture of [width] x [height] with [channels] channels filled by
/// [paint], which returns the channel values for a pixel.
img.Image _picture(
  int width,
  int height,
  int channels,
  List<int> Function(int x, int y) paint,
) {
  final image = img.Image(width: width, height: height, numChannels: channels);
  final data = image.toUint8List();
  var o = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final values = paint(x, y);
      for (var c = 0; c < channels; c++) {
        data[o++] = values[c];
      }
    }
  }
  return image;
}

double _median(List<num> values) {
  final sorted = List<num>.of(values)..sort();
  return sorted[sorted.length ~/ 2].toDouble();
}

void main() {
  for (final name in [
    'dou_hd_mo_jing.jpg', // a photo: busy edges, no margin can be grown
    'dou_baozou_11_bo_dao_zhang_zhe.jpg', // black lines on white paper
    'dou_kuso_0_dan_shi_wo_jian_de_tai_duo.png', // transparent cut-out
  ]) {
    test('$name: every share is a new file that looks the same', () {
      final original = _asset(name);
      final source = img.decodeImage(original)!;
      const seeds = 12;
      final copies = <ObfuscatedImage>[];
      final stopwatch = Stopwatch()..start();
      for (var seed = 1; seed <= seeds; seed++) {
        copies.add(
          ImageObfuscator(random: Random(seed))
              .obfuscate(original, fileName: name),
        );
      }
      final elapsed = stopwatch.elapsedMilliseconds ~/ seeds;
      _dump(name, original, copies.take(2).toList());
      expect(
        ImageObfuscator(random: Random(1))
            .obfuscate(original, fileName: name)
            .bytes,
        copies.first.bytes,
        reason: 'seeded runs reproduce',
      );

      final distances = <int>[];
      final dHashes = <int>[];
      final pHashes = <int>[];
      final sourceDHash = _dHash(source);
      final sourcePHash = _pHash(source);
      for (var i = 0; i < copies.length; i++) {
        final reason = '$name seed ${i + 1}';
        expect(copies[i].bytes, isNot(equals(original)), reason: reason);
        if (i > 0) {
          expect(copies[i].bytes, isNot(equals(copies[i - 1].bytes)));
        }
        final obfuscated = img.decodeImage(copies[i].bytes)!;
        _expectSizeInEnvelope(source, obfuscated, reason: reason);
        _expectSameTone(source, obfuscated, reason: reason);
        final d = _hamming(sourceDHash, _dHash(obfuscated));
        final p = _hamming(sourcePHash, _pHash(obfuscated));
        dHashes.add(d);
        pHashes.add(p);
        distances.add(d + p);
      }
      // ignore: avoid_print
      print(
        '$name: ${source.width}x${source.height}, ${original.length} -> '
        '${copies.first.bytes.length} bytes, ${elapsed}ms/share, over $seeds '
        'seeds dHash moved by median ${_median(dHashes)} bits '
        '(max ${dHashes.reduce(max)}), pHash by median ${_median(pHashes)} '
        '(max ${pHashes.reduce(max)})',
      );
      expect(
        _median(distances),
        greaterThanOrEqualTo(2),
        reason: 'perceptual fingerprints should move a little',
      );
    });
  }

  test('flat white stays white and flat black stays black', () {
    for (final png in [false, true]) {
      for (final (name, value, check) in [
        ('white', 255, (int v) => v >= 250),
        ('black', 0, (int v) => v <= 5),
      ]) {
        final source = img.encodePng(
          _picture(200, 150, 3, (x, y) => [value, value, value]),
        );
        for (var seed = 1; seed <= 16; seed++) {
          final bytes = ImageObfuscator(random: Random(seed))
              .obfuscateStill(source, png: png)!;
          final out = img.decodeImage(bytes)!;
          var sum = 0;
          for (final p in out) {
            for (final v in [p.r, p.g, p.b]) {
              expect(
                check(v.toInt()),
                isTrue,
                reason: '$name ${png ? 'png' : 'jpg'} seed $seed: $v',
              );
              sum += v.toInt();
            }
          }
          final mean = sum / (out.width * out.height * 3);
          expect((mean - value).abs(), lessThan(2), reason: '$name mean');
        }
      }
    }
  });

  test('a transparent cut-out gets no dark halo', () {
    // Light grey square on a transparent background that hides black.
    final source = img.encodePng(
      _picture(
        80,
        60,
        4,
        (x, y) => x >= 20 && x < 60 && y >= 15 && y < 45
            ? [220, 220, 220, 255]
            : [0, 0, 0, 0],
      ),
    );
    for (var seed = 1; seed <= 8; seed++) {
      final bytes = ImageObfuscator(random: Random(seed))
          .obfuscateStill(source, png: true)!;
      final shown = _opaque(img.decodePng(bytes)!);
      for (final p in shown) {
        expect(
          p.r >= 200 && p.g >= 200 && p.b >= 200,
          isTrue,
          reason: 'seed $seed pixel ${p.x},${p.y}: ${[p.r, p.g, p.b]}',
        );
      }
    }
  });

  test('flat edges may grow a margin, busy edges never do', () {
    final framed = _picture(
      240,
      160,
      3,
      (x, y) => x >= 70 && x < 170 && y >= 50 && y < 110
          ? [0, 0, 0]
          : [255, 255, 255],
    );
    expect(ImageObfuscator.flatSides(framed), [true, true, true, true]);
    final framedBytes = img.encodePng(framed);
    var grew = 0;
    for (var seed = 1; seed <= 12; seed++) {
      final out = img.decodePng(
        ImageObfuscator(random: Random(seed))
            .obfuscateStill(framedBytes, png: true)!,
      )!;
      if (out.width > 240 || out.height > 160) grew++;
      // The black block must come through whole: its area may only shrink
      // with the overall scale, never be cropped.
      var dark = 0;
      for (final p in out) {
        if (p.r <= 40 && p.g <= 40 && p.b <= 40) dark++;
      }
      expect(
        dark / (100 * 60),
        inInclusiveRange(0.93, 1.02),
        reason: 'seed $seed: ${out.width}x${out.height}, $dark dark pixels',
      );
    }
    expect(grew, greaterThan(6), reason: 'flat sides should usually grow');

    final noise = Random(3);
    final busy = _picture(
      240,
      160,
      3,
      (x, y) => [noise.nextInt(256), noise.nextInt(256), noise.nextInt(256)],
    );
    expect(ImageObfuscator.flatSides(busy), [false, false, false, false]);
    final busyBytes = img.encodePng(busy);
    for (var seed = 1; seed <= 6; seed++) {
      final out = img.decodePng(
        ImageObfuscator(random: Random(seed))
            .obfuscateStill(busyBytes, png: true)!,
      )!;
      expect(out.width, lessThanOrEqualTo(240), reason: 'seed $seed');
      expect(out.height, lessThanOrEqualTo(160), reason: 'seed $seed');
    }
  });

  group('warp geometry', () {
    // 8x6 picture in which every pixel is unique: r = 10x, g = 10y, b = 7.
    final source = _picture(8, 6, 3, (x, y) => [10 * x, 10 * y, 7]);
    img.Image run({
      double radians = 0,
      double left = 0,
      double top = 0,
      double right = 0,
      double bottom = 0,
      double scaleX = 1,
      double scaleY = 1,
      double offsetX = 0,
      double offsetY = 0,
    }) => ImageObfuscator.warp(
      source,
      radians: radians,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      scaleX: scaleX,
      scaleY: scaleY,
      offsetX: offsetX,
      offsetY: offsetY,
    );

    test('identity parameters reproduce the picture exactly', () {
      final out = run();
      expect(out.width, 8);
      expect(out.height, 6);
      expect(out.toUint8List(), source.toUint8List());
    });

    test('trims cut from the requested sides', () {
      final out = run(left: 0.25, top: 1 / 6, right: 0.125, bottom: 0);
      expect(out.width, 5); // 8 * (1 - 0.25 - 0.125)
      expect(out.height, 5); // 6 * (1 - 1/6)
      for (final p in out) {
        expect(p.r, 10 * (p.x + 2), reason: 'column ${p.x}');
        expect(p.g, 10 * (p.y + 1), reason: 'row ${p.y}');
      }
    });

    test('a negative trim grows the window by repeating the edge', () {
      final out = run(left: -0.25, right: 0, top: 0, bottom: -1 / 6);
      expect(out.width, 10);
      expect(out.height, 7);
      for (final p in out) {
        expect(p.r, 10 * max(0, p.x - 2), reason: 'column ${p.x}');
        expect(p.g, 10 * min(5, p.y), reason: 'row ${p.y}');
      }
    });

    test('a half turn maps every pixel to its opposite (true centre)', () {
      final out = run(radians: pi);
      expect(out.width, 8);
      expect(out.height, 6);
      for (final p in out) {
        expect(p.r, 10 * (7 - p.x), reason: 'output ${p.x},${p.y}');
        expect(p.g, 10 * (5 - p.y), reason: 'output ${p.x},${p.y}');
      }
    });

    test('a quarter turn is counter-clockwise about the centre', () {
      final square = _picture(5, 5, 3, (x, y) => [10 * x, 10 * y, 0]);
      final out = ImageObfuscator.warp(
        square,
        radians: pi / 2,
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        scaleX: 1,
        scaleY: 1,
        offsetX: 0,
        offsetY: 0,
      );
      // A quarter turn maps output (x, y) onto source (4 - y, x).
      for (final p in out) {
        expect(p.r, (4 - p.y) * 10, reason: 'output ${p.x},${p.y}');
        expect(p.g, p.x * 10, reason: 'output ${p.x},${p.y}');
      }
    });

    test('samples outside the picture clamp to its edge, never to black', () {
      final flat = _picture(40, 30, 4, (x, y) => [100, 150, 200, 255]);
      final out = ImageObfuscator.warp(
        flat,
        radians: pi / 4,
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        scaleX: 1,
        scaleY: 1,
        offsetX: 3,
        offsetY: -3,
      );
      for (final p in out) {
        expect(
          [p.r, p.g, p.b, p.a],
          [100, 150, 200, 255],
          reason: 'output ${p.x},${p.y}',
        );
      }
    });

    test('scale and offset move the sampling grid', () {
      final out = run(scaleX: 0.5, scaleY: 0.5, offsetX: 0.5);
      expect(out.width, 4);
      expect(out.height, 3);
      // Output x samples source 2x + 0.5 (halfway between two columns) and
      // output y samples source 2y; the ramps make bilinear samples exact.
      expect(out.getPixel(1, 0).r, 25);
      expect(out.getPixel(2, 0).r, 45);
      expect(out.getPixel(0, 1).g, 20);
      expect(out.getPixel(0, 2).g, 40);
    });

    test('alpha is interpolated premultiplied', () {
      // A transparent black pixel next to an opaque grey one: the blend in
      // between must be grey at half alpha, not a darker grey.
      final pair = _picture(
        2,
        1,
        4,
        (x, y) => x == 0 ? [0, 0, 0, 0] : [200, 200, 200, 255],
      );
      final out = ImageObfuscator.warp(
        pair,
        radians: 0,
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        scaleX: 1,
        scaleY: 1,
        offsetX: 0.5,
        offsetY: 0,
      );
      final p = out.getPixel(0, 0);
      expect(p.a, 128);
      expect([p.r, p.g, p.b], [200, 200, 200]);
    });
  });

  group('tone', () {
    test('greys, black and white are fixed points of the colour matrix', () {
      final identity = ImageObfuscator.colorMatrix(0, 1);
      for (var i = 0; i < 9; i++) {
        expect(identity[i], closeTo(i % 4 == 0 ? 1 : 0, 1e-9));
      }
      for (final (hue, saturation) in [
        (2.0, 1.04),
        (-2.0, 0.96),
        (30.0, 2.0),
      ]) {
        final m = ImageObfuscator.colorMatrix(hue, saturation);
        for (var row = 0; row < 3; row++) {
          expect(
            m[row * 3] + m[row * 3 + 1] + m[row * 3 + 2],
            closeTo(1, 1e-9),
          );
        }
      }
    });

    test(
      'the gamma field moves mid-tones a little and the ends not at all',
      () {
        final ramp = _picture(256, 8, 4, (x, y) => [x, x, x, 255]);
        ImageObfuscator.tone(
          ramp,
          hueDegrees: 2,
          saturation: 1.04,
          field: const GammaField(
            tiltX: 0.025,
            tiltY: -0.025,
            waves: [
              Wave(amplitude: 0.02, cyclesX: 1.2, cyclesY: 0.3, phase: 1),
              Wave(amplitude: 0.02, cyclesX: -0.5, cyclesY: 1.0, phase: 2),
            ],
          ),
        );
        var moved = 0;
        for (final p in ramp) {
          expect(p.a, 255);
          expect(
            (p.r - p.g).abs() <= 1 && (p.g - p.b).abs() <= 1,
            isTrue,
            reason: 'greys stay grey: ${[p.r, p.g, p.b]} at ${p.x}',
          );
          if (p.x == 0) expect(p.r, 0);
          if (p.x == 255) expect(p.r, 255);
          expect((p.r - p.x).abs(), lessThanOrEqualTo(10), reason: 'x ${p.x}');
          if (p.r != p.x) moved++;
        }
        expect(moved, greaterThan(256 * 8 ~/ 2));
      },
    );
  });

  test('GIF: colour tables nudged, frames and timing untouched', () {
    const name = 'dou_original_0_15_ni_ye_you_ze_ren.gif'; // local tables
    final original = _asset(name);
    final a = ImageObfuscator(random: Random(1))
        .obfuscate(original, fileName: name);
    final b = ImageObfuscator(random: Random(2))
        .obfuscate(original, fileName: name);
    _dump(name, original, [a, b]);
    expect(a.mimeType, 'image/gif');
    expect(a.bytes, isNot(equals(original)));
    expect(a.bytes, isNot(equals(b.bytes)));
    expect(
      a.bytes.length,
      inInclusiveRange(original.length + 5, original.length + 36),
      reason: 'one comment block of 1-32 bytes',
    );
    _expectSameAnimation(original, a.bytes, reason: name);
  });

  test('a PNG hiding behind a .gif name is obfuscated and renamed as PNG', () {
    // Five bundled memes carry the wrong extension; the bytes decide.
    const name = 'dou_kaogei_0_laugh.gif';
    final original = _asset(name);
    final a = ImageObfuscator(random: Random(1))
        .obfuscate(original, fileName: name);
    expect(a.mimeType, 'image/png');
    expect(a.fileName, 'dou_kaogei_0_laugh.png');
    expect(a.bytes, isNot(equals(original)));
    expect(img.decodePng(a.bytes), isNotNull);
    expect(
      ImageObfuscator()
          .obfuscate(_asset('dou_hd_mo_jing.jpg'), fileName: 'x.jpeg')
          .fileName,
      'x.jpeg',
    );
  });

  // Slow (a minute or two): pushes every bundled image through the obfuscator
  // once and checks size, tone and (for GIFs) every frame.
  test(
    'sweep: every bundled image obfuscates into a similar-looking file',
    () {
      final files =
          Directory('assets/images')
              .listSync()
              .whereType<File>()
              .where(
                (f) => RegExp(
                  r'\.(jpe?g|png|gif)$',
                  caseSensitive: false,
                ).hasMatch(f.path),
              )
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      expect(files.length, greaterThan(300));
      final obfuscator = ImageObfuscator(random: Random(7));
      final timings = <(int, String)>[];
      for (final f in files) {
        final name = f.uri.pathSegments.last;
        final bytes = f.readAsBytesSync();
        final stopwatch = Stopwatch()..start();
        final out = obfuscator.obfuscate(bytes, fileName: name);
        stopwatch.stop();
        expect(out.bytes, isNot(equals(bytes)), reason: name);
        expect(out.mimeType, startsWith('image/'), reason: name);
        if (out.mimeType == 'image/gif') {
          _expectSameAnimation(bytes, out.bytes, reason: name);
        } else {
          final before = img.decodeImage(bytes)!;
          final after = img.decodeImage(out.bytes);
          expect(after, isNotNull, reason: name);
          _expectSizeInEnvelope(before, after!, reason: name);
          _expectSameTone(before, after, reason: name);
        }
        timings.add((
          stopwatch.elapsedMilliseconds,
          '${stopwatch.elapsedMilliseconds} ms '
              '${bytes.length ~/ 1024}->${out.bytes.length ~/ 1024} KB $name',
        ));
      }
      timings.sort((a, b) => b.$1.compareTo(a.$1));
      final total = timings.fold(0, (sum, t) => sum + t.$1);
      // ignore: avoid_print
      print('${files.length} images in $total ms; slowest:');
      // ignore: avoid_print
      print(timings.take(10).map((t) => t.$2).join('\n'));
    },
    skip: Platform.environment.containsKey('OBFUSCATOR_SWEEP')
        ? false
        : 'set OBFUSCATOR_SWEEP=1 to obfuscate the whole library',
  );

  test('unknown or broken input is passed through unchanged', () {
    final junk = Uint8List.fromList(List.generate(64, (i) => i * 7 & 0xFF));
    expect(ImageObfuscator().obfuscate(junk, fileName: 'x.jpg').bytes, junk);
    expect(ImageObfuscator().obfuscate(junk, fileName: 'x.gif').bytes, junk);
    expect(ImageObfuscator().obfuscate(junk, fileName: 'x.bin').bytes, junk);
  });
}
