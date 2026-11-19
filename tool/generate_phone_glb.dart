// Generates `web/demo/assets/phone.glb`, the 3D device used by the animated
// Get Started page, plus `phone.glb.js` — the same bytes as base64, which the
// page only downloads when it runs from `file://` (the desktop app opens it
// that way) and plain `fetch` is refused.
//
// The asset is built here rather than downloaded so the repository stays
// self-contained and the licence is ours. Geometry is deliberately simple but
// genuinely three-dimensional: a rounded slate body, a proud screen plane, a
// camera island with two lenses and three side buttons.
//
//   dart run tool/generate_phone_glb.dart
//
// Writing the container by hand keeps the tool dependency-free; it is a normal
// glTF 2.0 binary (JSON chunk + BIN chunk) that any loader can read.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

// ---------------------------------------------------------------------------
// Geometry
// ---------------------------------------------------------------------------

/// One drawable group: vertices, normals, UVs and triangle indices for a single
/// material.
class _Mesh {
  _Mesh(this.name, this.material);

  final String name;
  final int material;
  final List<double> positions = <double>[];
  final List<double> normals = <double>[];
  final List<double> uvs = <double>[];
  final List<int> indices = <int>[];

  int get vertexCount => positions.length ~/ 3;

  int addVertex(
    double x,
    double y,
    double z,
    double nx,
    double ny,
    double nz, [
    double u = 0,
    double v = 0,
  ]) {
    final index = vertexCount;
    positions
      ..add(x)
      ..add(y)
      ..add(z);
    normals
      ..add(nx)
      ..add(ny)
      ..add(nz);
    uvs
      ..add(u)
      ..add(v);
    return index;
  }

  void addTriangle(int a, int b, int c) {
    indices
      ..add(a)
      ..add(b)
      ..add(c);
  }
}

/// Rounded box built by displacing a subdivided cube onto the surface of a
/// box/sphere Minkowski sum. Faces stay flat, edges and corners get a real
/// fillet, and normals are smooth across the seams.
void _addRoundedBox(
  _Mesh mesh,
  double sx,
  double sy,
  double sz,
  double radius, {
  int segments = 10,
  double ox = 0,
  double oy = 0,
  double oz = 0,
}) {
  final half = <double>[sx / 2, sy / 2, sz / 2];
  // A fillet cannot be larger than the thinnest half-extent, or the inner box
  // inverts and the clamp below gets an empty range.
  final fillet = math.min(radius, half.reduce(math.min) * 0.98);
  final inner = <double>[
    half[0] - fillet,
    half[1] - fillet,
    half[2] - fillet,
  ];

  // axis: the face normal axis, sign: which side, uAxis/vAxis picked so that
  // u × v points outwards (keeping the winding counter-clockwise).
  const faces = <({int axis, int sign, int uAxis, int vAxis})>[
    (axis: 0, sign: 1, uAxis: 1, vAxis: 2),
    (axis: 0, sign: -1, uAxis: 2, vAxis: 1),
    (axis: 1, sign: 1, uAxis: 2, vAxis: 0),
    (axis: 1, sign: -1, uAxis: 0, vAxis: 2),
    (axis: 2, sign: 1, uAxis: 0, vAxis: 1),
    (axis: 2, sign: -1, uAxis: 1, vAxis: 0),
  ];

  for (final face in faces) {
    final base = mesh.vertexCount;
    for (var j = 0; j <= segments; j++) {
      for (var i = 0; i <= segments; i++) {
        final p = List<double>.filled(3, 0);
        p[face.axis] = face.sign * half[face.axis];
        p[face.uAxis] =
            -half[face.uAxis] + 2 * half[face.uAxis] * i / segments;
        p[face.vAxis] =
            -half[face.vAxis] + 2 * half[face.vAxis] * j / segments;

        final n = List<double>.filled(3, 0);
        final q = List<double>.filled(3, 0);
        for (var a = 0; a < 3; a++) {
          q[a] = p[a].clamp(-inner[a], inner[a]);
          n[a] = p[a] - q[a];
        }
        final length = math.sqrt(n[0] * n[0] + n[1] * n[1] + n[2] * n[2]);
        final inv = length == 0 ? 0.0 : 1 / length;
        for (var a = 0; a < 3; a++) {
          n[a] *= inv;
          q[a] += n[a] * fillet;
        }

        mesh.addVertex(
          q[0] + ox,
          q[1] + oy,
          q[2] + oz,
          n[0],
          n[1],
          n[2],
          i / segments,
          j / segments,
        );
      }
    }
    for (var j = 0; j < segments; j++) {
      for (var i = 0; i < segments; i++) {
        final a = base + j * (segments + 1) + i;
        final b = a + 1;
        final c = a + segments + 2;
        final d = a + segments + 1;
        mesh.addTriangle(a, b, c);
        mesh.addTriangle(a, c, d);
      }
    }
  }
}

