import 'package:coretingcar/data/api/api_client.dart';
import 'package:coretingcar/data/api/api_exception.dart';
import 'package:coretingcar/data/api/token_store.dart';
import 'package:coretingcar/data/models/models.dart';
import 'package:coretingcar/data/services/auth_service.dart';
import 'package:coretingcar/data/services/car_status_service.dart';
import 'package:coretingcar/data/services/expenses_service.dart';
import 'package:coretingcar/data/services/priority_service.dart';
import 'package:coretingcar/data/services/request_service.dart';
import 'package:coretingcar/data/services/rules_service.dart';
import 'package:coretingcar/data/services/usage_service.dart';

const user1 = User(id: 1, name: 'Andy', profile: 'user1', color: '#9CC93B');
const user2 = User(id: 2, name: 'Dennis', profile: 'user2', color: '#FF8A3D');

/// `TokenStore` en memoria para tests (no toca `flutter_secure_storage`).
class FakeTokenStore extends TokenStore {
  FakeTokenStore({String? token, User? user}) : _token = token, _user = user;

  String? _token;
  User? _user;
  String? _profile;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<String?> readProfile() async => _profile;

  @override
  Future<void> saveProfile(String profile) async => _profile = profile;

  @override
  Future<void> saveUser(User user) async => _user = user;

  @override
  Future<User?> readUser() async => _user;

  @override
  Future<void> saveSession({required String token, required User user}) async {
    _token = token;
    _user = user;
    _profile = user.profile;
  }

  @override
  Future<void> clear() async {
    _token = null;
    _user = null;
    _profile = null;
  }
}

/// `AuthService` controlable para tests (sin red).
class FakeAuthService extends AuthService {
  FakeAuthService({
    this.usersList = const [user1, user2],
    this.meUser,
    this.meError,
    this.loginError,
  }) : super(ApiClient(tokenReader: () async => null));

  final List<User> usersList;
  final User? meUser;
  final ApiException? meError;
  final ApiException? loginError;

  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Future<List<User>> users() async => usersList;

  @override
  Future<User> me() async {
    if (meError != null) throw meError!;
    if (meUser != null) return meUser!;
    throw const ApiException(
      'UNAUTHORIZED',
      'Sesión caducada',
      statusCode: 401,
    );
  }

  @override
  Future<LoginResult> login(String profile, String pin) async {
    loginCalls++;
    if (loginError != null) throw loginError!;
    final user = usersList.firstWhere(
      (u) => u.profile == profile,
      orElse: () => User(id: 99, name: profile, profile: profile),
    );
    return (token: 'token-$profile', user: user);
  }

  @override
  Future<void> logout() async => logoutCalls++;
}

/// `PriorityService` controlable para tests (sin red).
class FakePriorityService extends PriorityService {
  FakePriorityService({
    this.todayResult,
    this.todayError,
    this.calendarResult,
    this.calendarError,
  }) : super(ApiClient(tokenReader: () async => null));

  final DailyPriority? todayResult;
  final ApiException? todayError;
  final List<CalendarDay>? calendarResult;
  final ApiException? calendarError;

  int todayCalls = 0;
  int calendarCalls = 0;

  @override
  Future<DailyPriority> today() async {
    // Yield una vez para imitar una llamada de red real (sin esta pausa, un
    // error síncrono dejaría al AsyncNotifier en `AsyncLoading`, no `AsyncError`).
    await Future<void>.delayed(Duration.zero);
    todayCalls++;
    if (todayError != null) throw todayError!;
    return todayResult!;
  }

  @override
  Future<List<CalendarDay>> calendar(String month) async {
    await Future<void>.delayed(Duration.zero);
    calendarCalls++;
    if (calendarError != null) throw calendarError!;
    if (calendarResult != null) return calendarResult!;
    // Genera el mes alternando user1/user2, con una cesión el día 15.
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final days = DateTime(year, m + 1, 0).day;
    return [
      for (var d = 1; d <= days; d++)
        CalendarDay(
          date: '$month-${d.toString().padLeft(2, '0')}',
          priorityUser: d.isOdd ? user1 : user2,
          isHandover: d == 15,
          origin: d == 15 ? 'request_accepted' : null,
        ),
    ];
  }
}

/// `UsageService` controlable para tests (sin red).
class FakeUsageService extends UsageService {
  FakeUsageService({
    this.mileageResult,
    this.mileageError,
    this.usageList = const [],
  }) : super(ApiClient(tokenReader: () async => null));

  final MileageSummary? mileageResult;
  final ApiException? mileageError;
  final List<UsageLog> usageList;

  int mileageCalls = 0;
  int createCalls = 0;

