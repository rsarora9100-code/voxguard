class ContactsService {
  // In-memory trusted contact cache
  static final Map<String, String> _whitelistCache = {
    '+14155552671': 'Sarah Miller (Mom)',
    '+14155559823': 'Dr. Robert Chen',
    '+14155554321': 'Acme Corp Office Desk',
  };

  /// Check if a phone number exists in local contacts
  static bool isKnownContact(String phoneNumber) {
    final clean = normalizeNumber(phoneNumber);
    return _whitelistCache.containsKey(clean);
  }

  /// Get contact name
  static String? getContactName(String phoneNumber) {
    final clean = normalizeNumber(phoneNumber);
    return _whitelistCache[clean];
  }

  /// Add a contact to local cache
  static void addContact(String phoneNumber, String name) {
    _whitelistCache[normalizeNumber(phoneNumber)] = name;
  }

  static String normalizeNumber(String number) {
    return number.replaceAll(' ', '').replaceAll('-', '').replaceAll('(', '').replaceAll(')', '');
  }
}