/// Flat rounded rectangle in XY at [z], facing +Z, with UVs spanning the
/// rectangle. Used for the screen so a canvas texture sits inside the bezel.
void _addRoundedPlane(  _Mesh mesh,
  double width,
  double height,
  double radius,
  double z, {
  int cornerSegments = 12,
}) {
  final hw = width / 2;
  final hh = height / 2;
  final r = radius;

  // Corner centres in counter-clockwise order, starting bottom-right.
  final corners = <({double x, double y, double start})>[
    (x: hw - r, y: -hh + r, start: -math.pi / 2),
    (x: hw - r, y: hh - r, start: 0),
    (x: -hw + r, y: hh - r, start: math.pi / 2),
    (x: -hw + r, y: -hh + r, start: math.pi),
  ];

  final outline = <({double x, double y})>[];
  for (final corner in corners) {
    for (var i = 0; i <= cornerSegments; i++) {
      final a = corner.start + (math.pi / 2) * i / cornerSegments;
      outline.add((
        x: corner.x + math.cos(a) * r,
        y: corner.y + math.sin(a) * r,
      ));
    }
  }

  final centre = mesh.addVertex(0, 0, z, 0, 0, 1, 0.5, 0.5);
  final first = mesh.vertexCount;
  for (final point in outline) {
    mesh.addVertex(
      point.x,
      point.y,
      z,
      0,
      0,
      1,
      (point.x + hw) / width,
      (point.y + hh) / height,
    );
  }
  for (var i = 0; i < outline.length; i++) {
    final current = first + i;
    final next = first + (i + 1) % outline.length;
    mesh.addTriangle(centre, current, next);
  }
}

/// Outline of a rounded rectangle, counter-clockwise, with the outward normal
/// stored on every point.
///
/// Corner arcs and straight edges are both single spans, so the seam between
/// them shares one normal and stays smooth.
List<({double x, double y, double nx, double ny})> _roundedRectOutline(
  double hw,
  double hh,
  double r,
  int cornerSegments,
) {
  final corners = <({double x, double y, double start})>[
    (x: hw - r, y: -hh + r, start: -math.pi / 2),
    (x: hw - r, y: hh - r, start: 0),
    (x: -hw + r, y: hh - r, start: math.pi / 2),
    (x: -hw + r, y: -hh + r, start: math.pi),
  ];

  final points = <({double x, double y, double nx, double ny})>[];
  for (final corner in corners) {
    for (var i = 0; i <= cornerSegments; i++) {
      final a = corner.start + (math.pi / 2) * i / cornerSegments;
      final nx = math.cos(a);
      final ny = math.sin(a);
      points.add((
        x: corner.x + nx * r,
        y: corner.y + ny * r,
        nx: nx,
        ny: ny,
      ));
    }
  }
  return points;
}

