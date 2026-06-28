import 'dart:io';
import 'package:path/path.dart' as p;

class AudioMetadataHasher {
  // FNV-1a 32-bit hash algorithm
  static int _hashBytes(List<int> bytes, [int seed = 2166136261]) {
    int hash = seed;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash;
  }

  // Generate file hash using FNV-1a + file size
  static String calculateHash(File file) {
    final size = file.lengthSync();
    final ext = p.extension(file.path).toLowerCase();

    RandomAccessFile? raf;
    try {
      raf = file.openSync(mode: FileMode.read);
      List<int> metadataBytes = [];

      switch (ext) {
        case '.mp3':
          metadataBytes = _extractMP3Metadata(raf, size);
          break;
        case '.flac':
          metadataBytes = _extractFLACMetadata(raf, size);
          break;
        case '.m4a':
        case '.mp4':
          metadataBytes = _extractMP4Metadata(raf, size);
          break;
        case '.wav':
          metadataBytes = _extractWAVMetadata(raf, size);
          break;
        case '.ogg':
        case '.oga':
        case '.opus':
          metadataBytes = _extractOggMetadata(raf, size);
          break;
        case '.wma':
          metadataBytes = _extractWMAMetadata(raf, size);
          break;
        case '.ape':
        case '.wv':
          metadataBytes = _extractAPEv2Metadata(raf, size);
          break;
        default:
          metadataBytes = _extractFallbackMetadata(raf, size);
          break;
      }

      raf.closeSync();
      raf = null;

      if (metadataBytes.isEmpty || metadataBytes.length < 64) {
        // If parsing returned empty or too small, run fallback
        raf = file.openSync(mode: FileMode.read);
        metadataBytes = _extractFallbackMetadata(raf, size);
        raf.closeSync();
        raf = null;
      }

      final hashVal = _hashBytes(metadataBytes);
      return '${hashVal.toRadixString(16)}_$size';
    } catch (e) {
      try {
        raf?.closeSync();
      } catch (_) {}
      // Robust fallback if reading file fails: hash of path + size
      final pathHash = _hashBytes(file.path.codeUnits);
      return '${pathHash.toRadixString(16)}_$size';
    }
  }

  static List<int> _extractMP3Metadata(RandomAccessFile raf, int fileSize) {
    final List<int> bytes = [];
    try {
      raf.setPositionSync(0);
      final id3v2Header = raf.readSync(10);
      if (id3v2Header.length >= 10 &&
          id3v2Header[0] == 0x49 && // 'I'
          id3v2Header[1] == 0x44 && // 'D'
          id3v2Header[2] == 0x33) {
        // '3'
        // Synchsafe integer parsing (7 bits per byte)
        final tagSize =
            ((id3v2Header[6] & 0x7F) << 21) |
            ((id3v2Header[7] & 0x7F) << 14) |
            ((id3v2Header[8] & 0x7F) << 7) |
            (id3v2Header[9] & 0x7F);

        final hasFooter = (id3v2Header[5] & 0x10) != 0;
        final totalTagSize = 10 + tagSize + (hasFooter ? 10 : 0);
        if (totalTagSize <= fileSize) {
          raf.setPositionSync(0);
          bytes.addAll(raf.readSync(totalTagSize));
        }
      }

      // Also extract APEv2 / ID3v1 at the end of the file
      bytes.addAll(_extractAPEv2Metadata(raf, fileSize));
    } catch (_) {}
    return bytes;
  }

  static List<int> _extractFLACMetadata(RandomAccessFile raf, int fileSize) {
    final List<int> bytes = [];
    try {
      raf.setPositionSync(0);
      final sig = raf.readSync(4);
      if (sig.length < 4 ||
          sig[0] != 0x66 || // 'f'
          sig[1] != 0x4C || // 'L'
          sig[2] != 0x61 || // 'a'
          sig[3] != 0x43) {
        // 'C'
        return bytes;
      }

      bytes.addAll(sig);
      int offset = 4;
      bool isLast = false;

      while (!isLast && offset < fileSize) {
        raf.setPositionSync(offset);
        final header = raf.readSync(4);
        if (header.length < 4) break;

        isLast = (header[0] & 0x80) != 0;
        final blockLength = ((header[1] & 0xFF) << 16) | ((header[2] & 0xFF) << 8) | (header[3] & 0xFF);

        if (offset + 4 + blockLength > fileSize) break;

        raf.setPositionSync(offset);
        final blockData = raf.readSync(4 + blockLength);
        bytes.addAll(blockData);

        offset += 4 + blockLength;
      }
    } catch (_) {}
    return bytes;
  }

