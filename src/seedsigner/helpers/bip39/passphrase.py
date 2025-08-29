from gettext import gettext as _ 

from seedsigner.models.settings import SettingsConstants
from .constants import FULL_CHARSETS   

def get_accented_passphrase_charset(locale: str): 
    """
    Returns an array of two strings containing accented/non-roman characters based upon the locale specified
    one in lower case and the other in upper case.
    """  
    if locale not in FULL_CHARSETS:    
        return []
    return FULL_CHARSETS[locale]