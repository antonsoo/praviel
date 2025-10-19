/// Models for Reader feature - browsing and reading classical texts.
///
/// These models mirror the backend Pydantic models defined in:
/// backend/app/models/reader.py
library;

/// Information about a text work (book, dialogue, etc.).
class TextWorkInfo {
  TextWorkInfo({
    required this.id,
    required this.author,
    required this.title,
    required this.language,
    required this.refScheme,
    required this.segmentCount,
    required this.licenseName,
    this.licenseUrl,
    required this.sourceTitle,
  });

  /// Database ID of the work
  final int id;

  /// Author name (e.g., 'Homer', 'Plato')
  final String author;

  /// Work title (e.g., 'Iliad', 'Apology')
  final String title;

  /// Language code (e.g., 'grc' for Ancient Greek)
  final String language;

  /// Reference scheme (e.g., 'book.line', 'stephanus', 'chapter.verse')
  final String refScheme;

  /// Total number of text segments (lines, pages, verses)
  final int segmentCount;

  /// License name (e.g., 'CC BY-SA 3.0')
  final String licenseName;

  /// URL to full license text
  final String? licenseUrl;

  /// Source document title (e.g., 'Perseus Digital Library')
  final String sourceTitle;

  factory TextWorkInfo.fromJson(Map<String, dynamic> json) {
    return TextWorkInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      author: json['author'] as String? ?? '',
      title: json['title'] as String? ?? '',
      language: json['language'] as String? ?? 'grc',
      refScheme: json['ref_scheme'] as String? ?? 'book.line',
      segmentCount: (json['segment_count'] as num?)?.toInt() ?? 0,
      licenseName: json['license_name'] as String? ?? 'Unknown',
      licenseUrl: json['license_url'] as String?,
      sourceTitle: json['source_title'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'title': title,
      'language': language,
      'ref_scheme': refScheme,
      'segment_count': segmentCount,
      'license_name': licenseName,
      'license_url': licenseUrl,
      'source_title': sourceTitle,
    };
  }
}

/// Information about a book within a work (for book.line reference scheme).
class BookInfo {
  BookInfo({
    required this.book,
    required this.lineCount,
    required this.firstLine,
    required this.lastLine,
  });

  /// Book number
  final int book;

  /// Number of lines in this book
  final int lineCount;

  /// First line number
  final int firstLine;

  /// Last line number
  final int lastLine;