/// Rounded rectangle in XY, extruded along Z with a bevelled rim.
///
/// [_addRoundedBox] ties the corner radius to the thinnest axis, so on a slab
/// as thin as a phone the corners can only ever be shallow. Here the plan-view
/// radius is free of the thickness: the outline follows the full corner arc and
/// a small bevel turns it into the front and back faces, which is what gives a
/// device its wide, soft corners and a rim that catches the light.
void _addRoundedPrism(
  _Mesh mesh,
  double width,
  double height,
  double depth,
  double cornerRadius, {
  double bevel = 0.008,
  int cornerSegments = 24,
  int bevelSegments = 4,
  double ox = 0,
  double oy = 0,
  double zBack = 0,
}) {
  final hw = width / 2;
  final hh = height / 2;
  final r = math.min(cornerRadius, math.min(hw, hh));
  final b = math.min(bevel, depth / 2 * 0.9);
  final zFront = zBack + depth;
  final outline = _roundedRectOutline(hw, hh, r, cornerSegments);

  // One entry per ring: how far the outline is pulled in, its Z, and how much
  // of the normal points sideways (nr) versus along Z (nz).
  final rings = <({double inset, double z, double nr, double nz})>[];
  rings.add((inset: b, z: zBack, nr: 0, nz: -1));
  for (var k = 1; k <= bevelSegments; k++) {
    final t = -math.pi / 2 + (math.pi / 2) * k / bevelSegments;
    rings.add((
      inset: b * (1 - math.cos(t)),
      z: zBack + b + b * math.sin(t),
      nr: math.cos(t),
      nz: math.sin(t),
    ));
  }
  for (var k = 0; k <= bevelSegments; k++) {
    final t = (math.pi / 2) * k / bevelSegments;
    rings.add((
      inset: b * (1 - math.cos(t)),
      z: zFront - b + b * math.sin(t),
      nr: math.cos(t),
      nz: math.sin(t),
    ));
  }

  final ringStart = <int>[];
  for (final ring in rings) {
    ringStart.add(mesh.vertexCount);
    for (final point in outline) {
      final x = point.x - point.nx * ring.inset;
      final y = point.y - point.ny * ring.inset;
      mesh.addVertex(
        x + ox,
        y + oy,
        ring.z,
        point.nx * ring.nr,
        point.ny * ring.nr,
        ring.nz,
        (x + hw) / width,
        (y + hh) / height,
      );
    }
  }

  final count = outline.length;
  for (var ring = 0; ring < rings.length - 1; ring++) {
    final a0 = ringStart[ring];
    final b0 = ringStart[ring + 1];
    for (var i = 0; i < count; i++) {
      final next = (i + 1) % count;
      final a = a0 + i;
      final b = a0 + next;
      final c = b0 + next;
      final d = b0 + i;
      mesh.addTriangle(a, b, c);
      mesh.addTriangle(a, c, d);
    }
  }

  // Caps: the same outline pulled in by the bevel, fanned from the centre.
  final backCentre = mesh.addVertex(ox, oy, zBack, 0, 0, -1, 0.5, 0.5);
  final backRing = ringStart.first;
  for (var i = 0; i < count; i++) {
    final next = (i + 1) % count;
    mesh.addTriangle(backCentre, backRing + next, backRing + i);
  }

  final frontCentre = mesh.addVertex(ox, oy, zFront, 0, 0, 1, 0.5, 0.5);
  final frontRing = ringStart.last;
  for (var i = 0; i < count; i++) {
    final next = (i + 1) % count;
    mesh.addTriangle(frontCentre, frontRing + i, frontRing + next);
  }
}

