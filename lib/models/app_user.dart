class AppUser {
  int? id;
  String name;
  String surname;
  String middleName;
  String birthday;
  String username;
  String password;
  String email;
  String phone;
  String accountNumber;         // Savings account number
  String checkingAccountNumber; // Checking account number
  String accountType;
  String accountStatus;
  double savingsBalance;
  double checkingBalance;

  AppUser({
    this.id,
    required this.name,
    required this.surname,
    this.middleName = '',
    this.birthday = '',
    required this.username,
    required this.password,
    this.email = '',
    this.phone = '',
    required this.accountNumber,
    this.checkingAccountNumber = '',
    this.accountType = 'savings',
    this.accountStatus = 'active',
    this.savingsBalance = 0.0,
    this.checkingBalance = 0.0,
  });

  double get totalBalance => savingsBalance + checkingBalance;

  String get initials {
    final first = name.isNotEmpty ? name[0].toUpperCase() : '';
    final last = surname.isNotEmpty ? surname[0].toUpperCase() : '';
    return '$first$last';
  }

  String get fullName => '$name $surname';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'surname': surname,
        'middleName': middleName,
        'birthday': birthday,
        'username': username,
        'password': password,
        'email': email,
        'phone': phone,
        'accountNumber': accountNumber,
        'checkingAccountNumber': checkingAccountNumber,
        'accountType': accountType,
        'accountStatus': accountStatus,
        'savingsBalance': savingsBalance,
        'checkingBalance': checkingBalance,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        name: json['name'] ?? '',
        surname: json['surname'] ?? '',
        middleName: json['middleName'] ?? '',
        birthday: json['birthday'] ?? '',
        username: json['username'] ?? '',
        password: json['password'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        accountNumber: json['accountNumber'] ?? '',
        checkingAccountNumber: json['checkingAccountNumber'] ?? '',
        accountType: json['accountType'] ?? 'savings',
        accountStatus: json['accountStatus'] ?? 'active',
        savingsBalance: (json['savingsBalance'] ?? 0.0).toDouble(),
        checkingBalance: (json['checkingBalance'] ?? 0.0).toDouble(),
      );
}