  factory BookInfo.fromJson(Map<String, dynamic> json) {
    return BookInfo(
      book: (json['book'] as num?)?.toInt() ?? 0,
      lineCount: (json['line_count'] as num?)?.toInt() ?? 0,
      firstLine: (json['first_line'] as num?)?.toInt() ?? 0,
      lastLine: (json['last_line'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'line_count': lineCount,
      'first_line': firstLine,
      'last_line': lastLine,
    };
  }
}

/// Structural metadata for a text work.
class TextStructure {
  TextStructure({
    required this.textId,
    required this.title,
    required this.author,
    required this.refScheme,
    this.books,
    this.pages,
    this.chapters,
  });

  /// Database ID of the work
  final int textId;

  /// Work title
  final String title;

  /// Author name
  final String author;

  /// Reference scheme
  final String refScheme;

  /// Book metadata (for book.line scheme - Homer)
  final List<BookInfo>? books;

  /// Stephanus page list (for stephanus scheme - Plato)
  final List<String>? pages;

  /// Chapter metadata (for chapter.verse scheme - future)
  final List<Map<String, dynamic>>? chapters;

  factory TextStructure.fromJson(Map<String, dynamic> json) {
    final booksJson = json['books'] as List<dynamic>?;
    final pagesJson = json['pages'] as List<dynamic>?;
    final chaptersJson = json['chapters'] as List<dynamic>?;

    return TextStructure(
      textId: (json['text_id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      refScheme: json['ref_scheme'] as String? ?? 'book.line',
      books: booksJson
          ?.map((item) => BookInfo.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      pages: pagesJson?.map((item) => item as String).toList(growable: false),
      chapters: chaptersJson
          ?.map((item) => item as Map<String, dynamic>)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text_id': textId,
      'title': title,
      'author': author,
      'ref_scheme': refScheme,
      'books': books?.map((book) => book.toJson()).toList(),
      'pages': pages,
      'chapters': chapters,
    };
  }
}

/// A text segment with its metadata.
class SegmentWithMeta {
  SegmentWithMeta({
    required this.ref,
    required this.text,
    required this.meta,
  });

  /// Reference (e.g., 'Il.1.1', 'Apol.17a')
  final String ref;

  /// Greek text content
  final String text;

  /// Metadata (e.g., {'book': 1, 'line': 1} or {'page': '17a'})
  final Map<String, dynamic> meta;

  factory SegmentWithMeta.fromJson(Map<String, dynamic> json) {
    return SegmentWithMeta(
      ref: json['ref'] as String? ?? '',
      text: json['text'] as String? ?? '',
      meta: json['meta'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ref': ref,
      'text': text,
      'meta': meta,
    };
  }
}

/// Token with morphological information.
class TokenInfo {
  TokenInfo({
    required this.text,
    this.lemma,
    this.morph,
  });

  final String text;
  final String? lemma;
  final String? morph;

  factory TokenInfo.fromJson(Map<String, dynamic> json) {
    return TokenInfo(
      text: json['text'] as String? ?? '',
      lemma: json['lemma'] as String?,
      morph: json['morph'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'lemma': lemma,
      'morph': morph,
    };
  }
}

/// Response from /reader/analyze endpoint.
class AnalyzeResponse {
  AnalyzeResponse({
    required this.tokens,
    required this.retrieval,
  });

  final List<TokenInfo> tokens;
  final List<dynamic> retrieval;

  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) {
    final rawTokens = json['tokens'] as List<dynamic>? ?? [];
    final tokens = rawTokens.map((t) => TokenInfo.fromJson(t as Map<String, dynamic>)).toList();
    return AnalyzeResponse(
      tokens: tokens,
      retrieval: json['retrieval'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tokens': tokens.map((t) => t.toJson()).toList(),
      'retrieval': retrieval,
    };
  }
}

/// Response for GET /reader/texts.
class TextListResponse {
  TextListResponse({required this.texts});

  /// List of available text works
  final List<TextWorkInfo> texts;

  factory TextListResponse.fromJson(Map<String, dynamic> json) {
    final textsJson = json['texts'] as List<dynamic>? ?? const <dynamic>[];
    return TextListResponse(
      texts: textsJson
          .map((item) => TextWorkInfo.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'texts': texts.map((text) => text.toJson()).toList(),
    };
  }
}

/// Response for GET /reader/texts/{id}/structure.
class TextStructureResponse {
  TextStructureResponse({required this.structure});

  /// Structural metadata for the text
  final TextStructure structure;

  factory TextStructureResponse.fromJson(Map<String, dynamic> json) {
    return TextStructureResponse(
      structure: TextStructure.fromJson(
        json['structure'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'structure': structure.toJson(),
    };
  }
}

/// Response for GET /reader/texts/{id}/segments.
class TextSegmentsResponse {
  TextSegmentsResponse({
    required this.segments,
    required this.textInfo,
  });

  /// List of text segments in the range
  final List<SegmentWithMeta> segments;

  /// Metadata about the text (author, title, license)
  final Map<String, dynamic> textInfo;

  factory TextSegmentsResponse.fromJson(Map<String, dynamic> json) {
    final segmentsJson = json['segments'] as List<dynamic>? ?? const <dynamic>[];
    return TextSegmentsResponse(
      segments: segmentsJson
          .map((item) => SegmentWithMeta.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      textInfo: json['text_info'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'segments': segments.map((segment) => segment.toJson()).toList(),
      'text_info': textInfo,
    };
  }
}
