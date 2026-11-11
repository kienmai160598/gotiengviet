//! English grammar checking for VietKey, backed by Harper and exposed to Swift through UniFFI.

use harper_core::linting::{Lint, LintGroup, LintKind, Linter, Suggestion};
use harper_core::spell::FstDictionary;
use harper_core::{Dialect, Document, Span, remove_overlaps};
use std::sync::Mutex;

uniffi::setup_scaffolding!();

/// One problem in the checked text. Offsets are UTF-16 code units, matching NSRange.
#[derive(Debug, uniffi::Record)]
pub struct GrammarIssue {
    pub location: u32,
    pub length: u32,
    pub message: String,
    /// Replacements for the whole issue range, best first. Empty when Harper has no fix.
    pub replacements: Vec<String>,
    /// Short category for the UI, e.g. "Agreement" or "Word choice".
    pub category: String,
}

#[derive(Debug, thiserror::Error, uniffi::Error)]
pub enum GrammarError {
    #[error("an earlier check panicked, the linter state is no longer trusted")]
    LinterPoisoned,
}

#[derive(uniffi::Object)]
pub struct GrammarChecker {
    linter: Mutex<LintGroup>,
}

#[uniffi::export]
#[allow(
    clippy::new_without_default,
    reason = "loading takes hundreds of ms, so no implicit Default"
)]
impl GrammarChecker {
    /// Loads Harper's curated rules and dictionary, which takes a few hundred milliseconds,
    /// so callers create one checker off the main thread and reuse it.
    #[uniffi::constructor]
    pub fn new() -> Self {
        let mut linter = LintGroup::new_curated(FstDictionary::curated(), Dialect::American);
        for rule in OFF_RULES {
            linter.config.set_rule_enabled(*rule, false);
        }
        Self {
            linter: Mutex::new(linter),
        }
    }

    pub fn check(&self, text: String) -> Result<Vec<GrammarIssue>, GrammarError> {
        let mut linter = self
            .linter
            .lock()
            .map_err(|_| GrammarError::LinterPoisoned)?;
        let chars: Vec<char> = text.chars().collect();
        let mut lints = linter.lint(&Document::new_plain_english_curated_chars(&chars));
        lints.retain(is_error);
        remove_overlaps(&mut lints);
        lints.sort_by_key(|lint| lint.span.start);
        let offsets = Utf16Offsets::new(&chars);
        Ok(lints
            .into_iter()
            .map(|lint| GrammarIssue {
                location: offsets.at(lint.span.start),
                length: offsets.at(lint.span.end) - offsets.at(lint.span.start),
                replacements: lint
                    .suggestions
                    .iter()
                    .map(|s| replacement(s, lint.span, &chars))
                    .collect(),
                category: category(lint.lint_kind).to_string(),
                message: lint.message,
            })
            .collect())
    }
}

/// Rules that judge words missing from Harper's dictionary. VietKey's own word tables cover
/// spelling, and these flag every Vietnamese word and tech term ("deps" -> "imps").
const OFF_RULES: &[&str] = &["SpellCheck", "WrongNegative"];

/// Keeps mistakes and drops preferences, which are noise while typing chat or code comments.
/// Capitalization is dropped too: chat is often lowercase ("ok", "i think so").
fn is_error(lint: &Lint) -> bool {
    !matches!(
        lint.lint_kind,
        LintKind::Capitalization
            | LintKind::Style
            | LintKind::Enhancement
            | LintKind::Readability
            | LintKind::Regionalism
            | LintKind::Formatting
    )
}

fn category(kind: LintKind) -> &'static str {
    match kind {
        LintKind::Agreement => "Agreement",
        LintKind::BoundaryError => "Word boundary",
        LintKind::Eggcorn | LintKind::Malapropism | LintKind::WordChoice => "Word choice",
        LintKind::Punctuation => "Punctuation",
        LintKind::Redundancy => "Redundancy",
        LintKind::Repetition => "Repetition",
        LintKind::Typo => "Typo",
        LintKind::Usage | LintKind::Nonstandard => "Usage",
        LintKind::WordOrder => "Word order",
        _ => "Grammar",
    }
}

/// Every Harper suggestion as the text that should replace the issue range.
fn replacement(suggestion: &Suggestion, span: Span<char>, chars: &[char]) -> String {
    match suggestion {
        Suggestion::ReplaceWith(with) => with.iter().collect(),
        Suggestion::InsertAfter(inserted) => {
            span.get_content(chars).iter().chain(inserted).collect()
        }
        Suggestion::Remove => String::new(),
    }
}

/// Maps Harper's char (Unicode scalar) offsets to UTF-16 offsets.
struct Utf16Offsets(Vec<u32>);

impl Utf16Offsets {
    fn new(chars: &[char]) -> Self {
        let mut offsets = Vec::with_capacity(chars.len() + 1);
        let mut total = 0u32;
        offsets.push(total);
        for char in chars {
            total += char.len_utf16() as u32;
            offsets.push(total);
        }
        Self(offsets)
    }

    fn at(&self, char_index: usize) -> u32 {
        self.0[char_index]
    }
}
