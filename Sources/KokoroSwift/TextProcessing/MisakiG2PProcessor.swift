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
/// uses its OpenJTalk-backed `OpenJTalkG2P` (or the pure-Apple `JapaneseG2P`
/// fallback). The active engine is chosen by `setLanguage(_:)`.
///
/// Engines are **built once and cached**, and `setLanguage(_:)` just switches which
/// one is active — so alternating languages within a single (code-switched)
/// utterance no longer rebuilds them. This matters most for Japanese: building
/// `OpenJTalkG2P` loads a MeCab dictionary, which previously happened on *every*
/// `.ja` selection; it's now loaded once and reused across switches.
final class MisakiG2PProcessor : G2PProcessor {
  /// US / GB English engines, built lazily on first selection and then cached.
  private var englishUS: EnglishG2P?
  private var englishGB: EnglishG2P?
  /// The Japanese engine — `OpenJTalkG2P` when its dictionary is present, else the
  /// cheap pure-Apple `JapaneseG2P` fallback. Once the (expensive) OpenJTalk engine
  /// is built it's kept; while only the fallback is built it's re-resolved on each
  /// `.ja` selection so it can upgrade to OpenJTalk once the dictionary downloads.
  private var japanese: JapanesePhonemizer?
  /// The language selected by `setLanguage(_:)` — the dispatch key for `process`.
  private var active: Language?

  /// Configures the processor for the specified language.
  /// - Parameter language: The target language for phonemization. `.enUS`, `.enGB` and `.ja` are supported.
  /// - Throws: `G2PProcessorError.unsupportedLanguage` if the language is not supported.
  func setLanguage(_ language: Language) throws {
    switch language {
    case .enUS:
      if englishUS == nil { englishUS = EnglishG2P(british: false) }
    case .enGB:
      if englishGB == nil { englishGB = EnglishG2P(british: true) }
    case .ja:
      // Reuse a built OpenJTalk engine; otherwise (nil, or only the cheap fallback)
      // re-resolve so it upgrades to OpenJTalk once the dictionary is configured.
      if !(japanese is OpenJTalkG2P) { japanese = makeJapanesePhonemizer() }
    default:
      throw G2PProcessorError.unsupportedLanguage
    }
    active = language
  }

  /// Converts input text to phonetic representation using the active engine.
  /// - Parameter input: The text string to be converted to phonemes.
  /// - Returns: A phonetic string representation of the input text and arrays of tokens.
  /// - Throws: `G2PProcessorError.processorNotInitialized` if `setLanguage(_:)` has not been called.
  func process(input: String) throws -> (String, [MToken]?) {
    switch active {
    case .enUS:
      guard let englishUS else { throw G2PProcessorError.processorNotInitialized }
      return englishUS.phonemize(text: input)
    case .enGB:
      guard let englishGB else { throw G2PProcessorError.processorNotInitialized }
      return englishGB.phonemize(text: input)
    case .ja:
      guard let japanese else { throw G2PProcessorError.processorNotInitialized }
      return japanese.phonemize(text: input)
    default:
      throw G2PProcessorError.processorNotInitialized
    }
  }
}

#endif