/// Cylinder along Z, centred at ([cx], [cy], [cz]).
void _addCylinder(
  _Mesh mesh,
  double radius,
  double depth,
  double cx,
  double cy,
  double cz, {
  int segments = 28,
}) {
  final half = depth / 2;

  // Side wall.
  final sideStart = mesh.vertexCount;
  for (var i = 0; i <= segments; i++) {
    final a = 2 * math.pi * i / segments;
    final nx = math.cos(a);
    final ny = math.sin(a);
    mesh.addVertex(cx + nx * radius, cy + ny * radius, cz - half, nx, ny, 0);
    mesh.addVertex(cx + nx * radius, cy + ny * radius, cz + half, nx, ny, 0);
  }
  for (var i = 0; i < segments; i++) {
    final a = sideStart + i * 2;
    final b = a + 1;
    final c = a + 3;
    final d = a + 2;
    mesh.addTriangle(a, b, c);
    mesh.addTriangle(a, c, d);
  }

  // Caps.
  for (final direction in <int>[1, -1]) {
    final z = cz + direction * half;
    final centre = mesh.addVertex(cx, cy, z, 0, 0, direction.toDouble());
    final ring = mesh.vertexCount;
    for (var i = 0; i <= segments; i++) {
      final a = 2 * math.pi * i / segments;
      mesh.addVertex(
        cx + math.cos(a) * radius,
        cy + math.sin(a) * radius,
        z,
        0,
        0,
        direction.toDouble(),
      );
    }
    for (var i = 0; i < segments; i++) {
      final p = ring + i;
      final q = ring + i + 1;
      if (direction > 0) {
        mesh.addTriangle(centre, p, q);
      } else {
        mesh.addTriangle(centre, q, p);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// glTF writer
// ---------------------------------------------------------------------------

class _GltfBuilder {
  final BytesBuilder _bin = BytesBuilder();
  final List<Map<String, Object?>> _accessors = <Map<String, Object?>>[];
  final List<Map<String, Object?>> _bufferViews = <Map<String, Object?>>[];

  int _align() {
    while (_bin.length % 4 != 0) {
      _bin.addByte(0);
    }
    return _bin.length;
  }

  int _addView(Uint8List bytes, int target) {
    final offset = _align();
    _bin.add(bytes);
    _bufferViews.add(<String, Object?>{
      'buffer': 0,
      'byteOffset': offset,
      'byteLength': bytes.lengthInBytes,
      'target': target,
    });
    return _bufferViews.length - 1;
  }

  int addFloats(Float32List data, String type, int components) {
    final view = _addView(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      34962, // ARRAY_BUFFER
    );
    final accessor = <String, Object?>{
      'bufferView': view,
      'componentType': 5126, // FLOAT
      'count': data.length ~/ components,
      'type': type,
    };
    if (type == 'VEC3') {
      var minX = double.infinity, minY = double.infinity, minZ = double.infinity;
      var maxX = double.negativeInfinity,
          maxY = double.negativeInfinity,
          maxZ = double.negativeInfinity;
      for (var i = 0; i < data.length; i += 3) {
        minX = math.min(minX, data[i]);
        minY = math.min(minY, data[i + 1]);
        minZ = math.min(minZ, data[i + 2]);
        maxX = math.max(maxX, data[i]);
        maxY = math.max(maxY, data[i + 1]);
        maxZ = math.max(maxZ, data[i + 2]);
      }
      accessor['min'] = <double>[minX, minY, minZ];
      accessor['max'] = <double>[maxX, maxY, maxZ];
    }
    _accessors.add(accessor);
    return _accessors.length - 1;
  }

  int addIndices(Uint32List data) {
    final view = _addView(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      34963, // ELEMENT_ARRAY_BUFFER
    );
    _accessors.add(<String, Object?>{
      'bufferView': view,
      'componentType': 5125, // UNSIGNED_INT
      'count': data.length,
      'type': 'SCALAR',
    });
    return _accessors.length - 1;
  }

  Uint8List finish(List<_Mesh> meshes) {
    final materials = <Map<String, Object?>>[
      // 0 — body
      <String, Object?>{
        'name': 'Body',
        'doubleSided': false,
        'pbrMetallicRoughness': <String, Object?>{
          'baseColorFactor': <double>[0.105, 0.086, 0.145, 1.0],
          'metallicFactor': 0.82,
          'roughnessFactor': 0.30,
        },
      },
      // 1 — screen (replaced with a CanvasTexture at runtime)
      <String, Object?>{
        'name': 'Screen',
        'doubleSided': false,
        'pbrMetallicRoughness': <String, Object?>{
          'baseColorFactor': <double>[0.035, 0.025, 0.06, 1.0],
          'metallicFactor': 0.0,
          'roughnessFactor': 1.0,
        },
        'emissiveFactor': <double>[0.04, 0.03, 0.07],
      },
      // 2 — camera island
      <String, Object?>{
        'name': 'CameraIsland',
        'pbrMetallicRoughness': <String, Object?>{
          'baseColorFactor': <double>[0.075, 0.062, 0.105, 1.0],
          'metallicFactor': 0.55,
          'roughnessFactor': 0.45,
        },
      },
      // 3 — lens glass
      <String, Object?>{
        'name': 'Lens',
        'pbrMetallicRoughness': <String, Object?>{
          'baseColorFactor': <double>[0.015, 0.015, 0.022, 1.0],
          'metallicFactor': 0.25,
          'roughnessFactor': 0.08,
        },
      },
      // 4 — buttons
      <String, Object?>{
        'name': 'Button',
        'pbrMetallicRoughness': <String, Object?>{
          'baseColorFactor': <double>[0.24, 0.205, 0.32, 1.0],
          'metallicFactor': 0.9,
          'roughnessFactor': 0.28,
        },
      },
      // 5 — front glass: near-black and very smooth, so the environment map
      // reads as a reflection across it.
      <String, Object?>{
        'name': 'Glass',
        'pbrMetallicRoughness': <String, Object?>{
          'baseColorFactor': <double>[0.021, 0.018, 0.031, 1.0],
          'metallicFactor': 0.2,
          'roughnessFactor': 0.055,
        },
      },
      // 6 — earpiece slot / speaker grille
      <String, Object?>{
        'name': 'Speaker',
        'pbrMetallicRoughness': <String, Object?>{
          'baseColorFactor': <double>[0.018, 0.015, 0.026, 1.0],
          'metallicFactor': 0.45,
          'roughnessFactor': 0.6,
        },
      },
    ];

    final nodes = <Map<String, Object?>>[
      <String, Object?>{'name': 'PhoneRoot', 'children': <int>[]},
    ];
    final gltfMeshes = <Map<String, Object?>>[];

    for (final mesh in meshes) {
      final position = addFloats(Float32List.fromList(mesh.positions), 'VEC3', 3);
      final normal = addFloats(Float32List.fromList(mesh.normals), 'VEC3', 3);
      final uv = addFloats(Float32List.fromList(mesh.uvs), 'VEC2', 2);
      final index = addIndices(Uint32List.fromList(mesh.indices));

      gltfMeshes.add(<String, Object?>{
        'name': mesh.name,
        'primitives': <Map<String, Object?>>[
          <String, Object?>{
            'attributes': <String, Object?>{
              'POSITION': position,
              'NORMAL': normal,
              'TEXCOORD_0': uv,
            },
            'indices': index,
            'material': mesh.material,
          },
        ],
      });
      nodes.add(<String, Object?>{
        'name': mesh.name,
        'mesh': gltfMeshes.length - 1,
      });
      (nodes[0]['children'] as List<int>).add(nodes.length - 1);
    }

    final gltf = <String, Object?>{
      'asset': <String, Object?>{
        'version': '2.0',
        'generator': 'smartpos generate_phone_glb.dart',
      },
      'scene': 0,
      'scenes': <Map<String, Object?>>[
        <String, Object?>{
          'nodes': <int>[0],
        },
      ],
      'nodes': nodes,
      'meshes': gltfMeshes,
      'materials': materials,
      'accessors': _accessors,
      'bufferViews': _bufferViews,
      'buffers': <Map<String, Object?>>[
        <String, Object?>{'byteLength': _align()},
      ],
    };

    var json =
        utf8.encode(const JsonEncoder.withIndent(' ').convert(gltf)).toList();
    while (json.length % 4 != 0) {
      json = <int>[...json, 0x20];
    }

    final bin = _bin.toBytes();
    final paddedBin = bin.length % 4 == 0
        ? bin
        : Uint8List.fromList(<int>[...bin, ...List<int>.filled(4 - bin.length % 4, 0)]);

    final total = 12 + 8 + json.length + 8 + paddedBin.length;
    final out = BytesBuilder();
    final header = ByteData(12)
      ..setUint32(0, 0x46546C67, Endian.little) // "glTF"
      ..setUint32(4, 2, Endian.little)
      ..setUint32(8, total, Endian.little);
    out.add(header.buffer.asUint8List());

    final jsonHeader = ByteData(8)
      ..setUint32(0, json.length, Endian.little)
      ..setUint32(4, 0x4E4F534A, Endian.little); // "JSON"
    out
      ..add(jsonHeader.buffer.asUint8List())
      ..add(json);

    final binHeader = ByteData(8)
      ..setUint32(0, paddedBin.length, Endian.little)
      ..setUint32(4, 0x004E4942, Endian.little); // "BIN\0"
    out
      ..add(binHeader.buffer.asUint8List())
      ..add(paddedBin);

    return out.toBytes();
  }
}

// ---------------------------------------------------------------------------
// The device
// ---------------------------------------------------------------------------

List<_Mesh> _buildPhone() {
  // Body: a 1.02 × 2.12 slab with the wide corners of a real handset. The
  // corner radius (0.132) is 13% of the width, close to a modern phone; the
  // 0.02 rim bevel is what a finger would feel around the frame.
  final body = _Mesh('Body', 0);
  _addRoundedPrism(
    body,
    1.020,
    2.120,
    0.115,
    0.132,
    bevel: 0.020,
    cornerSegments: 28,
    bevelSegments: 5,
    zBack: -0.0575,
  );

  // Front glass, sitting proud of the frame so its edge reads as a real sheet
  // rather than a painted-on layer. Its widest ring must clear the body's front
  // face: land it here and the bevel crosses that plane at an angle instead of
  // grazing it, which would shimmer as a dotted line along the rim.
  final glass = _Mesh('Glass', 5);
  _addRoundedPrism(
    glass,
    0.972,
    2.072,
    0.012,
    0.108,
    bevel: 0.004,
    cornerSegments: 26,
    bevelSegments: 3,
    zBack: 0.0565,
  );

  // Screen: the canvas texture, inset inside the glass so an even black bezel
  // shows all the way around. Concentric corners: 0.132 - 0.024 - 0.012.
  final screen = _Mesh('Screen', 1);
  _addRoundedPlane(screen, 0.940, 2.040, 0.096, 0.0692);

  // Earpiece slot on the top edge, just proud of the frame.
  final speaker = _Mesh('Speaker', 6);
  _addRoundedBox(
    speaker,
    0.180,
    0.008,
    0.030,
    0.0038,
    segments: 8,
    oy: 1.0570,
    oz: 0.004,
  );

  // Camera island on the back (-Z), with two lenses.
  final island = _Mesh('CameraIsland', 2);
  _addRoundedBox(
    island,
    0.360,
    0.440,
    0.030,
    0.052,
    segments: 8,
    ox: -0.215,
    oy: 0.660,
    oz: -0.0645,
  );

  final lensA = _Mesh('LensTop', 3);
  _addCylinder(lensA, 0.062, 0.022, -0.215, 0.755, -0.089);

  final lensB = _Mesh('LensBottom', 3);
  _addCylinder(lensB, 0.062, 0.022, -0.215, 0.560, -0.089);

  // Side buttons: volume rocker and power on the right, mute on the left.
  // Thin and barely proud of the frame, the way real buttons sit.
  final volume = _Mesh('VolumeButton', 4);
  _addRoundedBox(
    volume,
    0.014,
    0.180,
    0.030,
    0.0055,
    segments: 8,
    ox: 0.508,
    oy: 0.430,
  );

  final power = _Mesh('PowerButton', 4);
  _addRoundedBox(
    power,
    0.014,
    0.120,
    0.030,
    0.0055,
    segments: 8,
    ox: 0.508,
    oy: 0.150,
  );

  final mute = _Mesh('MuteButton', 4);
  _addRoundedBox(
    mute,
    0.014,
    0.070,
    0.026,
    0.0055,
    segments: 8,
    ox: -0.508,
    oy: 0.520,
  );

  return <_Mesh>[
    body,
    glass,
    screen,
    speaker,
    island,
    lensA,
    lensB,
    volume,
    power,
    mute,
  ];
}

void main(List<String> args) {
  final output = args.isNotEmpty
      ? args.first
      : 'web/demo/assets/phone.glb';

  final meshes = _buildPhone();
  final bytes = _GltfBuilder().finish(meshes);
  final file = File(output);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);

  // `fetch` cannot read a sibling file on a `file://` page, and the demo is
  // opened straight from disk by the desktop app. The base64 twin is only
  // requested when that fetch fails, so HTTP visitors never download it.
  final js = File(
    [file.parent.path, 'phone.glb.js'].join(Platform.pathSeparator),
  );
  js.writeAsStringSync(
    '/* generated by tool/generate_phone_glb.dart — do not edit */\n'
    'window.PHONE_GLB_BASE64 = "${base64Encode(bytes)}";\n',
  );

  stdout.writeln(
    'Wrote ${file.path} (${(bytes.length / 1024).toStringAsFixed(1)} KB) — '
    '${meshes.length} parts\n'
    'Wrote ${js.path} (${(js.lengthSync() / 1024).toStringAsFixed(0)} KB)',
  );
}
