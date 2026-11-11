extension Syllable {
    /// Nuclei that may or may not take a final consonant.
    private static let openNuclei: Set<String> = [
        "a", "e", "ê", "i", "o", "ô", "ơ", "u", "ư", "y", "oa", "oe", "uê", "uy",
    ]
    /// Nuclei that require a final consonant.
    private static let closedNuclei: Set<String> = [
        "ă", "â", "iê", "yê", "uô", "ươ", "oă", "uâ", "uyê", "oo",
    ]
    /// Nuclei ending in a glide, which never take a final consonant.
    private static let glideNuclei: Set<String> = [
        "ai", "ao", "au", "ay", "âu", "ây", "eo", "êu", "ia", "iu", "oi", "ôi", "ơi", "ui", "ưi",
        "ưu", "ua", "ưa", "uơ", "oai", "oay", "oeo", "uây", "uôi", "ươi", "ươu", "iêu", "yêu",
        "uya", "uyu",
    ]
    static let allNuclei = openNuclei.union(closedNuclei).union(glideNuclei)

    private static let stopFinals: Set<String> = ["c", "ch", "p", "t"]
    private static let frontVowels: Set<Character> = ["e", "ê", "i", "y"]

    func isValid(with tone: Tone) -> Bool {
        hasValidRhyme && hasValidSpelling && (!Self.stopFinals.contains(final) || tone.fitsStopFinal)
    }

    private var hasValidRhyme: Bool {
        if Self.openNuclei.contains(nucleus) { return finalFitsNucleus }
        if Self.closedNuclei.contains(nucleus) { return !final.isEmpty && finalFitsNucleus }
        return Self.glideNuclei.contains(nucleus) && final.isEmpty
    }

    private var finalFitsNucleus: Bool {
        guard let last = nucleus.last else { return false }
        switch final {
        case "ch", "nh": return ["a", "ê", "i", "y"].contains(last)
        case "c", "ng": return last != "i" && last != "y"
        default: return true
        }
    }

    /// Orthographic rules: k/gh/ngh before front vowels, c/g/ng elsewhere, iê vs yê.
    private var hasValidSpelling: Bool {
        guard let first = nucleus.first else { return false }
        let isFront = Self.frontVowels.contains(first)
        switch initial {
        case "k", "gh", "ngh": guard isFront else { return false }
        case "c", "ng": guard !isFront else { return false }
        case "g": guard !isFront || first == "i" else { return false }
        default: break
        }
        if nucleus.hasPrefix("yê") { return initial.isEmpty || initial == "qu" }
        if nucleus.hasPrefix("iê") { return !initial.isEmpty }
        return true
    }
}