  @override
  Future<List<UsageLog>> list({int? userId, String? from, String? to}) async {
    await Future<void>.delayed(Duration.zero);
    return usageList;
  }

  @override
  Future<MileageSummary> mileage() async {
    await Future<void>.delayed(Duration.zero);
    mileageCalls++;
    if (mileageError != null) throw mileageError!;
    return mileageResult!;
  }

  @override
  Future<UsageLog> create({
    required String date,
    required int startKm,
    required int endKm,
    required EntryType type,
  }) async {
    await Future<void>.delayed(Duration.zero);
    createCalls++;
    return UsageLog(
      id: 1,
      userId: 1,
      date: date,
      startKm: startKm,
      endKm: endKm,
      totalKm: endKm - startKm,
      type: type,
    );
  }
}

/// `CarStatusService` controlable para tests (sin red). Empieza libre.
class FakeCarStatusService extends CarStatusService {
  FakeCarStatusService({CarStatus? status, this.setError})
    : _status = status ?? const CarStatus(availability: CarAvailability.free),
      super(ApiClient(tokenReader: () async => null));

  CarStatus _status;
  final ApiException? setError;

  int getCalls = 0;
  int setCalls = 0;
  CarAvailability? lastStatus;
  ParkingSpot? lastParking;
  String? lastNote;

  @override
  Future<CarStatus> getStatus() async {
    await Future<void>.delayed(Duration.zero);
    getCalls++;
    return _status;
  }

  @override
  Future<CarStatus> setStatus(
    CarAvailability availability, {
    ParkingSpot? parking,
    String? note,
  }) async {
    await Future<void>.delayed(Duration.zero);
    setCalls++;
    lastStatus = availability;
    lastParking = parking;
    lastNote = note;
    if (setError != null) throw setError!;
    _status = CarStatus(
      availability: availability,
      user: availability == CarAvailability.taken ? user1 : null,
      parking: parking,
      parkingUser: switch (parking) {
        ParkingSpot.user1 => user1,
        ParkingSpot.user2 => user2,
        _ => null, // 'other' o null → sin usuario (la ubicación va en la nota)
      },
      note: note,
      since: DateTime(2026, 6, 4, 14, 30),
    );
    return _status;
  }
}

/// `ExpensesService` controlable para tests (sin red).
class FakeExpensesService extends ExpensesService {
  FakeExpensesService({this.summaryResult, this.summaryError})
    : super(ApiClient(tokenReader: () async => null));

  final ExpensesSummary? summaryResult;
  final ApiException? summaryError;

  int fuelCalls = 0;
  int washCalls = 0;

  @override
  Future<ExpensesSummary> summary() async {
    await Future<void>.delayed(Duration.zero);
    if (summaryError != null) throw summaryError!;
    return summaryResult!;
  }

  @override
  Future<FuelLog> addFuel({
    required String date,
    required double amountEur,
    required EntryType type,
  }) async {
    await Future<void>.delayed(Duration.zero);
    fuelCalls++;
    return FuelLog(
      id: 1,
      userId: 1,
      date: date,
      amountEur: amountEur,
      type: type,
    );
  }

  @override
  Future<WashLog> addWash({required String date, double? costEur}) async {
    await Future<void>.delayed(Duration.zero);
    washCalls++;
    return WashLog(id: 1, userId: 1, date: date, costEur: costEur);
  }
}

/// `RulesService` controlable para tests (sin red).
class FakeRulesService extends RulesService {
  FakeRulesService({this.result, this.error})
    : super(ApiClient(tokenReader: () async => null));

  final Rules? result;
  final ApiException? error;

  @override
  Future<Rules> getRules() async {
    await Future<void>.delayed(Duration.zero);
    if (error != null) throw error!;
    return result!;
  }
}

/// Reglas de muestra (los valores del contrato).
Rules rulesSample() => const Rules(
  monthlyFeeEur: 355.0,
  feeSplitPct: 50.0,
  feePerPerson: 177.5,
  annualKmTotal: 16000,
  annualKmPerPerson: 8000,
  kmWindow: 'natural',
  sharedKmRounding: 1,
  anchorDate: '2026-01-01',
  anchorUserId: 1,
  firstWashUserId: 2,
  timezone: 'Europe/Madrid',
);

/// `RequestService` controlable para tests (sin red).
class FakeRequestService extends RequestService {
  FakeRequestService({
    this.listResult = const [],
    this.pendingResult = const [],
  }) : super(ApiClient(tokenReader: () async => null));

  List<UseRequest> listResult;
  List<UseRequest> pendingResult;

  int acceptCalls = 0;
  int rejectCalls = 0;
  int cancelCalls = 0;
  int createCalls = 0;

