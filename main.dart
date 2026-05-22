import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const TiboWeatherApp());
}

class TiboWeatherApp extends StatelessWidget {
  const TiboWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tibo Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'System',
        scaffoldBackgroundColor: const Color(0xFFE1EEF5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFEF3CF),
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFF2B5A78)),
          titleTextStyle: TextStyle(
            color: Color(0xFF2B5A78),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _philippineLocations = [];
  bool _isLoading = false;
  WeatherData? _currentWeather;
  ForecastData? _forecastData;
  String _currentLocationName = 'Philippines';
  String? _alertMessage;
  final String _apiKey = 'bd5e378503939ddaee76f12ad7a97608';

  // Province to capital mapping
  final Map<String, String> _provinceToCapital = {
    'Aklan': 'Kalibo', 'Antique': 'San Jose', 'Capiz': 'Roxas City',
    'Guimaras': 'Jordan', 'Iloilo': 'Iloilo City', 'Negros Occidental': 'Bacolod',
    'Negros Oriental': 'Dumaguete', 'Bohol': 'Tagbilaran', 'Siquijor': 'Siquijor',
    'Eastern Samar': 'Borongan', 'Northern Samar': 'Catarman', 'Samar (Western)': 'Catbalogan',
    'Leyte': 'Tacloban', 'Southern Leyte': 'Maasin', 'Biliran': 'Naval',
    'Zamboanga del Norte': 'Dipolog', 'Zamboanga del Sur': 'Pagadian',
    'Zamboanga Sibugay': 'Ipil', 'Bukidnon': 'Malaybalay', 'Camiguin': 'Mambajao',
    'Lanao del Norte': 'Iligan', 'Lanao del Sur': 'Marawi',
    'Misamis Occidental': 'Oroquieta', 'Misamis Oriental': 'Cagayan de Oro',
    'Davao del Norte': 'Tagum', 'Davao del Sur': 'Davao City',
    'Davao Occidental': 'Malita', 'Davao Oriental': 'Mati', 'Davao de Oro': 'Nabunturan',
    'Cotabato (North Cotabato)': 'Kidapawan', 'Sultan Kudarat': 'Isulan',
    'South Cotabato': 'Koronadal', 'Sarangani': 'Alabel', 'Agusan del Norte': 'Butuan',
    'Agusan del Sur': 'Prosperidad', 'Surigao del Norte': 'Surigao City',
    'Surigao del Sur': 'Tandag', 'Dinagat Islands': 'San Jose', 'Basilan': 'Lamitan',
    'Sulu': 'Jolo', 'Tawi-Tawi': 'Bongao', 'Maguindanao': 'Shariff Aguak',
    'Abra': 'Bangued', 'Apayao': 'Luna', 'Benguet': 'Baguio', 'Ifugao': 'Lagawe',
    'Kalinga': 'Tabuk', 'Mountain Province': 'Bontoc', 'Ilocos Norte': 'Laoag',
    'Ilocos Sur': 'Vigan', 'La Union': 'San Fernando', 'Pangasinan': 'Lingayen',
    'Cagayan': 'Tuguegarao', 'Isabela': 'Ilagan', 'Nueva Vizcaya': 'Bayombong',
    'Quirino': 'Cabarroguis', 'Batanes': 'Basco', 'Aurora': 'Baler', 'Bulacan': 'Malolos',
    'Pampanga': 'San Fernando', 'Tarlac': 'Tarlac City', 'Nueva Ecija': 'Palayan',
    'Zambales': 'Iba', 'Bataan': 'Balanga', 'Rizal': 'Antipolo', 'Laguna': 'Santa Cruz',
    'Batangas': 'Batangas City', 'Quezon Province': 'Lucena', 'Camarines Norte': 'Daet',
    'Camarines Sur': 'Naga', 'Albay': 'Legazpi', 'Sorsogon': 'Sorsogon City',
    'Masbate': 'Masbate City', 'Catanduanes': 'Virac', 'Marinduque': 'Boac',
    'Romblon': 'Romblon', 'Palawan': 'Puerto Princesa', 'Mindoro Occidental': 'Mamburao',
    'Mindoro Oriental': 'Calapan'
  };

  @override
  void initState() {
    super.initState();
    _loadPhilippineLocations();
    _loadWeatherByCity('Quezon City');
  }

  void _loadPhilippineLocations() {
    final locations = [
      'Manila', 'Quezon City', 'Caloocan', 'Las Piñas', 'Makati', 'Malabon',
      'Mandaluyong', 'Marikina', 'Muntinlupa', 'Navotas', 'Parañaque', 'Pasay',
      'Pasig', 'Pateros', 'San Juan', 'Taguig', 'Valenzuela', 'Abra', 'Bangued',
      'Apayao', 'Luna', 'Benguet', 'Baguio', 'La Trinidad', 'Ifugao', 'Lagawe',
      'Banaue', 'Kalinga', 'Tabuk', 'Mountain Province', 'Bontoc', 'Sagada',
      'Ilocos Norte', 'Laoag', 'Ilocos Sur', 'Vigan', 'Candon', 'La Union',
      'San Fernando', 'Pangasinan', 'Lingayen', 'Dagupan', 'Alaminos', 'Urdaneta',
      'Cagayan', 'Tuguegarao', 'Aparri', 'Isabela', 'Ilagan', 'Cauayan', 'Santiago',
      'Nueva Vizcaya', 'Bayombong', 'Quirino', 'Cabarroguis', 'Batanes', 'Basco',
      'Aurora', 'Baler', 'Bulacan', 'Malolos', 'Meycauayan', 'San Jose del Monte',
      'Baliwag', 'Pampanga', 'Angeles City', 'Mabalacat', 'Tarlac', 'Tarlac City',
      'Concepcion', 'Nueva Ecija', 'Palayan', 'Cabanatuan', 'Gapan',
      'Science City of Muñoz', 'Zambales', 'Iba', 'Olongapo', 'Bataan', 'Balanga',
      'Mariveles', 'Rizal', 'Antipolo', 'Cainta', 'Laguna', 'Santa Cruz', 'Calamba',
      'Biñan', 'San Pablo', 'Santa Rosa', 'Cabuyao', 'Batangas', 'Batangas City',
      'Lipa', 'Tanauan', 'Quezon Province', 'Lucena', 'Tayabas', 'Infanta',
      'Camarines Norte', 'Daet', 'Camarines Sur', 'Naga', 'Iriga', 'Legazpi',
      'Albay', 'Tabaco', 'Ligao', 'Sorsogon', 'Sorsogon City', 'Masbate',
      'Masbate City', 'Catanduanes', 'Virac', 'Marinduque', 'Boac', 'Romblon',
      'Palawan', 'Puerto Princesa', 'El Nido', 'Coron', 'Mindoro Occidental',
      'Mamburao', 'Mindoro Oriental', 'Calapan', 'Aklan', 'Kalibo', 'Boracay',
      'Antique', 'San Jose', 'Capiz', 'Roxas City', 'Iloilo', 'Iloilo City',
      'Passi', 'Guimaras', 'Jordan', 'Negros Occidental', 'Bacolod', 'Silay',
      'Kabankalan', 'Negros Oriental', 'Dumaguete', 'Bais', 'Cebu', 'Cebu City',
      'Mandaue', 'Lapu-Lapu', 'Toledo', 'Danao', 'Bohol', 'Tagbilaran', 'Siquijor',
      'Eastern Samar', 'Borongan', 'Northern Samar', 'Catarman',
      'Samar (Western)', 'Catbalogan', 'Calbayog', 'Leyte', 'Tacloban', 'Ormoc',
      'Baybay', 'Southern Leyte', 'Maasin', 'Biliran', 'Naval',
      'Zamboanga del Norte', 'Dipolog', 'Dapitan', 'Zamboanga del Sur', 'Pagadian',
      'Zamboanga City', 'Zamboanga Sibugay', 'Ipil', 'Bukidnon', 'Malaybalay',
      'Valencia', 'Camiguin', 'Mambajao', 'Lanao del Norte', 'Iligan', 'Tubod',
      'Lanao del Sur', 'Marawi', 'Misamis Occidental', 'Oroquieta', 'Ozamiz',
      'Misamis Oriental', 'Cagayan de Oro', 'Gingoog', 'Davao del Norte', 'Tagum',
      'Panabo', 'Davao del Sur', 'Davao City', 'Digos', 'Davao Occidental',
      'Malita', 'Davao Oriental', 'Mati', 'Davao de Oro', 'Nabunturan',
      'Cotabato (North Cotabato)', 'Kidapawan', 'Midsayap', 'Sultan Kudarat',
      'Isulan', 'Tacurong', 'South Cotabato', 'Koronadal', 'General Santos',
      'Sarangani', 'Alabel', 'Agusan del Norte', 'Butuan', 'Cabadbaran',
      'Agusan del Sur', 'Prosperidad', 'Bayugan', 'Surigao del Norte',
      'Surigao City', 'Siargao', 'Surigao del Sur', 'Tandag', 'Bislig',
      'Dinagat Islands', 'Basilan', 'Lamitan', 'Isabela City', 'Sulu', 'Jolo',
      'Tawi-Tawi', 'Bongao', 'Maguindanao', 'Shariff Aguak', 'Cotabato City'
    ];
    _philippineLocations.addAll(locations.toSet().toList()..sort());
  }

  String _getSearchableLocation(String input) {
    return _provinceToCapital[input] ?? input;
  }

  IconData _getWeatherIcon(int weatherId) {
    if (weatherId >= 200 && weatherId < 300) return Icons.flash_on;
    if (weatherId >= 300 && weatherId < 400) return Icons.grain;
    if (weatherId >= 500 && weatherId < 600) return Icons.beach_access;
    if (weatherId >= 600 && weatherId < 700) return Icons.ac_unit;
    if (weatherId == 800) return Icons.wb_sunny;
    if (weatherId == 801) return Icons.wb_cloudy;
    if (weatherId > 801 && weatherId < 805) return Icons.cloud;
    return Icons.wb_cloudy;
  }

  void _checkAlert(int weatherId, double windSpeed, String description) {
    String? msg;
    if (weatherId >= 200 && weatherId < 300) {
      msg = 'THUNDERSTORM: Lightning risk, stay safe!';
    } else if (weatherId >= 500 && weatherId < 600 && description.contains('heavy')) {
      msg = 'Heavy rain alert — possible flash floods.';
    } else if (windSpeed > 12) {
      msg = 'Strong winds ${windSpeed.toStringAsFixed(1)} m/s! Caution advised.';
    } else if (description.toLowerCase().contains('typhoon')) {
      msg = 'Typhoon alert: take precautions.';
    }
    setState(() {
      _alertMessage = msg;
    });
  }

  Future<void> _loadWeatherByCity(String cityName) async {
    setState(() {
      _isLoading = true;
      _alertMessage = null;
    });

    try {
      String searchCity = _getSearchableLocation(cityName.trim());
      String encoded = Uri.encodeComponent(searchCity);
      String url = 'https://api.openweathermap.org/data/2.5/weather?q=$encoded,PH&appid=$_apiKey&units=metric';
      
      var response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        url = 'https://api.openweathermap.org/data/2.5/weather?q=$encoded&appid=$_apiKey&units=metric';
        response = await http.get(Uri.parse(url));
      }
      
      if (response.statusCode != 200) {
        throw Exception('"$cityName" not found. Please use a valid PH city/province.');
      }

      final weatherJson = json.decode(response.body);
      final currentWeather = WeatherData.fromJson(weatherJson);
      
      setState(() {
        _currentWeather = currentWeather;
        _currentLocationName = currentWeather.name;
      });
      
      _checkAlert(currentWeather.weatherId, currentWeather.windSpeed, currentWeather.description);
      
      await _loadForecast(currentWeather.lat, currentWeather.lon);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception:', ''))),
      );
      setState(() {
        _isLoading = false;
      });
      if (_currentWeather == null) {
        _loadWeatherByCity('Manila');
      }
    }
  }

  Future<void> _loadForecast(double lat, double lon) async {
    try {
      String url = 'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final forecastJson = json.decode(response.body);
        setState(() {
          _forecastData = ForecastData.fromJson(forecastJson);
        });
      }
    } catch (e) {
      // Silent fail for forecast
    }
  }

  Future<void> _loadWeatherByCoords(Position position) async {
    setState(() {
      _isLoading = true;
      _alertMessage = null;
    });

    try {
      String url = 'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('Coordinates not supported');
      }
      
      final weatherJson = json.decode(response.body);
      final currentWeather = WeatherData.fromJson(weatherJson);
      
      setState(() {
        _currentWeather = currentWeather;
        _currentLocationName = currentWeather.name;
      });
      
      _checkAlert(currentWeather.weatherId, currentWeather.windSpeed, currentWeather.description);
      await _loadForecast(currentWeather.lat, currentWeather.lon);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not retrieve weather from your location. Loading Manila as fallback.')),
      );
      setState(() {
        _isLoading = false;
      });
      _loadWeatherByCity('Manila');
    }
  }

  void _handleLocationSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a province, city or municipality from the Philippines list.')),
      );
      return;
    }
    _loadWeatherByCity(query);
  }

  void _handleGeoLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled. Loading Manila instead.')),
      );
      _loadWeatherByCity('Manila');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location access denied. Loading Manila instead.')),
        );
        _loadWeatherByCity('Manila');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions permanently denied. Loading Manila instead.')),
      );
      _loadWeatherByCity('Manila');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      await _loadWeatherByCoords(position);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get your location. Loading Manila instead.')),
      );
      _loadWeatherByCity('Manila');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tibo Weather App'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD9E6F2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Color(0xFF1E3A4D)),
                const SizedBox(width: 4),
                Text(_currentLocationName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E3A4D))),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search section
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(56),
                            border: Border.all(color: const Color(0xFFCAD2D9)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Search location',
                                    prefixIcon: Icon(Icons.search, color: Color(0xFF9AAEBF)),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  onFieldSubmitted: (_) => _handleLocationSearch(),
                                ),
                              ),
                              Container(
                                height: 48,
                                width: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF5B042),
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(56),
                                    bottomRight: Radius.circular(56),
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Color(0xFF2D2A23)),
                                  onPressed: _handleLocationSearch,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _handleGeoLocation,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('My Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C6280),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                    ),
                  ),
                ],
              ),
            ),

            // Weather content
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    SizedBox(height: 16),
                    Text('Fetching weather...', style: TextStyle(color: Color(0xFF4C6573))),
                  ],
                ),
              )
            else if (_currentWeather != null)
              Column(
                children: [
                  // Current weather card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: const Color(0xFFCFDED9)),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentWeather!.temp.round().toString(),
                              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w700, color: Color(0xFFE07C1F)),
                            ),
                            const Text('°C', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: Color(0xFFB86B1B))),
                          ],
                        ),
                        Icon(_getWeatherIcon(_currentWeather!.weatherId), size: 60, color: const Color(0xFFF5B042)),
          