  static List<int> _extractMP4Metadata(RandomAccessFile raf, int fileSize) {
    final List<int> bytes = [];
    try {
      int offset = 0;
      while (offset < fileSize) {
        raf.setPositionSync(offset);
        final header = raf.readSync(8);
        if (header.length < 8) break;

        int size =
            ((header[0] & 0xFF) << 24) | ((header[1] & 0xFF) << 16) | ((header[2] & 0xFF) << 8) | (header[3] & 0xFF);
        final type = String.fromCharCodes(header.sublist(4, 8));

        int headerSize = 8;
        if (size == 1) {
          // Large size (8 bytes) follows
          final largeHeader = raf.readSync(8);
          if (largeHeader.length < 8) break;
          size =
              ((largeHeader[0] & 0xFF) << 56) |
              ((largeHeader[1] & 0xFF) << 48) |
              ((largeHeader[2] & 0xFF) << 40) |
              ((largeHeader[3] & 0xFF) << 32) |
              ((largeHeader[4] & 0xFF) << 24) |
              ((largeHeader[5] & 0xFF) << 16) |
              ((largeHeader[6] & 0xFF) << 8) |
              (largeHeader[7] & 0xFF);
          headerSize = 16;
        }

        if (size < headerSize || offset + size > fileSize) break;

        if (type == 'moov' || type == 'ftyp') {
          raf.setPositionSync(offset);
          bytes.addAll(raf.readSync(size));
        } else if (type == 'mdat') {
          // Hash only the header of 'mdat' to keep metadata changes independent of raw data
          // and to avoid reading the massive audio payload.
          raf.setPositionSync(offset);
          bytes.addAll(raf.readSync(headerSize));
        }

        offset += size;
      }
    } catch (_) {}
    return bytes;
  }

  static List<int> _extractWAVMetadata(RandomAccessFile raf, int fileSize) {
    final List<int> bytes = [];
    try {
      raf.setPositionSync(0);
      final riffHeader = raf.readSync(12);
      if (riffHeader.length < 12) return bytes;

      final riffStr = String.fromCharCodes(riffHeader.sublist(0, 4));
      final waveStr = String.fromCharCodes(riffHeader.sublist(8, 12));
      if (riffStr != 'RIFF' || waveStr != 'WAVE') return bytes;

      bytes.addAll(riffHeader);
      int offset = 12;

      while (offset < fileSize) {
        raf.setPositionSync(offset);
        final chunkHeader = raf.readSync(8);
        if (chunkHeader.length < 8) break;

        final type = String.fromCharCodes(chunkHeader.sublist(0, 4));
        final size =
            (chunkHeader[4] & 0xFF) |
            ((chunkHeader[5] & 0xFF) << 8) |
            ((chunkHeader[6] & 0xFF) << 16) |
            ((chunkHeader[7] & 0xFF) << 24);

        if (size < 0 || offset + 8 + size > fileSize) break;

        if (type != 'data') {
          raf.setPositionSync(offset);
          bytes.addAll(raf.readSync(8 + size));
        } else {
          // Keep chunk header of 'data' to maintain layout/alignment
          bytes.addAll(chunkHeader);
        }

        offset += 8 + size;
        if (size % 2 != 0) offset += 1; // RIFF chunk padding
      }
    } catch (_) {}
    return bytes;
  }

  static List<int> _extractOggMetadata(RandomAccessFile raf, int fileSize) {
    final List<int> bytes = [];
    try {
      raf.setPositionSync(0);
      int offset = 0;
      int completedPackets = 0;

      // We read up to the first 3 completed packets, which covers all header packets (ident, comments, setup)
      while (offset < fileSize && completedPackets < 3) {
        raf.setPositionSync(offset);
        final header = raf.readSync(27);
        if (header.length < 27) break;

        if (header[0] != 0x4F || // 'O'
            header[1] != 0x67 || // 'g'
            header[2] != 0x67 || // 'g'
            header[3] != 0x53) {
          // 'S'
          break;
        }

        final numSegments = header[26];
        final segmentTable = raf.readSync(numSegments);
        if (segmentTable.length < numSegments) break;

        int pageDataSize = 0;
        for (final segLen in segmentTable) {
          pageDataSize += segLen;
          if (segLen < 255) {
            completedPackets++;
          }
        }

        final totalPageSize = 27 + numSegments + pageDataSize;
        raf.setPositionSync(offset);
        bytes.addAll(raf.readSync(totalPageSize));

        offset += totalPageSize;
      }
    } catch (_) {}
    return bytes;
  }

