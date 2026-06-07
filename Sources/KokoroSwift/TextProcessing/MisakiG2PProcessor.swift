//
//  Kokoro-tts-lib
//
#if canImport(MisakiSwift)

import Foundation
import MisakiSwift
import MLXUtilsLibrary

/// A G2P processor that uses the MisakiSwift library for phonemization.
/// Requires the MisakiSwift framework to be available at compile time.
///
/// English (`.enUS` / `.enGB`) uses MisakiSwift's `EnglishG2P`; Japanese (`.ja`)
/// uses its `JapaneseG2P`. Exactly one engine is active at a time, selected by
/// `setLanguage(_:)`.
final class MisakiG2PProcessor : G2PProcessor {
  /// The MisakiSwift English G2P engine, set when an English language is selected.
  var misaki: EnglishG2P?
  /// The MisakiSwift Japanese G2P engine, set when `.ja` is selected. Resolved by
  /// `makeJapanesePhonemizer()` to OpenJTalk when its dictionary is available, else
  /// the pure-Apple `JapaneseG2P` fallback.
  var japanese: JapanesePhonemizer?

  /// Configures the processor for the specified language.
  /// - Parameter language: The target language for phonemization. `.enUS`, `.enGB` and `.ja` are supported.
  /// - Throws: `G2PProcessorError.unsupportedLanguage` if the language is not supported.
  func setLanguage(_ language: Language) throws {
    misaki = nil
    japanese = nil
    switch language {
    case .enUS:
      misaki = EnglishG2P(british: false)
    case .enGB:
      misaki = EnglishG2P(british: true)
    case .ja:
      japanese = makeJapanesePhonemizer()
    default:
      throw G2PProcessorError.unsupportedLanguage
    }
  }

  /// Converts input text to phonetic representation.
  /// - Parameter input: The text string to be converted to phonemes.
  /// - Returns: A phonetic string representation of the input text and arrays of tokens.
  /// - Throws: `G2PProcessorError.processorNotInitialized` if `setLanguage(_:)` has not been called.
  func process(input: String) throws -> (String, [MToken]?) {
    if let japanese {
      return japanese.phonemize(text: input)
    }
    guard let misaki else { throw G2PProcessorError.processorNotInitialized }
    return misaki.phonemize(text: input)
  }
}

#endif
