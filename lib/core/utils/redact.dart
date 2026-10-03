/// Removes email addresses and phone-like numbers from text before it is
/// logged or sent to an error reporter, so a failure message cannot carry a
/// user's contact details out of the app.
String redactPersonalData(String input) {
  final withoutEmails = input.replaceAll(
    RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+'),
    '[email]',
  );
  return withoutEmails.replaceAll(RegExp(r'\+?\d[\d\s-]{7,}\d'), '[phone]');
}