  static List<int> _extractWMAMetadata(RandomAccessFile raf, int fileSize) {
    final List<int> bytes = [];
    try {
      int offset = 0;
      while (offset < fileSize) {
        raf.setPositionSync(offset);
        final header = raf.readSync(24); // 16 bytes GUID + 8 bytes size
        if (header.length < 24) break;

        final size =
            (header[16] & 0xFF) |
            ((header[17] & 0xFF) << 8) |
            ((header[18] & 0xFF) << 16) |
            ((header[19] & 0xFF) << 24) |
            ((header[20] & 0xFF) << 32) |
            ((header[21] & 0xFF) << 40) |
            ((header[22] & 0xFF) << 48) |
            ((header[23] & 0xFF) << 56);

        if (size < 24 || offset + size > fileSize) break;

        // Header Object GUID: 75B22630-66E6-11CF-A6D9-00AA0062ECE6
        final isHeaderObject =
            header[0] == 0x30 &&
            header[1] == 0x26 &&
            header[2] == 0xB2 &&
            header[3] == 0x75 &&
            header[4] == 0xE6 &&
            header[5] == 0x66 &&
            header[6] == 0xCF &&
            header[7] == 0x11 &&
            header[8] == 0xA6 &&
            header[9] == 0xD9 &&
            header[10] == 0x00 &&
            header[11] == 0xAA &&
            header[12] == 0x00 &&
            header[13] == 0x62 &&
            header[14] == 0xEC &&
            header[15] == 0xE6;

        // Data Object GUID: 75B22636-66E6-11CF-A6D9-00AA0062ECE6
        final isDataObject =
            header[0] == 0x36 &&
            header[1] == 0x26 &&
            header[2] == 0xB2 &&
            header[3] == 0x75 &&
            header[4] == 0xE6 &&
            header[5] == 0x66 &&
            header[6] == 0xCF &&
            header[7] == 0x11 &&
            header[8] == 0xA6 &&
            header[9] == 0xD9 &&
            header[10] == 0x00 &&
            header[11] == 0xAA &&
            header[12] == 0x00 &&
            header[13] == 0x62 &&
            header[14] == 0xEC &&
            header[15] == 0xE6;

        if (isHeaderObject) {
          raf.setPositionSync(offset);
          bytes.addAll(raf.readSync(size));
        } else if (isDataObject) {
          // Hash only the header of data object to avoid loading the audio payload
          bytes.addAll(header);
        }

        offset += size;
      }
    } catch (_) {}
    return bytes;
  }

  static List<int> _extractAPEv2Metadata(RandomAccessFile raf, int fileSize) {
    final List<int> bytes = [];
    try {
      // First, check if there is an ID3v1 tag at the end
      bool hasId3v1 = false;
      if (fileSize >= 128) {
        raf.setPositionSync(fileSize - 128);
        final id3v1 = raf.readSync(128);
        if (id3v1.length == 128 &&
            id3v1[0] == 0x54 && // 'T'
            id3v1[1] == 0x41 && // 'A'
            id3v1[2] == 0x47) {
          // 'G'
          hasId3v1 = true;
          bytes.addAll(id3v1); // Hash the ID3v1 tag
        }
      }

      // Look for APEv2 footer
      int footerOffset = -1;
      if (hasId3v1 && fileSize >= 128 + 32) {
        footerOffset = fileSize - 128 - 32;
      } else if (fileSize >= 32) {
        footerOffset = fileSize - 32;
      }

      if (footerOffset >= 0) {
        raf.setPositionSync(footerOffset);
        final footer = raf.readSync(32);
        if (footer.length == 32 &&
            footer[0] == 0x41 && // 'A'
            footer[1] == 0x50 && // 'P'
            footer[2] == 0x45 && // 'E'
            footer[3] == 0x54 && // 'T'
            footer[4] == 0x41 && // 'A'
            footer[5] == 0x47 && // 'G'
            footer[6] == 0x45 && // 'E'
            footer[7] == 0x58) {
          // 'X'
          // APE tag found! Read the tag size (bytes 12-15, little-endian)
          final tagSize = footer[12] | (footer[13] << 8) | (footer[14] << 16) | (footer[15] << 24);

          final startOffset = footerOffset - tagSize;
          if (startOffset >= 0 && startOffset < footerOffset) {
            raf.setPositionSync(startOffset);
            final tagData = raf.readSync(tagSize + 32);
            bytes.addAll(tagData);
          }
        }
      }
    } catch (_) {}
    return bytes;
  }

  static List<int> _extractFallbackMetadata(RandomAccessFile raf, int fileSize) {
    final List<int> bytes = [];
    try {
      // Read the first 512 KB
      final numBytesStart = fileSize < 524288 ? fileSize : 524288;
      raf.setPositionSync(0);
      bytes.addAll(raf.readSync(numBytesStart));

      if (fileSize > 524288) {
        // Read the last 128 KB
        final readSize = fileSize - 524288 < 131072 ? fileSize - 524288 : 131072;
        raf.setPositionSync(fileSize - readSize);
        bytes.addAll(raf.readSync(readSize));
      }
    } catch (_) {}
    return bytes;
  }
}