  @override
  Future<List<UseRequest>> list({RequestStatus? status}) async {
    await Future<void>.delayed(Duration.zero);
    return listResult;
  }

  @override
  Future<List<UseRequest>> pending() async {
    await Future<void>.delayed(Duration.zero);
    return pendingResult;
  }

  @override
  Future<UseRequest> accept(int id) async {
    await Future<void>.delayed(Duration.zero);
    acceptCalls++;
    return _resolved(id, RequestStatus.accepted);
  }

  @override
  Future<UseRequest> reject(int id) async {
    await Future<void>.delayed(Duration.zero);
    rejectCalls++;
    return _resolved(id, RequestStatus.rejected);
  }

  @override
  Future<UseRequest> cancel(int id) async {
    await Future<void>.delayed(Duration.zero);
    cancelCalls++;
    return _resolved(id, RequestStatus.cancelled);
  }

  @override
  Future<UseRequest> create({required String useDate, String? message}) async {
    await Future<void>.delayed(Duration.zero);
    createCalls++;
    return UseRequest(
      id: 99,
      requesterId: 1,
      recipientId: 2,
      useDate: useDate,
      status: RequestStatus.pending,
      message: message,
    );
  }

  UseRequest _resolved(int id, RequestStatus status) => UseRequest(
    id: id,
    requesterId: 2,
    recipientId: 1,
    useDate: '2026-06-10',
    status: status,
  );
}

/// Solicitudes de muestra para `user1` (id 1): 1 recibida pendiente (de Dennis),
/// 1 enviada pendiente (a Dennis) y 1 aceptada en el historial.
List<UseRequest> requestsSample() => const [
  // Recibida por Andy (la pide Dennis).
  UseRequest(
    id: 1,
    requesterId: 2,
    recipientId: 1,
    useDate: '2026-06-10',
    status: RequestStatus.pending,
    message: '¿Me lo dejas?',
    requester: user2,
    recipient: user1,
  ),
  // Enviada por Andy.
  UseRequest(
    id: 2,
    requesterId: 1,
    recipientId: 2,
    useDate: '2026-06-12',
    status: RequestStatus.pending,
    requester: user1,
    recipient: user2,
  ),
  // Historial (aceptada).
  UseRequest(
    id: 3,
    requesterId: 1,
    recipientId: 2,
    useDate: '2026-05-01',
    status: RequestStatus.accepted,
    requester: user1,
    recipient: user2,
  ),
];

/// Resumen de gastos de muestra: saldo y un repostaje compartido + un lavado.
ExpensesSummary expensesSample() => const ExpensesSummary(
  fuel: FuelSection(
    list: [
      FuelEntry(
        log: FuelLog(
          id: 1,
          userId: 2,
          date: '2026-06-01',
          amountEur: 25.0,
          type: EntryType.shared,
        ),
        user: user2,
      ),
    ],
    totalPerUser: [
      FuelTotal(user: user1, totalEur: 0),
      FuelTotal(user: user2, totalEur: 25.0),
    ],
    balance: FuelBalance(
      settled: false,
      amountEur: 12.5,
      fromUser: user1,
      toUser: user2,
    ),
  ),
  wash: WashSection(
    last: WashEntry(
      log: WashLog(id: 9, userId: 1, date: '2026-05-20', costEur: 15.0),
      user: user1,
    ),
    nextWashUser: user2,
    history: [
      WashEntry(
        log: WashLog(id: 9, userId: 1, date: '2026-05-20', costEur: 15.0),
        user: user1,
      ),
    ],
  ),
);

/// Resumen de km de muestra: Andy dentro de cupo, Dennis con exceso.
MileageSummary mileageSample() => const MileageSummary(
  people: [
    PersonMileage(
      user: user1,
      individualKm: 6240,
      usedKm: 6240,
      remainingKm: 1760,
      exceeded: false,
      excessKm: 0,
    ),
    PersonMileage(
      user: user2,
      individualKm: 8430,
      usedKm: 8430,
      remainingKm: 0,
      exceeded: true,
      excessKm: 430,
    ),
  ],
  annualKmTotal: 16000,
  annualKmPerPerson: 8000,
  sharedKm: 120.5,
  sharedKmPerPerson: 60.25,
);

/// Construye una prioridad de prueba para `priorityUser`.
DailyPriority priorityFor(
  User user, {
  String date = '2026-06-04',
  bool isMyDay = false,
  String? conflictPhrase,
}) => DailyPriority(
  date: date,
  priorityUser: user,
  isMyDay: isMyDay,
  conflictPhrase: conflictPhrase,
);
