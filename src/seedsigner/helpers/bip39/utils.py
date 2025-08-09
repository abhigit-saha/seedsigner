import os
import ast
from seedsigner.models.settings_definition import SettingsConstants

def _load_wordlist_from_file(language_code: str) -> list:
    """
    Load wordlist from file system path in seedsigner-translations submodule.
    """
    # Get the path to the wordlist file based on the language code.
    current_dir = os.path.dirname(os.path.abspath(__file__))
    translations_dir = os.path.join(current_dir, '..', '..', 'resources', 'seedsigner-translations')
    wordlist_file = os.path.join(translations_dir, 'l10n', language_code, 'wordlist', f'{_get_language_name(language_code)}_list.py')
    
    if not os.path.exists(wordlist_file):
        raise FileNotFoundError(f"Wordlist file not found: {wordlist_file}")
    
    # Read and parse the Python file to extract the wordlist
    with open(wordlist_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Parse the file to extract the wordlist variable
    tree = ast.parse(content)
    for node in tree.body:
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id.startswith('WORDLIST__'):
                    # Evaluate the list literal
                    if isinstance(node.value, ast.List):
                        wordlist = [ast.literal_eval(elt) for elt in node.value.elts]
                        return wordlist
    
    raise ValueError(f"Could not find wordlist in file: {wordlist_file}")

def _get_language_name(language_code: str) -> str:
    """
    Get the language name for file naming.
    """
    language_map = {
        SettingsConstants.WORDLIST_LANGUAGE__ES: 'spanish',
        SettingsConstants.WORDLIST_LANGUAGE__FR: 'french', 
        SettingsConstants.WORDLIST_LANGUAGE__IT: 'italian',
        SettingsConstants.WORDLIST_LANGUAGE__PT: 'portuguese'
    }
    return language_map.get(language_code, language_code)

def get_bip39_wordlist(wordlist_language_code: str) -> list:
    """
    Returns the wordlist for the specified language code.
    """
    match wordlist_language_code:
        case SettingsConstants.WORDLIST_LANGUAGE__EN:
            from embit.wordlists.bip39 import WORDLIST as WORDLIST__ENGLISH
            if len(WORDLIST__ENGLISH) != 2048 or WORDLIST__ENGLISH[0] != "abandon":
                raise ValueError("English wordlist is not loaded correctly.")
            return WORDLIST__ENGLISH
        case SettingsConstants.WORDLIST_LANGUAGE__ES | SettingsConstants.WORDLIST_LANGUAGE__FR | SettingsConstants.WORDLIST_LANGUAGE__IT | SettingsConstants.WORDLIST_LANGUAGE__PT:
            return _load_wordlist_from_file(wordlist_language_code)
        case _:
            raise ValueError(f"Unsupported language code: {wordlist_language_code}")

def get_possible_alphabet(wordlist_language_code: str) -> str: 
    if wordlist_language_code in [SettingsConstants.WORDLIST_LANGUAGE__EN, SettingsConstants.WORDLIST_LANGUAGE__ES, SettingsConstants.WORDLIST_LANGUAGE__FR, SettingsConstants.WORDLIST_LANGUAGE__IT, SettingsConstants.WORDLIST_LANGUAGE__PT]:
        return "abcdefghijklmnopqrstuvwxyz"
    else: 
        raise ValueError(f"Unsupported language code: {wordlist_language_code}")
    
