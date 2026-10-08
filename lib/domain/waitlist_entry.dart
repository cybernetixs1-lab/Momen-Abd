class WaitlistEntry {
  const WaitlistEntry({
    required this.ticketNumber,
    required this.name,
    required this.partySize,
  });

  final int ticketNumber;
  final String name;
  final int partySize;

  int partiesAheadOf(int index) => index;

  Map<String, Object> toJson() => {
        'ticketNumber': ticketNumber,
        'name': name,
        'partySize': partySize,
      };

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) {
    final ticketNumber = json['ticketNumber'];
    final name = json['name'];
    final partySize = json['partySize'];

    if (ticketNumber is! int || name is! String || partySize is! int) {
      throw const FormatException('Invalid waitlist entry.');
    }

    return WaitlistEntry(
      ticketNumber: ticketNumber,
      name: name,
      partySize: partySize,
    );
  }
}
