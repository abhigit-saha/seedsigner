from seedsigner.models.settings_definition import SettingsConstants

def get_bip39_wordlist(wordlist_language_code: str) -> list:
    """
    Returns the wordlist for the specified language code.
    """
    match wordlist_language_code:
        case SettingsConstants.WORDLIST_LANGUAGE__EN:
            from .wordlists.english_list import WORDLIST__ENGLISH
            return WORDLIST__ENGLISH
        case SettingsConstants.WORDLIST_LANGUAGE__ES:
            from .wordlists.spanish_list import WORDLIST__SPANISH
            return WORDLIST__SPANISH
        case SettingsConstants.WORDLIST_LANGUAGE__FR:
            from .wordlists.french_list import WORDLIST__FRENCH
            return WORDLIST__FRENCH
        case SettingsConstants.WORDLIST_LANGUAGE__IT:
            from .wordlists.italian_list import WORDLIST__ITALIAN
            return WORDLIST__ITALIAN
        case SettingsConstants.WORDLIST_LANGUAGE__PT:
            from .wordlists.portuguese_list import WORDLIST__PORTUGUESE
            return WORDLIST__PORTUGUESE
        case _:
            raise ValueError(f"Unsupported language code: {wordlist_language_code}")

def get_possible_alphabet(wordlist_language_code: str) -> list: 
    if wordlist_language_code in [SettingsConstants.WORDLIST_LANGUAGE__EN, SettingsConstants.WORDLIST_LANGUAGE__ES, SettingsConstants.WORDLIST_LANGUAGE__FR, SettingsConstants.WORDLIST_LANGUAGE__IT, SettingsConstants.WORDLIST_LANGUAGE__PT]:
        return "abcdefghijklmnopqrstuvwxyz"
    else: 
        raise ValueError(f"Unsupported language code: {wordlist_language_code}")
    
