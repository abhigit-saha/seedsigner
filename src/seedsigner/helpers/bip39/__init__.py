from seedsigner.models.settings_definition import SettingsConstants

def get_bip39_wordlist(wordlist_language_code: str) -> list:
    """
    Returns the wordlist for the specified language code.
    """
    match wordlist_language_code:
        case SettingsConstants.WORDLIST_LANGUAGE__EN:
            from .english_list import WORDLIST__ENGLISH
            return WORDLIST__ENGLISH
        case SettingsConstants.WORDLIST_LANGUAGE__ES:
            from .spanish_list import WORDLIST__SPANISH
            return WORDLIST__SPANISH
        case SettingsConstants.WORDLIST_LANGUAGE__FR:
            from .french_list import WORDLIST__FRENCH
            return WORDLIST__FRENCH
        case SettingsConstants.WORDLIST_LANGUAGE__IT:
            from .italian_list import WORDLIST__ITALIAN
            return WORDLIST__ITALIAN
        case SettingsConstants.WORDLIST_LANGUAGE__PT:
            from .portuguese_list import WORDLIST__PORTUGUESE
            return WORDLIST__PORTUGUESE
        case _:
            raise ValueError(f"Unsupported language code: {wordlist_language_code}")
