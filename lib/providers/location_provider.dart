// ============================================================
// AeroSense — Location Provider  (v4 — All India)
// 70 cities across every state/UT × 6 areas = 420+ localities
// Real lat/lon. Text + voice search at city and area level.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/geocoding_service.dart';
import '../services/geolocator_helper.dart';

// ─────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────
class AqiCity {
  final String name;
  final String state;
  final double latitude;
  final double longitude;
  final String emoji;

  const AqiCity({
    required this.name,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.emoji,
  });

  String get displayName => '$emoji $name';
  String get fullName    => '$name, $state';

  @override
  bool operator ==(Object other) => other is AqiCity && other.name == name;
  @override
  int  get hashCode => name.hashCode;
}

class CityArea {
  final String cityName;
  final String name;
  final double latitude;
  final double longitude;
  final String type; // residential|commercial|industrial|mixed

  const CityArea({
    required this.cityName,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.type = 'mixed',
  });

  String get fullName => '$name, $cityName';

  @override
  bool operator ==(Object other) =>
      other is CityArea && other.cityName == cityName && other.name == name;
  @override
  int get hashCode => Object.hash(cityName, name);
}

// ─────────────────────────────────────────────────────────────
// 70 cities — all Indian states / UTs represented
// ─────────────────────────────────────────────────────────────
const List<AqiCity> kSupportedCities = [
  // ── Mega-metros ───────────────────────────────────────────
  AqiCity(name:'New Delhi',        state:'Delhi',             latitude:28.6139, longitude:77.2090, emoji:'🏛️'),
  AqiCity(name:'Mumbai',           state:'Maharashtra',        latitude:19.0760, longitude:72.8777, emoji:'🌊'),
  AqiCity(name:'Bengaluru',        state:'Karnataka',          latitude:12.9716, longitude:77.5946, emoji:'🌿'),
  AqiCity(name:'Chennai',          state:'Tamil Nadu',         latitude:13.0827, longitude:80.2707, emoji:'🌴'),
  AqiCity(name:'Kolkata',          state:'West Bengal',        latitude:22.5726, longitude:88.3639, emoji:'🎭'),
  AqiCity(name:'Hyderabad',        state:'Telangana',          latitude:17.3850, longitude:78.4867, emoji:'💎'),
  // ── Tier-2 metros ─────────────────────────────────────────
  AqiCity(name:'Pune',             state:'Maharashtra',        latitude:18.5204, longitude:73.8567, emoji:'🎓'),
  AqiCity(name:'Ahmedabad',        state:'Gujarat',            latitude:23.0225, longitude:72.5714, emoji:'🏭'),
  AqiCity(name:'Jaipur',           state:'Rajasthan',          latitude:26.9124, longitude:75.7873, emoji:'🏰'),
  AqiCity(name:'Lucknow',          state:'Uttar Pradesh',      latitude:26.8467, longitude:80.9462, emoji:'🕌'),
  AqiCity(name:'Surat',            state:'Gujarat',            latitude:21.1702, longitude:72.8311, emoji:'💠'),
  AqiCity(name:'Kanpur',           state:'Uttar Pradesh',      latitude:26.4499, longitude:80.3319, emoji:'🏗️'),
  AqiCity(name:'Nagpur',           state:'Maharashtra',        latitude:21.1458, longitude:79.0882, emoji:'🍊'),
  AqiCity(name:'Indore',           state:'Madhya Pradesh',     latitude:22.7196, longitude:75.8577, emoji:'🏙️'),
  AqiCity(name:'Bhopal',           state:'Madhya Pradesh',     latitude:23.2599, longitude:77.4126, emoji:'💧'),
  AqiCity(name:'Patna',            state:'Bihar',              latitude:25.5941, longitude:85.1376, emoji:'🏞️'),
  AqiCity(name:'Visakhapatnam',    state:'Andhra Pradesh',     latitude:17.6868, longitude:83.2185, emoji:'⚓'),
  AqiCity(name:'Vadodara',         state:'Gujarat',            latitude:22.3072, longitude:73.1812, emoji:'🎨'),
  AqiCity(name:'Coimbatore',       state:'Tamil Nadu',         latitude:11.0168, longitude:76.9558, emoji:'🧵'),
  AqiCity(name:'Kochi',            state:'Kerala',             latitude:9.9312,  longitude:76.2673, emoji:'🚢'),
  AqiCity(name:'Chandigarh',       state:'Punjab',             latitude:30.7333, longitude:76.7794, emoji:'🌳'),
  AqiCity(name:'Guwahati',         state:'Assam',              latitude:26.1445, longitude:91.7362, emoji:'🌺'),
  AqiCity(name:'Bhubaneswar',      state:'Odisha',             latitude:20.2961, longitude:85.8245, emoji:'🪐'),
  AqiCity(name:'Thiruvananthapuram',state:'Kerala',            latitude:8.5241,  longitude:76.9366, emoji:'🌞'),
  AqiCity(name:'Amritsar',         state:'Punjab',             latitude:31.6340, longitude:74.8723, emoji:'🕍'),
  AqiCity(name:'Agra',             state:'Uttar Pradesh',      latitude:27.1767, longitude:78.0081, emoji:'🏯'),
  AqiCity(name:'Varanasi',         state:'Uttar Pradesh',      latitude:25.3176, longitude:82.9739, emoji:'🪔'),
  AqiCity(name:'Jodhpur',          state:'Rajasthan',          latitude:26.2389, longitude:73.0243, emoji:'🏜️'),
  AqiCity(name:'Goa (Panaji)',      state:'Goa',                latitude:15.4909, longitude:73.8278, emoji:'🏖️'),
  AqiCity(name:'Ranchi',           state:'Jharkhand',          latitude:23.3441, longitude:85.3096, emoji:'⛏️'),
  AqiCity(name:'Raipur',           state:'Chhattisgarh',       latitude:21.2514, longitude:81.6296, emoji:'🌾'),
  AqiCity(name:'Dehradun',         state:'Uttarakhand',        latitude:30.3165, longitude:78.0322, emoji:'🏔️'),
  AqiCity(name:'Shimla',           state:'Himachal Pradesh',   latitude:31.1048, longitude:77.1734, emoji:'❄️'),
  AqiCity(name:'Mysuru',           state:'Karnataka',          latitude:12.2958, longitude:76.6394, emoji:'🐘'),
  AqiCity(name:'Madurai',          state:'Tamil Nadu',         latitude:9.9252,  longitude:78.1198, emoji:'🛕'),
  // ── Additional state capitals & major cities ──────────────
  AqiCity(name:'Vijayawada',       state:'Andhra Pradesh',     latitude:16.5062, longitude:80.6480, emoji:'🌉'),
  AqiCity(name:'Tirupati',         state:'Andhra Pradesh',     latitude:13.6288, longitude:79.4192, emoji:'⛰️'),
  AqiCity(name:'Dibrugarh',        state:'Assam',              latitude:27.4728, longitude:94.9120, emoji:'🍵'),
  AqiCity(name:'Muzaffarpur',      state:'Bihar',              latitude:26.1209, longitude:85.3647, emoji:'🌿'),
  AqiCity(name:'Bhilai',           state:'Chhattisgarh',       latitude:21.1938, longitude:81.3509, emoji:'🏭'),
  AqiCity(name:'Rajkot',           state:'Gujarat',            latitude:22.3039, longitude:70.8022, emoji:'💫'),
  AqiCity(name:'Faridabad',        state:'Haryana',            latitude:28.4089, longitude:77.3178, emoji:'🏙️'),
  AqiCity(name:'Gurugram',         state:'Haryana',            latitude:28.4595, longitude:77.0266, emoji:'🏢'),
  AqiCity(name:'Manali',           state:'Himachal Pradesh',   latitude:32.2396, longitude:77.1887, emoji:'🏔️'),
  AqiCity(name:'Jammu',            state:'Jammu & Kashmir',    latitude:32.7266, longitude:74.8570, emoji:'🕌'),
  AqiCity(name:'Srinagar',         state:'Jammu & Kashmir',    latitude:34.0837, longitude:74.7973, emoji:'🌷'),
  AqiCity(name:'Jamshedpur',       state:'Jharkhand',          latitude:22.8046, longitude:86.2029, emoji:'⚙️'),
  AqiCity(name:'Hubballi',         state:'Karnataka',          latitude:15.3647, longitude:75.1240, emoji:'🌐'),
  AqiCity(name:'Mangaluru',        state:'Karnataka',          latitude:12.9141, longitude:74.8560, emoji:'🌊'),
  AqiCity(name:'Kozhikode',        state:'Kerala',             latitude:11.2588, longitude:75.7804, emoji:'🚢'),
  AqiCity(name:'Jabalpur',         state:'Madhya Pradesh',     latitude:23.1815, longitude:79.9864, emoji:'🪨'),
  AqiCity(name:'Gwalior',          state:'Madhya Pradesh',     latitude:26.2183, longitude:78.1828, emoji:'🏰'),
  AqiCity(name:'Nashik',           state:'Maharashtra',        latitude:19.9975, longitude:73.7898, emoji:'🍇'),
  AqiCity(name:'Aurangabad',       state:'Maharashtra',        latitude:19.8762, longitude:75.3433, emoji:'🏺'),
  AqiCity(name:'Imphal',           state:'Manipur',            latitude:24.8170, longitude:93.9368, emoji:'🌸'),
  AqiCity(name:'Shillong',         state:'Meghalaya',          latitude:25.5788, longitude:91.8933, emoji:'🌧️'),
  AqiCity(name:'Aizawl',           state:'Mizoram',            latitude:23.7271, longitude:92.7176, emoji:'🌿'),
  AqiCity(name:'Kohima',           state:'Nagaland',           latitude:25.6751, longitude:94.1086, emoji:'🦅'),
  AqiCity(name:'Cuttack',          state:'Odisha',             latitude:20.4625, longitude:85.8828, emoji:'🏛️'),
  AqiCity(name:'Puducherry',       state:'Puducherry',         latitude:11.9416, longitude:79.8083, emoji:'🇫🇷'),
  AqiCity(name:'Ludhiana',         state:'Punjab',             latitude:30.9010, longitude:75.8573, emoji:'🧵'),
  AqiCity(name:'Kota',             state:'Rajasthan',          latitude:25.2138, longitude:75.8648, emoji:'📚'),
  AqiCity(name:'Gangtok',          state:'Sikkim',             latitude:27.3314, longitude:88.6138, emoji:'🏔️'),
  AqiCity(name:'Salem',            state:'Tamil Nadu',         latitude:11.6643, longitude:78.1460, emoji:'⚡'),
  AqiCity(name:'Tiruchirappalli',  state:'Tamil Nadu',         latitude:10.7905, longitude:78.7047, emoji:'🏯'),
  AqiCity(name:'Agartala',         state:'Tripura',            latitude:23.8315, longitude:91.2868, emoji:'🌿'),
  AqiCity(name:'Prayagraj',        state:'Uttar Pradesh',      latitude:25.4358, longitude:81.8463, emoji:'🛕'),
  AqiCity(name:'Meerut',           state:'Uttar Pradesh',      latitude:28.9845, longitude:77.7064, emoji:'⚔️'),
  AqiCity(name:'Noida',            state:'Uttar Pradesh',      latitude:28.5355, longitude:77.3910, emoji:'🏢'),
  AqiCity(name:'Haridwar',         state:'Uttarakhand',        latitude:29.9457, longitude:78.1642, emoji:'🛕'),
  AqiCity(name:'Durgapur',         state:'West Bengal',        latitude:23.5204, longitude:87.3119, emoji:'🏭'),
  AqiCity(name:'Siliguri',         state:'West Bengal',        latitude:26.7271, longitude:88.3953, emoji:'🍵'),
  AqiCity(name:'Port Blair',       state:'Andaman & Nicobar',  latitude:11.6234, longitude:92.7265, emoji:'🏝️'),
  AqiCity(name:'Silvassa',         state:'Dadra & NH',         latitude:20.2666, longitude:73.0169, emoji:'🌳'),
  AqiCity(name:'Daman',            state:'Daman & Diu',        latitude:20.3974, longitude:72.8328, emoji:'⛵'),
  AqiCity(name:'Kavaratti',        state:'Lakshadweep',        latitude:10.5593, longitude:72.6358, emoji:'🐚'),
  AqiCity(name:'Leh',              state:'Ladakh',             latitude:34.1526, longitude:77.5771, emoji:'🏔️'),
];

// ─────────────────────────────────────────────────────────────
// 420+ areas — 6 per city, real coordinates
// ─────────────────────────────────────────────────────────────
const List<CityArea> kCityAreas = [
  // ── New Delhi ──────────────────────────────────────────────
  CityArea(cityName:'New Delhi', name:'Connaught Place',   latitude:28.6315, longitude:77.2167, type:'commercial'),
  CityArea(cityName:'New Delhi', name:'Karol Bagh',        latitude:28.6514, longitude:77.1907, type:'commercial'),
  CityArea(cityName:'New Delhi', name:'Dwarka',            latitude:28.5921, longitude:77.0460, type:'residential'),
  CityArea(cityName:'New Delhi', name:'Rohini',            latitude:28.7337, longitude:77.1167, type:'residential'),
  CityArea(cityName:'New Delhi', name:'Lajpat Nagar',      latitude:28.5677, longitude:77.2433, type:'mixed'),
  CityArea(cityName:'New Delhi', name:'Anand Vihar',       latitude:28.6468, longitude:77.3159, type:'mixed'),
  // ── Mumbai ─────────────────────────────────────────────────
  CityArea(cityName:'Mumbai', name:'Andheri',        latitude:19.1136, longitude:72.8697, type:'mixed'),
  CityArea(cityName:'Mumbai', name:'Bandra',         latitude:19.0596, longitude:72.8295, type:'residential'),
  CityArea(cityName:'Mumbai', name:'Colaba',         latitude:18.9067, longitude:72.9162, type:'commercial'),
  CityArea(cityName:'Mumbai', name:'Dadar',          latitude:19.0186, longitude:72.8429, type:'mixed'),
  CityArea(cityName:'Mumbai', name:'Borivali',       latitude:19.2288, longitude:72.8570, type:'residential'),
  CityArea(cityName:'Mumbai', name:'Kurla',          latitude:19.0726, longitude:72.8800, type:'mixed'),
  // ── Bengaluru ──────────────────────────────────────────────
  CityArea(cityName:'Bengaluru', name:'Koramangala',  latitude:12.9352, longitude:77.6245, type:'mixed'),
  CityArea(cityName:'Bengaluru', name:'Whitefield',   latitude:12.9698, longitude:77.7499, type:'commercial'),
  CityArea(cityName:'Bengaluru', name:'Indiranagar',  latitude:12.9783, longitude:77.6408, type:'residential'),
  CityArea(cityName:'Bengaluru', name:'Jayanagar',    latitude:12.9259, longitude:77.5828, type:'residential'),
  CityArea(cityName:'Bengaluru', name:'Marathahalli', latitude:12.9591, longitude:77.6972, type:'commercial'),
  CityArea(cityName:'Bengaluru', name:'Electronic City', latitude:12.8458, longitude:77.6602, type:'commercial'),
  // ── Chennai ────────────────────────────────────────────────
  CityArea(cityName:'Chennai', name:'Anna Nagar',     latitude:13.0858, longitude:80.2101, type:'residential'),
  CityArea(cityName:'Chennai', name:'T. Nagar',       latitude:13.0418, longitude:80.2341, type:'commercial'),
  CityArea(cityName:'Chennai', name:'Velachery',      latitude:12.9815, longitude:80.2180, type:'residential'),
  CityArea(cityName:'Chennai', name:'Adyar',          latitude:13.0012, longitude:80.2565, type:'residential'),
  CityArea(cityName:'Chennai', name:'Guindy',         latitude:13.0067, longitude:80.2206, type:'industrial'),
  CityArea(cityName:'Chennai', name:'Perambur',       latitude:13.1165, longitude:80.2366, type:'industrial'),
  // ── Kolkata ────────────────────────────────────────────────
  CityArea(cityName:'Kolkata', name:'Salt Lake',       latitude:22.5815, longitude:88.4135, type:'mixed'),
  CityArea(cityName:'Kolkata', name:'Park Street',     latitude:22.5520, longitude:88.3510, type:'commercial'),
  CityArea(cityName:'Kolkata', name:'Dum Dum',         latitude:22.6469, longitude:88.3926, type:'mixed'),
  CityArea(cityName:'Kolkata', name:'Howrah',          latitude:22.5958, longitude:88.2636, type:'industrial'),
  CityArea(cityName:'Kolkata', name:'New Town',        latitude:22.5771, longitude:88.4685, type:'commercial'),
  CityArea(cityName:'Kolkata', name:'Jadavpur',        latitude:22.4980, longitude:88.3720, type:'mixed'),
  // ── Hyderabad ──────────────────────────────────────────────
  CityArea(cityName:'Hyderabad', name:'Hitech City',    latitude:17.4435, longitude:78.3772, type:'commercial'),
  CityArea(cityName:'Hyderabad', name:'Banjara Hills',  latitude:17.4126, longitude:78.4482, type:'residential'),
  CityArea(cityName:'Hyderabad', name:'Gachibowli',     latitude:17.4401, longitude:78.3489, type:'commercial'),
  CityArea(cityName:'Hyderabad', name:'Secunderabad',   latitude:17.4399, longitude:78.4983, type:'mixed'),
  CityArea(cityName:'Hyderabad', name:'Kukatpally',     latitude:17.4849, longitude:78.3984, type:'residential'),
  CityArea(cityName:'Hyderabad', name:'Uppal',          latitude:17.4051, longitude:78.5590, type:'industrial'),
  // ── Pune ───────────────────────────────────────────────────
  CityArea(cityName:'Pune', name:'Hinjewadi',      latitude:18.5912, longitude:73.7389, type:'commercial'),
  CityArea(cityName:'Pune', name:'Kothrud',        latitude:18.5074, longitude:73.8077, type:'residential'),
  CityArea(cityName:'Pune', name:'Shivajinagar',   latitude:18.5308, longitude:73.8475, type:'commercial'),
  CityArea(cityName:'Pune', name:'Hadapsar',       latitude:18.5018, longitude:73.9260, type:'mixed'),
  CityArea(cityName:'Pune', name:'Baner',          latitude:18.5590, longitude:73.7868, type:'mixed'),
  CityArea(cityName:'Pune', name:'Viman Nagar',    latitude:18.5679, longitude:73.9143, type:'residential'),
  // ── Ahmedabad ──────────────────────────────────────────────
  CityArea(cityName:'Ahmedabad', name:'Navrangpura',    latitude:23.0375, longitude:72.5612, type:'commercial'),
  CityArea(cityName:'Ahmedabad', name:'Maninagar',      latitude:22.9987, longitude:72.6035, type:'mixed'),
  CityArea(cityName:'Ahmedabad', name:'Satellite',      latitude:23.0305, longitude:72.5120, type:'residential'),
  CityArea(cityName:'Ahmedabad', name:'Bopal',          latitude:23.0265, longitude:72.4674, type:'residential'),
  CityArea(cityName:'Ahmedabad', name:'Naroda',         latitude:23.0831, longitude:72.6452, type:'industrial'),
  CityArea(cityName:'Ahmedabad', name:'Vastrapur',      latitude:23.0394, longitude:72.5280, type:'mixed'),
  // ── Jaipur ─────────────────────────────────────────────────
  CityArea(cityName:'Jaipur', name:'C-Scheme',        latitude:26.9124, longitude:75.8011, type:'commercial'),
  CityArea(cityName:'Jaipur', name:'Vaishali Nagar',  latitude:26.9204, longitude:75.7381, type:'residential'),
  CityArea(cityName:'Jaipur', name:'Mansarovar',      latitude:26.8728, longitude:75.7562, type:'residential'),
  CityArea(cityName:'Jaipur', name:'Malviya Nagar',   latitude:26.8592, longitude:75.8053, type:'mixed'),
  CityArea(cityName:'Jaipur', name:'Sanganer',        latitude:26.8203, longitude:75.7947, type:'industrial'),
  CityArea(cityName:'Jaipur', name:'Tonk Road',       latitude:26.8683, longitude:75.8228, type:'mixed'),
  // ── Lucknow ────────────────────────────────────────────────
  CityArea(cityName:'Lucknow', name:'Gomti Nagar',    latitude:26.8597, longitude:81.0108, type:'residential'),
  CityArea(cityName:'Lucknow', name:'Hazratganj',     latitude:26.8490, longitude:80.9462, type:'commercial'),
  CityArea(cityName:'Lucknow', name:'Aliganj',        latitude:26.8912, longitude:80.9392, type:'residential'),
  CityArea(cityName:'Lucknow', name:'Indira Nagar',   latitude:26.8803, longitude:81.0010, type:'residential'),
  CityArea(cityName:'Lucknow', name:'Alambagh',       latitude:26.8121, longitude:80.9163, type:'mixed'),
  CityArea(cityName:'Lucknow', name:'Chinhat',        latitude:26.8665, longitude:81.0634, type:'industrial'),
  // ── Surat ──────────────────────────────────────────────────
  CityArea(cityName:'Surat', name:'Adajan',        latitude:21.2096, longitude:72.8047, type:'residential'),
  CityArea(cityName:'Surat', name:'Vesu',          latitude:21.1538, longitude:72.7779, type:'residential'),
  CityArea(cityName:'Surat', name:'Katargam',      latitude:21.2172, longitude:72.8453, type:'industrial'),
  CityArea(cityName:'Surat', name:'Udhna',         latitude:21.1764, longitude:72.8696, type:'industrial'),
  CityArea(cityName:'Surat', name:'Althan',        latitude:21.1673, longitude:72.7804, type:'residential'),
  CityArea(cityName:'Surat', name:'Majura Gate',   latitude:21.1989, longitude:72.8298, type:'commercial'),
  // ── Kanpur ─────────────────────────────────────────────────
  CityArea(cityName:'Kanpur', name:'Civil Lines',    latitude:26.4647, longitude:80.3490, type:'residential'),
  CityArea(cityName:'Kanpur', name:'Kidwai Nagar',   latitude:26.4691, longitude:80.3240, type:'mixed'),
  CityArea(cityName:'Kanpur', name:'Panki',          latitude:26.4213, longitude:80.2888, type:'industrial'),
  CityArea(cityName:'Kanpur', name:'Govindnagar',    latitude:26.4925, longitude:80.3531, type:'residential'),
  CityArea(cityName:'Kanpur', name:'Kakadeo',        latitude:26.4720, longitude:80.2941, type:'commercial'),
  CityArea(cityName:'Kanpur', name:'Armapur',        latitude:26.5018, longitude:80.2728, type:'industrial'),
  // ── Nagpur ─────────────────────────────────────────────────
  CityArea(cityName:'Nagpur', name:'Sitabuldi',     latitude:21.1503, longitude:79.0889, type:'commercial'),
  CityArea(cityName:'Nagpur', name:'Dharampeth',    latitude:21.1368, longitude:79.0638, type:'residential'),
  CityArea(cityName:'Nagpur', name:'Wardha Road',   latitude:21.1040, longitude:79.1065, type:'mixed'),
  CityArea(cityName:'Nagpur', name:'Hingna',        latitude:21.1197, longitude:78.9690, type:'industrial'),
  CityArea(cityName:'Nagpur', name:'Manewada',      latitude:21.1025, longitude:79.1355, type:'residential'),
  CityArea(cityName:'Nagpur', name:'Bhandara Road', latitude:21.1642, longitude:79.1492, type:'mixed'),
  // ── Indore ─────────────────────────────────────────────────
  CityArea(cityName:'Indore', name:'Vijay Nagar',   latitude:22.7536, longitude:75.8935, type:'commercial'),
  CityArea(cityName:'Indore', name:'Scheme 54',     latitude:22.7313, longitude:75.8874, type:'residential'),
  CityArea(cityName:'Indore', name:'Bhawarkua',     latitude:22.6949, longitude:75.8667, type:'mixed'),
  CityArea(cityName:'Indore', name:'Palasia',       latitude:22.7218, longitude:75.8707, type:'commercial'),
  CityArea(cityName:'Indore', name:'Pipliyahana',   latitude:22.7086, longitude:75.9113, type:'industrial'),
  CityArea(cityName:'Indore', name:'LIG Colony',    latitude:22.7449, longitude:75.8583, type:'residential'),
  // ── Bhopal ─────────────────────────────────────────────────
  CityArea(cityName:'Bhopal', name:'MP Nagar',     latitude:23.2341, longitude:77.4338, type:'commercial'),
  CityArea(cityName:'Bhopal', name:'Arera Colony', latitude:23.2195, longitude:77.4381, type:'residential'),
  CityArea(cityName:'Bhopal', name:'Kolar',        latitude:23.1932, longitude:77.4690, type:'residential'),
  CityArea(cityName:'Bhopal', name:'Bairagarh',    latitude:23.2994, longitude:77.3546, type:'industrial'),
  CityArea(cityName:'Bhopal', name:'TT Nagar',     latitude:23.2512, longitude:77.4057, type:'mixed'),
  CityArea(cityName:'Bhopal', name:'Shahpura',     latitude:23.2070, longitude:77.4556, type:'residential'),
  // ── Patna ──────────────────────────────────────────────────
  CityArea(cityName:'Patna', name:'Boring Road',    latitude:25.6150, longitude:85.1231, type:'commercial'),
  CityArea(cityName:'Patna', name:'Kankarbagh',     latitude:25.5961, longitude:85.1679, type:'residential'),
  CityArea(cityName:'Patna', name:'Rajendra Nagar', latitude:25.5851, longitude:85.1336, type:'residential'),
  CityArea(cityName:'Patna', name:'Danapur',        latitude:25.6126, longitude:85.0487, type:'mixed'),
  CityArea(cityName:'Patna', name:'Khagaul',        latitude:25.5791, longitude:85.0469, type:'industrial'),
  CityArea(cityName:'Patna', name:'Patna Sahib',    latitude:25.6120, longitude:85.2176, type:'mixed'),
  // ── Visakhapatnam ──────────────────────────────────────────
  CityArea(cityName:'Visakhapatnam', name:'MVP Colony',    latitude:17.7231, longitude:83.3012, type:'residential'),
  CityArea(cityName:'Visakhapatnam', name:'Gajuwaka',      latitude:17.6890, longitude:83.2101, type:'industrial'),
  CityArea(cityName:'Visakhapatnam', name:'Maddilapalem',  latitude:17.7455, longitude:83.3337, type:'residential'),
  CityArea(cityName:'Visakhapatnam', name:'Rushikonda',    latitude:17.7862, longitude:83.3793, type:'mixed'),
  CityArea(cityName:'Visakhapatnam', name:'Kommadi',       latitude:17.7832, longitude:83.3562, type:'mixed'),
  CityArea(cityName:'Visakhapatnam', name:'Steel Plant',   latitude:17.6734, longitude:83.1849, type:'industrial'),
  // ── Vadodara ───────────────────────────────────────────────
  CityArea(cityName:'Vadodara', name:'Alkapuri',    latitude:22.3119, longitude:73.1723, type:'commercial'),
  CityArea(cityName:'Vadodara', name:'Fatehgunj',   latitude:22.3268, longitude:73.1895, type:'mixed'),
  CityArea(cityName:'Vadodara', name:'Gotri',       latitude:22.3389, longitude:73.1368, type:'residential'),
  CityArea(cityName:'Vadodara', name:'Subhanpura',  latitude:22.3262, longitude:73.1569, type:'residential'),
  CityArea(cityName:'Vadodara', name:'GIDC',        latitude:22.3480, longitude:73.2254, type:'industrial'),
  CityArea(cityName:'Vadodara', name:'Waghodia',    latitude:22.3040, longitude:73.2580, type:'industrial'),
  // ── Coimbatore ─────────────────────────────────────────────
  CityArea(cityName:'Coimbatore', name:'RS Puram',      latitude:11.0042, longitude:76.9478, type:'commercial'),
  CityArea(cityName:'Coimbatore', name:'Peelamedu',     latitude:11.0270, longitude:77.0266, type:'mixed'),
  CityArea(cityName:'Coimbatore', name:'Saibaba Colony',latitude:11.0188, longitude:76.9711, type:'residential'),
  CityArea(cityName:'Coimbatore', name:'Singanallur',   latitude:10.9996, longitude:77.0262, type:'mixed'),
  CityArea(cityName:'Coimbatore', name:'Ganapathy',     latitude:11.0478, longitude:76.9870, type:'residential'),
  CityArea(cityName:'Coimbatore', name:'Kuniyamuthur',  latitude:10.9586, longitude:76.9490, type:'industrial'),
  // ── Kochi ──────────────────────────────────────────────────
  CityArea(cityName:'Kochi', name:'Ernakulam',     latitude:9.9816,  longitude:76.2999, type:'commercial'),
  CityArea(cityName:'Kochi', name:'Kakkanad',      latitude:10.0159, longitude:76.3419, type:'commercial'),
  CityArea(cityName:'Kochi', name:'Edappally',     latitude:10.0268, longitude:76.3126, type:'mixed'),
  CityArea(cityName:'Kochi', name:'Aluva',         latitude:10.1004, longitude:76.3570, type:'industrial'),
  CityArea(cityName:'Kochi', name:'Tripunithura',  latitude:9.9443,  longitude:76.3490, type:'residential'),
  CityArea(cityName:'Kochi', name:'Maradu',        latitude:9.9367,  longitude:76.3220, type:'residential'),
  // ── Chandigarh ─────────────────────────────────────────────
  CityArea(cityName:'Chandigarh', name:'Sector 17',   latitude:30.7388, longitude:76.7887, type:'commercial'),
  CityArea(cityName:'Chandigarh', name:'Sector 22',   latitude:30.7280, longitude:76.7814, type:'mixed'),
  CityArea(cityName:'Chandigarh', name:'Sector 34',   latitude:30.7202, longitude:76.7763, type:'residential'),
  CityArea(cityName:'Chandigarh', name:'Manimajra',   latitude:30.7194, longitude:76.8420, type:'industrial'),
  CityArea(cityName:'Chandigarh', name:'Mohali',      latitude:30.7046, longitude:76.7179, type:'mixed'),
  CityArea(cityName:'Chandigarh', name:'Panchkula',   latitude:30.6942, longitude:76.8606, type:'residential'),
  // ── Guwahati ───────────────────────────────────────────────
  CityArea(cityName:'Guwahati', name:'Dispur',        latitude:26.1376, longitude:91.7800, type:'commercial'),
  CityArea(cityName:'Guwahati', name:'Paltan Bazar',  latitude:26.1834, longitude:91.7528, type:'commercial'),
  CityArea(cityName:'Guwahati', name:'Beltola',       latitude:26.1193, longitude:91.7779, type:'residential'),
  CityArea(cityName:'Guwahati', name:'Chandmari',     latitude:26.1714, longitude:91.7589, type:'mixed'),
  CityArea(cityName:'Guwahati', name:'Garchuk',       latitude:26.1462, longitude:91.6977, type:'residential'),
  CityArea(cityName:'Guwahati', name:'Amingaon',      latitude:26.2128, longitude:91.6843, type:'industrial'),
  // ── Bhubaneswar ────────────────────────────────────────────
  CityArea(cityName:'Bhubaneswar', name:'Saheed Nagar', latitude:20.2901, longitude:85.8400, type:'commercial'),
  CityArea(cityName:'Bhubaneswar', name:'Patia',        latitude:20.3560, longitude:85.8190, type:'residential'),
  CityArea(cityName:'Bhubaneswar', name:'Nayapalli',    latitude:20.2851, longitude:85.8124, type:'residential'),
  CityArea(cityName:'Bhubaneswar', name:'Rasulgarh',    latitude:20.2726, longitude:85.8531, type:'mixed'),
  CityArea(cityName:'Bhubaneswar', name:'Mancheswar',   latitude:20.2715, longitude:85.8712, type:'industrial'),
  CityArea(cityName:'Bhubaneswar', name:'Infocity',     latitude:20.3540, longitude:85.8141, type:'commercial'),
  // ── Thiruvananthapuram ─────────────────────────────────────
  CityArea(cityName:'Thiruvananthapuram', name:'Kowdiar',     latitude:8.5241,  longitude:76.9241, type:'residential'),
  CityArea(cityName:'Thiruvananthapuram', name:'Kazhakuttam', latitude:8.5652,  longitude:76.8778, type:'commercial'),
  CityArea(cityName:'Thiruvananthapuram', name:'Pattom',      latitude:8.5225,  longitude:76.9444, type:'mixed'),
  CityArea(cityName:'Thiruvananthapuram', name:'Vattiyoorkav', latitude:8.5628, longitude:76.9543, type:'residential'),
  CityArea(cityName:'Thiruvananthapuram', name:'Technopark',  latitude:8.5571,  longitude:76.8815, type:'commercial'),
  CityArea(cityName:'Thiruvananthapuram', name:'Nedumangad',  latitude:8.6011,  longitude:77.0041, type:'mixed'),
  // ── Amritsar ───────────────────────────────────────────────
  CityArea(cityName:'Amritsar', name:'Golden Temple Area', latitude:31.6200, longitude:74.8765, type:'mixed'),
  CityArea(cityName:'Amritsar', name:'Ranjit Avenue',      latitude:31.6386, longitude:74.8552, type:'residential'),
  CityArea(cityName:'Amritsar', name:'Lawrence Road',      latitude:31.6436, longitude:74.8803, type:'commercial'),
  CityArea(cityName:'Amritsar', name:'Majitha Road',       latitude:31.6603, longitude:74.9099, type:'industrial'),
  CityArea(cityName:'Amritsar', name:'GT Road',            latitude:31.6318, longitude:74.9225, type:'mixed'),
  CityArea(cityName:'Amritsar', name:'Sultanwind',         latitude:31.6024, longitude:74.9090, type:'industrial'),
  // ── Agra ───────────────────────────────────────────────────
  CityArea(cityName:'Agra', name:'Taj Ganj',      latitude:27.1751, longitude:78.0421, type:'mixed'),
  CityArea(cityName:'Agra', name:'Shahganj',      latitude:27.1893, longitude:77.9926, type:'commercial'),
  CityArea(cityName:'Agra', name:'Sikandra',      latitude:27.2099, longitude:77.9604, type:'mixed'),
  CityArea(cityName:'Agra', name:'Kamla Nagar',   latitude:27.1913, longitude:78.0188, type:'residential'),
  CityArea(cityName:'Agra', name:'Foundry Nagar', latitude:27.1745, longitude:78.0631, type:'industrial'),
  CityArea(cityName:'Agra', name:'Bodla',         latitude:27.1450, longitude:77.9872, type:'industrial'),
  // ── Varanasi ───────────────────────────────────────────────
  CityArea(cityName:'Varanasi', name:'Godowlia',     latitude:25.3099, longitude:83.0102, type:'commercial'),
  CityArea(cityName:'Varanasi', name:'Sigra',        latitude:25.3313, longitude:82.9891, type:'commercial'),
  CityArea(cityName:'Varanasi', name:'Lanka',        latitude:25.2680, longitude:82.9909, type:'mixed'),
  CityArea(cityName:'Varanasi', name:'Sarnath',      latitude:25.3810, longitude:83.0219, type:'mixed'),
  CityArea(cityName:'Varanasi', name:'Mughal Sarai', latitude:25.2788, longitude:83.1190, type:'industrial'),
  CityArea(cityName:'Varanasi', name:'Pandeypur',    latitude:25.3358, longitude:82.9681, type:'residential'),
  // ── Jodhpur ────────────────────────────────────────────────
  CityArea(cityName:'Jodhpur', name:'Paota',         latitude:26.2974, longitude:73.0242, type:'commercial'),
  CityArea(cityName:'Jodhpur', name:'Shastri Nagar', latitude:26.2580, longitude:73.0337, type:'residential'),
  CityArea(cityName:'Jodhpur', name:'Ratanada',      latitude:26.2694, longitude:73.0060, type:'residential'),
  CityArea(cityName:'Jodhpur', name:'Basni',         latitude:26.2368, longitude:73.0553, type:'industrial'),
  CityArea(cityName:'Jodhpur', name:'Bhagat Ki Kothi', latitude:26.2890, longitude:73.0465, type:'mixed'),
  CityArea(cityName:'Jodhpur', name:'Pal',           latitude:26.2224, longitude:73.0831, type:'mixed'),
  // ── Goa (Panaji) ───────────────────────────────────────────
  CityArea(cityName:'Goa (Panaji)', name:'Panaji City',   latitude:15.4909, longitude:73.8278, type:'commercial'),
  CityArea(cityName:'Goa (Panaji)', name:'Mapusa',        latitude:15.5933, longitude:73.8098, type:'mixed'),
  CityArea(cityName:'Goa (Panaji)', name:'Margao',        latitude:15.2832, longitude:73.9862, type:'commercial'),
  CityArea(cityName:'Goa (Panaji)', name:'Calangute',     latitude:15.5440, longitude:73.7552, type:'mixed'),
  CityArea(cityName:'Goa (Panaji)', name:'Vasco',         latitude:15.3957, longitude:73.8117, type:'industrial'),
  CityArea(cityName:'Goa (Panaji)', name:'Ponda',         latitude:15.4028, longitude:74.0117, type:'industrial'),
  // ── Ranchi ─────────────────────────────────────────────────
  CityArea(cityName:'Ranchi', name:'Harmu',       latitude:23.3652, longitude:85.2942, type:'residential'),
  CityArea(cityName:'Ranchi', name:'Doranda',     latitude:23.3320, longitude:85.3068, type:'commercial'),
  CityArea(cityName:'Ranchi', name:'Kanke',       latitude:23.3952, longitude:85.3178, type:'mixed'),
  CityArea(cityName:'Ranchi', name:'Booty More',  latitude:23.3785, longitude:85.3339, type:'mixed'),
  CityArea(cityName:'Ranchi', name:'Namkum',      latitude:23.3079, longitude:85.3681, type:'industrial'),
  CityArea(cityName:'Ranchi', name:'Argora',      latitude:23.3622, longitude:85.3211, type:'residential'),
  // ── Raipur ─────────────────────────────────────────────────
  CityArea(cityName:'Raipur', name:'Telibandha',   latitude:21.2592, longitude:81.6376, type:'commercial'),
  CityArea(cityName:'Raipur', name:'Shankar Nagar',latitude:21.2736, longitude:81.6541, type:'residential'),
  CityArea(cityName:'Raipur', name:'Mowa',         latitude:21.2802, longitude:81.6724, type:'mixed'),
  CityArea(cityName:'Raipur', name:'Fafadih',      latitude:21.2443, longitude:81.6704, type:'industrial'),
  CityArea(cityName:'Raipur', name:'Avanti Vihar', latitude:21.2446, longitude:81.6538, type:'residential'),
  CityArea(cityName:'Raipur', name:'Pandri',       latitude:21.2355, longitude:81.6408, type:'mixed'),
  // ── Dehradun ───────────────────────────────────────────────
  CityArea(cityName:'Dehradun', name:'Rajpur Road',  latitude:30.3433, longitude:78.0545, type:'commercial'),
  CityArea(cityName:'Dehradun', name:'Prem Nagar',   latitude:30.2934, longitude:77.9866, type:'residential'),
  CityArea(cityName:'Dehradun', name:'Clement Town', latitude:30.2868, longitude:78.0048, type:'mixed'),
  CityArea(cityName:'Dehradun', name:'Raipur Road',  latitude:30.3748, longitude:78.0876, type:'mixed'),
  CityArea(cityName:'Dehradun', name:'ISBT Area',    latitude:30.3245, longitude:78.0432, type:'commercial'),
  CityArea(cityName:'Dehradun', name:'Selaqui',      latitude:30.3542, longitude:77.8908, type:'industrial'),
  // ── Shimla ─────────────────────────────────────────────────
  CityArea(cityName:'Shimla', name:'The Mall',     latitude:31.1048, longitude:77.1734, type:'commercial'),
  CityArea(cityName:'Shimla', name:'Sanjauli',     latitude:31.0951, longitude:77.1775, type:'residential'),
  CityArea(cityName:'Shimla', name:'Lakkar Bazar', latitude:31.1023, longitude:77.1680, type:'commercial'),
  CityArea(cityName:'Shimla', name:'Chhota Shimla',latitude:31.0987, longitude:77.1621, type:'residential'),
  CityArea(cityName:'Shimla', name:'Kufri',        latitude:31.0985, longitude:77.2626, type:'mixed'),
  CityArea(cityName:'Shimla', name:'Rampur',       latitude:31.4467, longitude:77.6294, type:'industrial'),
  // ── Mysuru ─────────────────────────────────────────────────
  CityArea(cityName:'Mysuru', name:'Vijayanagar',       latitude:12.3130, longitude:76.6075, type:'residential'),
  CityArea(cityName:'Mysuru', name:'Jayalakshmipuram',  latitude:12.2987, longitude:76.6408, type:'residential'),
  CityArea(cityName:'Mysuru', name:'Gokulam',           latitude:12.3240, longitude:76.6364, type:'residential'),
  CityArea(cityName:'Mysuru', name:'KRS Road',          latitude:12.3456, longitude:76.6530, type:'mixed'),
  CityArea(cityName:'Mysuru', name:'Hebbal',            latitude:12.3520, longitude:76.6216, type:'industrial'),
  CityArea(cityName:'Mysuru', name:'Nanjangud',         latitude:12.1132, longitude:76.6832, type:'industrial'),
  // ── Madurai ────────────────────────────────────────────────
  CityArea(cityName:'Madurai', name:'Anna Nagar',      latitude:9.9389,  longitude:78.1196, type:'residential'),
  CityArea(cityName:'Madurai', name:'KK Nagar',        latitude:9.9042,  longitude:78.1073, type:'residential'),
  CityArea(cityName:'Madurai', name:'Meenakshi Amman', latitude:9.9195,  longitude:78.1193, type:'mixed'),
  CityArea(cityName:'Madurai', name:'Thiruppalai',     latitude:9.8858,  longitude:78.1421, type:'industrial'),
  CityArea(cityName:'Madurai', name:'Mattuthavani',    latitude:9.9544,  longitude:78.0897, type:'commercial'),
  CityArea(cityName:'Madurai', name:'Avaniyapuram',    latitude:9.8929,  longitude:78.1270, type:'industrial'),
  // ── Vijayawada ─────────────────────────────────────────────
  CityArea(cityName:'Vijayawada', name:'Benz Circle',    latitude:16.5193, longitude:80.6305, type:'commercial'),
  CityArea(cityName:'Vijayawada', name:'Autonagar',      latitude:16.4807, longitude:80.6714, type:'industrial'),
  CityArea(cityName:'Vijayawada', name:'Moghalrajpuram', latitude:16.5116, longitude:80.6213, type:'residential'),
  CityArea(cityName:'Vijayawada', name:'Patamata',       latitude:16.5303, longitude:80.6388, type:'residential'),
  CityArea(cityName:'Vijayawada', name:'Labbipet',       latitude:16.5130, longitude:80.6494, type:'mixed'),
  CityArea(cityName:'Vijayawada', name:'Nunna',          latitude:16.4978, longitude:80.7189, type:'industrial'),
  // ── Tirupati ───────────────────────────────────────────────
  CityArea(cityName:'Tirupati', name:'Balaji Nagar',  latitude:13.6373, longitude:79.4192, type:'residential'),
  CityArea(cityName:'Tirupati', name:'Tiruchanur',    latitude:13.5726, longitude:79.4230, type:'mixed'),
  CityArea(cityName:'Tirupati', name:'Renigunta',     latitude:13.6524, longitude:79.5124, type:'industrial'),
  CityArea(cityName:'Tirupati', name:'Karakambadi',   latitude:13.5919, longitude:79.3729, type:'residential'),
  CityArea(cityName:'Tirupati', name:'Thambalipalle', latitude:13.6079, longitude:79.4765, type:'mixed'),
  CityArea(cityName:'Tirupati', name:'Alipiri',       latitude:13.6499, longitude:79.4027, type:'mixed'),
  // ── Dibrugarh ──────────────────────────────────────────────
  CityArea(cityName:'Dibrugarh', name:'AT Road',       latitude:27.4877, longitude:94.9113, type:'commercial'),
  CityArea(cityName:'Dibrugarh', name:'Charing Cross',  latitude:27.4786, longitude:94.9032, type:'commercial'),
  CityArea(cityName:'Dibrugarh', name:'Barbaruah',      latitude:27.5000, longitude:94.8820, type:'industrial'),
  CityArea(cityName:'Dibrugarh', name:'Lahoal',         latitude:27.4650, longitude:94.9350, type:'industrial'),
  CityArea(cityName:'Dibrugarh', name:'Graham Bazar',   latitude:27.4912, longitude:94.9176, type:'mixed'),
  CityArea(cityName:'Dibrugarh', name:'Mancotta',       latitude:27.4605, longitude:94.9262, type:'residential'),
  // ── Muzaffarpur ────────────────────────────────────────────
  CityArea(cityName:'Muzaffarpur', name:'Mithanpura',    latitude:26.1258, longitude:85.3836, type:'residential'),
  CityArea(cityName:'Muzaffarpur', name:'Brahampura',    latitude:26.1369, longitude:85.3730, type:'mixed'),
  CityArea(cityName:'Muzaffarpur', name:'Juran Chapra',  latitude:26.1148, longitude:85.3517, type:'mixed'),
  CityArea(cityName:'Muzaffarpur', name:'Saraiyaganj',   latitude:26.1197, longitude:85.3611, type:'commercial'),
  CityArea(cityName:'Muzaffarpur', name:'Kazi Mohammadpur', latitude:26.1310, longitude:85.3645, type:'residential'),
  CityArea(cityName:'Muzaffarpur', name:'Ramna',         latitude:26.0985, longitude:85.3716, type:'industrial'),
  // ── Bhilai ─────────────────────────────────────────────────
  CityArea(cityName:'Bhilai', name:'Sector 1',     latitude:21.2160, longitude:81.3762, type:'residential'),
  CityArea(cityName:'Bhilai', name:'Sector 6',     latitude:21.1937, longitude:81.3667, type:'residential'),
  CityArea(cityName:'Bhilai', name:'Steel Plant',  latitude:21.1994, longitude:81.3365, type:'industrial'),
  CityArea(cityName:'Bhilai', name:'Supela',       latitude:21.2211, longitude:81.4160, type:'commercial'),
  CityArea(cityName:'Bhilai', name:'Nehru Nagar',  latitude:21.1870, longitude:81.3818, type:'mixed'),
  CityArea(cityName:'Bhilai', name:'Smrit Nagar',  latitude:21.2085, longitude:81.3961, type:'residential'),
  // ── Panaji (Goa) ───────────────────────────────────────────
  CityArea(cityName:'Goa (Panaji)', name:'Altinho',      latitude:15.5001, longitude:73.8309, type:'residential'),
  CityArea(cityName:'Goa (Panaji)', name:'Fontainhas',   latitude:15.4975, longitude:73.8340, type:'residential'),
  CityArea(cityName:'Goa (Panaji)', name:'Miramar',      latitude:15.4765, longitude:73.8016, type:'mixed'),
  CityArea(cityName:'Goa (Panaji)', name:'Caranzalem',   latitude:15.4793, longitude:73.8149, type:'mixed'),
  CityArea(cityName:'Goa (Panaji)', name:'Ribandar',     latitude:15.5139, longitude:73.8548, type:'mixed'),
  CityArea(cityName:'Goa (Panaji)', name:'Old Goa',      latitude:15.5042, longitude:73.9117, type:'mixed'),
  // ── Rajkot ─────────────────────────────────────────────────
  CityArea(cityName:'Rajkot', name:'Kalawad Road', latitude:22.3120, longitude:70.7798, type:'commercial'),
  CityArea(cityName:'Rajkot', name:'Gondal Road',  latitude:22.2854, longitude:70.7893, type:'mixed'),
  CityArea(cityName:'Rajkot', name:'Raiya',        latitude:22.2998, longitude:70.8316, type:'residential'),
  CityArea(cityName:'Rajkot', name:'Kothariya',    latitude:22.2639, longitude:70.8058, type:'residential'),
  CityArea(cityName:'Rajkot', name:'Bhaktinagar',  latitude:22.2896, longitude:70.8188, type:'mixed'),
  CityArea(cityName:'Rajkot', name:'Aji GIDC',     latitude:22.3186, longitude:70.8457, type:'industrial'),
  // ── Faridabad ──────────────────────────────────────────────
  CityArea(cityName:'Faridabad', name:'Sector 15',     latitude:28.4281, longitude:77.3195, type:'residential'),
  CityArea(cityName:'Faridabad', name:'NIT',           latitude:28.3836, longitude:77.3109, type:'mixed'),
  CityArea(cityName:'Faridabad', name:'Ballabhgarh',   latitude:28.3411, longitude:77.3186, type:'industrial'),
  CityArea(cityName:'Faridabad', name:'Sector 37',     latitude:28.4564, longitude:77.2951, type:'residential'),
  CityArea(cityName:'Faridabad', name:'IMT Faridabad', latitude:28.4183, longitude:77.3483, type:'industrial'),
  CityArea(cityName:'Faridabad', name:'Old Faridabad', latitude:28.4089, longitude:77.3178, type:'commercial'),
  // ── Gurugram ───────────────────────────────────────────────
  CityArea(cityName:'Gurugram', name:'DLF Phase 1',   latitude:28.4707, longitude:77.0965, type:'commercial'),
  CityArea(cityName:'Gurugram', name:'Cyber City',    latitude:28.4950, longitude:77.0888, type:'commercial'),
  CityArea(cityName:'Gurugram', name:'Sohna Road',    latitude:28.4151, longitude:77.0374, type:'mixed'),
  CityArea(cityName:'Gurugram', name:'Palam Vihar',   latitude:28.5167, longitude:76.9918, type:'residential'),
  CityArea(cityName:'Gurugram', name:'Manesar',       latitude:28.3564, longitude:76.9360, type:'industrial'),
  CityArea(cityName:'Gurugram', name:'Golf Course Rd',latitude:28.4421, longitude:77.1025, type:'residential'),
  // ── Manali ─────────────────────────────────────────────────
  CityArea(cityName:'Manali', name:'Old Manali',    latitude:32.2559, longitude:77.1792, type:'mixed'),
  CityArea(cityName:'Manali', name:'Mall Road',     latitude:32.2396, longitude:77.1887, type:'commercial'),
  CityArea(cityName:'Manali', name:'Solang Valley', latitude:32.3149, longitude:77.1525, type:'mixed'),
  CityArea(cityName:'Manali', name:'Kullu',         latitude:31.9578, longitude:77.1095, type:'commercial'),
  CityArea(cityName:'Manali', name:'Naggar',        latitude:32.0952, longitude:77.1661, type:'residential'),
  CityArea(cityName:'Manali', name:'Rohtang',       latitude:32.3748, longitude:77.2414, type:'mixed'),
  // ── Jammu ──────────────────────────────────────────────────
  CityArea(cityName:'Jammu', name:'Gandhi Nagar',  latitude:32.7266, longitude:74.8700, type:'residential'),
  CityArea(cityName:'Jammu', name:'Bakshi Nagar',  latitude:32.7432, longitude:74.8637, type:'mixed'),
  CityArea(cityName:'Jammu', name:'Trikuta Nagar', latitude:32.7382, longitude:74.8296, type:'commercial'),
  CityArea(cityName:'Jammu', name:'Nagrota',       latitude:32.6645, longitude:74.9007, type:'industrial'),
  CityArea(cityName:'Jammu', name:'Samba',         latitude:32.5597, longitude:75.1165, type:'industrial'),
  CityArea(cityName:'Jammu', name:'Parade Ground', latitude:32.7299, longitude:74.8570, type:'commercial'),
  // ── Srinagar ───────────────────────────────────────────────
  CityArea(cityName:'Srinagar', name:'Lal Chowk',    latitude:34.0837, longitude:74.7972, type:'commercial'),
  CityArea(cityName:'Srinagar', name:'Dal Lake',      latitude:34.0927, longitude:74.8440, type:'mixed'),
  CityArea(cityName:'Srinagar', name:'Rajbagh',       latitude:34.0742, longitude:74.8184, type:'residential'),
  CityArea(cityName:'Srinagar', name:'Hyderpora',     latitude:34.1136, longitude:74.7874, type:'commercial'),
  CityArea(cityName:'Srinagar', name:'Bemina',        latitude:34.0862, longitude:74.7550, type:'industrial'),
  CityArea(cityName:'Srinagar', name:'Soura',         latitude:34.1038, longitude:74.8116, type:'mixed'),
  // ── Jamshedpur ─────────────────────────────────────────────
  CityArea(cityName:'Jamshedpur', name:'Bistupur',    latitude:22.8046, longitude:86.1874, type:'commercial'),
  CityArea(cityName:'Jamshedpur', name:'Sakchi',      latitude:22.7966, longitude:86.1893, type:'commercial'),
  CityArea(cityName:'Jamshedpur', name:'Jugsalai',    latitude:22.7876, longitude:86.1967, type:'mixed'),
  CityArea(cityName:'Jamshedpur', name:'Adityapur',   latitude:22.7844, longitude:86.1429, type:'industrial'),
  CityArea(cityName:'Jamshedpur', name:'Gamharia',    latitude:22.7639, longitude:86.1556, type:'industrial'),
  CityArea(cityName:'Jamshedpur', name:'Telco',       latitude:22.8209, longitude:86.1632, type:'industrial'),
  // ── Hubballi ───────────────────────────────────────────────
  CityArea(cityName:'Hubballi', name:'Vidyanagar',    latitude:15.3647, longitude:75.1240, type:'residential'),
  CityArea(cityName:'Hubballi', name:'Gokul Road',    latitude:15.3823, longitude:75.1152, type:'commercial'),
  CityArea(cityName:'Hubballi', name:'Navanagar',     latitude:15.3701, longitude:75.1454, type:'residential'),
  CityArea(cityName:'Hubballi', name:'Dharwad',       latitude:15.4589, longitude:75.0078, type:'mixed'),
  CityArea(cityName:'Hubballi', name:'Keshwapur',     latitude:15.3474, longitude:75.0892, type:'mixed'),
  CityArea(cityName:'Hubballi', name:'KSSIDC',        latitude:15.3380, longitude:75.1567, type:'industrial'),
  // ── Mangaluru ──────────────────────────────────────────────
  CityArea(cityName:'Mangaluru', name:'Hampankatta',  latitude:12.8698, longitude:74.8433, type:'commercial'),
  CityArea(cityName:'Mangaluru', name:'Kadri',        latitude:12.8814, longitude:74.8577, type:'residential'),
  CityArea(cityName:'Mangaluru', name:'Bejai',        latitude:12.8748, longitude:74.8517, type:'mixed'),
  CityArea(cityName:'Mangaluru', name:'Falnir',       latitude:12.8841, longitude:74.8351, type:'residential'),
  CityArea(cityName:'Mangaluru', name:'Baikampady',   latitude:12.9038, longitude:74.8690, type:'industrial'),
  CityArea(cityName:'Mangaluru', name:'Surathkal',    latitude:13.0143, longitude:74.7918, type:'industrial'),
  // ── Kozhikode ──────────────────────────────────────────────
  CityArea(cityName:'Kozhikode', name:'Calicut Beach', latitude:11.2491, longitude:75.7768, type:'mixed'),
  CityArea(cityName:'Kozhikode', name:'Palayam',       latitude:11.2588, longitude:75.7804, type:'commercial'),
  CityArea(cityName:'Kozhikode', name:'Nadakkavu',     latitude:11.2689, longitude:75.7746, type:'residential'),
  CityArea(cityName:'Kozhikode', name:'Feroke',        latitude:11.1836, longitude:75.8180, type:'industrial'),
  CityArea(cityName:'Kozhikode', name:'Mavoor',        latitude:11.2801, longitude:75.9035, type:'industrial'),
  CityArea(cityName:'Kozhikode', name:'Beypore',       latitude:11.1699, longitude:75.8122, type:'mixed'),
  // ── Jabalpur ───────────────────────────────────────────────
  CityArea(cityName:'Jabalpur', name:'Napier Town',  latitude:23.1730, longitude:79.9367, type:'commercial'),
  CityArea(cityName:'Jabalpur', name:'Gorakhpur',    latitude:23.1990, longitude:79.9823, type:'mixed'),
  CityArea(cityName:'Jabalpur', name:'Adhartal',     latitude:23.2202, longitude:79.9786, type:'mixed'),
  CityArea(cityName:'Jabalpur', name:'Madan Mahal',  latitude:23.1589, longitude:79.9518, type:'residential'),
  CityArea(cityName:'Jabalpur', name:'Ordnance Factory', latitude:23.2000, longitude:80.0392, type:'industrial'),
  CityArea(cityName:'Jabalpur', name:'Mandla Road',  latitude:23.1329, longitude:79.9892, type:'mixed'),
  // ── Gwalior ────────────────────────────────────────────────
  CityArea(cityName:'Gwalior', name:'City Centre',  latitude:26.2183, longitude:78.1828, type:'commercial'),
  CityArea(cityName:'Gwalior', name:'Lashkar',      latitude:26.2124, longitude:78.1771, type:'mixed'),
  CityArea(cityName:'Gwalior', name:'Morar',        latitude:26.2440, longitude:78.2270, type:'mixed'),
  CityArea(cityName:'Gwalior', name:'Thatipur',     latitude:26.1960, longitude:78.1463, type:'residential'),
  CityArea(cityName:'Gwalior', name:'Banmore',      latitude:26.1618, longitude:78.0897, type:'industrial'),
  CityArea(cityName:'Gwalior', name:'Bahodapur',    latitude:26.2368, longitude:78.1631, type:'residential'),
  // ── Nashik ─────────────────────────────────────────────────
  CityArea(cityName:'Nashik', name:'Gangapur Road', latitude:20.0113, longitude:73.7631, type:'commercial'),
  CityArea(cityName:'Nashik', name:'Panchvati',     latitude:20.0105, longitude:73.7866, type:'mixed'),
  CityArea(cityName:'Nashik', name:'Satpur MIDC',   latitude:19.9837, longitude:73.7543, type:'industrial'),
  CityArea(cityName:'Nashik', name:'Ambad',         latitude:20.0220, longitude:73.7426, type:'industrial'),
  CityArea(cityName:'Nashik', name:'Deolali',       latitude:19.9283, longitude:73.8306, type:'mixed'),
  CityArea(cityName:'Nashik', name:'Cidco',         latitude:19.9682, longitude:73.7998, type:'residential'),
  // ── Aurangabad ─────────────────────────────────────────────
  CityArea(cityName:'Aurangabad', name:'CIDCO',        latitude:19.9082, longitude:75.3241, type:'commercial'),
  CityArea(cityName:'Aurangabad', name:'Garkheda',     latitude:19.8558, longitude:75.3756, type:'mixed'),
  CityArea(cityName:'Aurangabad', name:'Bajajnagar',   latitude:19.8933, longitude:75.3093, type:'residential'),
  CityArea(cityName:'Aurangabad', name:'MIDC Waluj',   latitude:19.8360, longitude:75.2763, type:'industrial'),
  CityArea(cityName:'Aurangabad', name:'Chikalthana',  latitude:19.8453, longitude:75.3945, type:'industrial'),
  CityArea(cityName:'Aurangabad', name:'Osmanpura',    latitude:19.8762, longitude:75.3433, type:'mixed'),
  // ── Imphal ─────────────────────────────────────────────────
  CityArea(cityName:'Imphal', name:'Paona Bazar',   latitude:24.8062, longitude:93.9374, type:'commercial'),
  CityArea(cityName:'Imphal', name:'Khurai',        latitude:24.8247, longitude:93.9466, type:'mixed'),
  CityArea(cityName:'Imphal', name:'Singjamei',     latitude:24.8342, longitude:93.9115, type:'residential'),
  CityArea(cityName:'Imphal', name:'Lamphelpat',    latitude:24.8094, longitude:93.9027, type:'mixed'),
  CityArea(cityName:'Imphal', name:'Lilong',        latitude:24.7386, longitude:93.9651, type:'industrial'),
  CityArea(cityName:'Imphal', name:'Heingang',      latitude:24.8450, longitude:93.9730, type:'residential'),
  // ── Shillong ───────────────────────────────────────────────
  CityArea(cityName:'Shillong', name:'Police Bazar',  latitude:25.5778, longitude:91.8825, type:'commercial'),
  CityArea(cityName:'Shillong', name:'Laban',         latitude:25.5659, longitude:91.8913, type:'residential'),
  CityArea(cityName:'Shillong', name:'Rynjah',        latitude:25.5811, longitude:91.8636, type:'residential'),
  CityArea(cityName:'Shillong', name:'Mawlai',        latitude:25.5951, longitude:91.8772, type:'mixed'),
  CityArea(cityName:'Shillong', name:'Nongthymmai',   latitude:25.5730, longitude:91.9157, type:'mixed'),
  CityArea(cityName:'Shillong', name:'Meghalaya Univ',latitude:25.5456, longitude:91.9058, type:'commercial'),
  // ── Aizawl ─────────────────────────────────────────────────
  CityArea(cityName:'Aizawl', name:'Zarkawt',      latitude:23.7271, longitude:92.7176, type:'commercial'),
  CityArea(cityName:'Aizawl', name:'Dawrpui',      latitude:23.7225, longitude:92.7224, type:'mixed'),
  CityArea(cityName:'Aizawl', name:'Bawngkawn',    latitude:23.7382, longitude:92.7254, type:'residential'),
  CityArea(cityName:'Aizawl', name:'Venghlui',     latitude:23.7148, longitude:92.7090, type:'residential'),
  CityArea(cityName:'Aizawl', name:'Ramhlun',      latitude:23.7451, longitude:92.7362, type:'mixed'),
  CityArea(cityName:'Aizawl', name:'Zemabawk',     latitude:23.6940, longitude:92.7283, type:'industrial'),
  // ── Kohima ─────────────────────────────────────────────────
  CityArea(cityName:'Kohima', name:'Town',          latitude:25.6751, longitude:94.1086, type:'commercial'),
  CityArea(cityName:'Kohima', name:'New Market',    latitude:25.6710, longitude:94.1038, type:'commercial'),
  CityArea(cityName:'Kohima', name:'Bayavü',        latitude:25.6618, longitude:94.1147, type:'residential'),
  CityArea(cityName:'Kohima', name:'Meriema',       latitude:25.6854, longitude:94.1023, type:'residential'),
  CityArea(cityName:'Kohima', name:'Lower Chandmari',latitude:25.6782,longitude:94.0943, type:'mixed'),
  CityArea(cityName:'Kohima', name:'Tsiesema',      latitude:25.6959, longitude:94.1204, type:'mixed'),
  // ── Cuttack ────────────────────────────────────────────────
  CityArea(cityName:'Cuttack', name:'Bidanasi',     latitude:20.4625, longitude:85.8510, type:'residential'),
  CityArea(cityName:'Cuttack', name:'Buxi Bazar',   latitude:20.4690, longitude:85.8795, type:'commercial'),
  CityArea(cityName:'Cuttack', name:'Chauliaganj',  latitude:20.4748, longitude:85.8574, type:'mixed'),
  CityArea(cityName:'Cuttack', name:'Mangalabag',   latitude:20.4831, longitude:85.8455, type:'mixed'),
  CityArea(cityName:'Cuttack', name:'NALCO',        latitude:20.3540, longitude:85.1360, type:'industrial'),
  CityArea(cityName:'Cuttack', name:'Jagatpur',     latitude:20.5174, longitude:85.9001, type:'industrial'),
  // ── Puducherry ─────────────────────────────────────────────
  CityArea(cityName:'Puducherry', name:'White Town',    latitude:11.9341, longitude:79.8346, type:'mixed'),
  CityArea(cityName:'Puducherry', name:'Lawspet',       latitude:11.9579, longitude:79.8238, type:'residential'),
  CityArea(cityName:'Puducherry', name:'Muthialpet',    latitude:11.9281, longitude:79.8381, type:'mixed'),
  CityArea(cityName:'Puducherry', name:'Ariyankuppam',  latitude:11.8978, longitude:79.8265, type:'industrial'),
  CityArea(cityName:'Puducherry', name:'Villianur',     latitude:11.9626, longitude:79.7792, type:'industrial'),
  CityArea(cityName:'Puducherry', name:'Osudu',         latitude:11.9776, longitude:79.8593, type:'mixed'),
  // ── Ludhiana ───────────────────────────────────────────────
  CityArea(cityName:'Ludhiana', name:'Model Town',    latitude:30.9138, longitude:75.8446, type:'residential'),
  CityArea(cityName:'Ludhiana', name:'BRS Nagar',     latitude:30.8988, longitude:75.8278, type:'residential'),
  CityArea(cityName:'Ludhiana', name:'Focal Point',   latitude:30.8762, longitude:75.8740, type:'industrial'),
  CityArea(cityName:'Ludhiana', name:'Gill Road',     latitude:30.9246, longitude:75.8789, type:'industrial'),
  CityArea(cityName:'Ludhiana', name:'Sarabha Nagar', latitude:30.9033, longitude:75.8394, type:'commercial'),
  CityArea(cityName:'Ludhiana', name:'Dugri',         latitude:30.8749, longitude:75.8478, type:'mixed'),
  // ── Kota ───────────────────────────────────────────────────
  CityArea(cityName:'Kota', name:'Dadwara',       latitude:25.2138, longitude:75.8648, type:'commercial'),
  CityArea(cityName:'Kota', name:'Rangbari',      latitude:25.2354, longitude:75.8453, type:'residential'),
  CityArea(cityName:'Kota', name:'Vigyan Nagar',  latitude:25.1917, longitude:75.8701, type:'mixed'),
  CityArea(cityName:'Kota', name:'DC Mill Area',  latitude:25.2290, longitude:75.8993, type:'industrial'),
  CityArea(cityName:'Kota', name:'Kunhari',       latitude:25.1666, longitude:75.8553, type:'industrial'),
  CityArea(cityName:'Kota', name:'Mahaveer Nagar',latitude:25.1981, longitude:75.8491, type:'residential'),
  // ── Gangtok ────────────────────────────────────────────────
  CityArea(cityName:'Gangtok', name:'MG Marg',      latitude:27.3318, longitude:88.6138, type:'commercial'),
  CityArea(cityName:'Gangtok', name:'Tadong',        latitude:27.3141, longitude:88.6269, type:'mixed'),
  CityArea(cityName:'Gangtok', name:'Ranipool',      latitude:27.2892, longitude:88.6041, type:'residential'),
  CityArea(cityName:'Gangtok', name:'Sajong',        latitude:27.3563, longitude:88.6015, type:'residential'),
  CityArea(cityName:'Gangtok', name:'Pakyong',       latitude:27.2333, longitude:88.6057, type:'mixed'),
  CityArea(cityName:'Gangtok', name:'Singtam',       latitude:27.2283, longitude:88.5024, type:'industrial'),
  // ── Salem ──────────────────────────────────────────────────
  CityArea(cityName:'Salem', name:'Fairlands',    latitude:11.6755, longitude:78.1385, type:'commercial'),
  CityArea(cityName:'Salem', name:'Suramangalam', latitude:11.6528, longitude:78.1660, type:'mixed'),
  CityArea(cityName:'Salem', name:'Ammapet',      latitude:11.6788, longitude:78.1713, type:'mixed'),
  CityArea(cityName:'Salem', name:'Omalur Road',  latitude:11.6347, longitude:78.1289, type:'industrial'),
  CityArea(cityName:'Salem', name:'Mettur',       latitude:11.7868, longitude:77.8005, type:'industrial'),
  CityArea(cityName:'Salem', name:'Hasthampatti', latitude:11.6940, longitude:78.1437, type:'residential'),
  // ── Tiruchirappalli ────────────────────────────────────────
  CityArea(cityName:'Tiruchirappalli', name:'Woraiyur',    latitude:10.8228, longitude:78.6843, type:'mixed'),
  CityArea(cityName:'Tiruchirappalli', name:'Srirangam',   latitude:10.8597, longitude:78.6924, type:'mixed'),
  CityArea(cityName:'Tiruchirappalli', name:'KK Nagar',    latitude:10.7774, longitude:78.7143, type:'residential'),
  CityArea(cityName:'Tiruchirappalli', name:'Kattur',      latitude:10.8041, longitude:78.7640, type:'industrial'),
  CityArea(cityName:'Tiruchirappalli', name:'Thuvakudi',   latitude:10.8330, longitude:78.7823, type:'industrial'),
  CityArea(cityName:'Tiruchirappalli', name:'Ariyamangalam',latitude:10.7673,longitude:78.7977, type:'mixed'),
  // ── Agartala ───────────────────────────────────────────────
  CityArea(cityName:'Agartala', name:'Krishna Nagar', latitude:23.8367, longitude:91.2814, type:'residential'),
  CityArea(cityName:'Agartala', name:'Motor Stand',   latitude:23.8320, longitude:91.2868, type:'commercial'),
  CityArea(cityName:'Agartala', name:'Battala',       latitude:23.8254, longitude:91.2928, type:'commercial'),
  CityArea(cityName:'Agartala', name:'Ramnagar',      latitude:23.8421, longitude:91.3038, type:'residential'),
  CityArea(cityName:'Agartala', name:'Indranagar',    latitude:23.8176, longitude:91.2696, type:'mixed'),
  CityArea(cityName:'Agartala', name:'Bodhjungnagar', latitude:23.8600, longitude:91.2440, type:'industrial'),
  // ── Prayagraj ──────────────────────────────────────────────
  CityArea(cityName:'Prayagraj', name:'Civil Lines',     latitude:25.4567, longitude:81.8489, type:'commercial'),
  CityArea(cityName:'Prayagraj', name:'George Town',     latitude:25.4461, longitude:81.8404, type:'mixed'),
  CityArea(cityName:'Prayagraj', name:'Naini',           latitude:25.3885, longitude:81.8891, type:'industrial'),
  CityArea(cityName:'Prayagraj', name:'Jhusi',           latitude:25.4293, longitude:81.9013, type:'mixed'),
  CityArea(cityName:'Prayagraj', name:'Phaphamau',       latitude:25.5052, longitude:81.8524, type:'mixed'),
  CityArea(cityName:'Prayagraj', name:'Mumfordganj',     latitude:25.4358, longitude:81.8463, type:'residential'),
  // ── Meerut ─────────────────────────────────────────────────
  CityArea(cityName:'Meerut', name:'Cantonment',   latitude:28.9955, longitude:77.7129, type:'mixed'),
  CityArea(cityName:'Meerut', name:'Civil Lines',  latitude:29.0013, longitude:77.6983, type:'commercial'),
  CityArea(cityName:'Meerut', name:'Pallavpuram',  latitude:28.9612, longitude:77.7238, type:'residential'),
  CityArea(cityName:'Meerut', name:'Partapur',     latitude:28.9713, longitude:77.7512, type:'industrial'),
  CityArea(cityName:'Meerut', name:'Modipuram',    latitude:29.0487, longitude:77.7043, type:'industrial'),
  CityArea(cityName:'Meerut', name:'Shastri Nagar',latitude:28.9787, longitude:77.6899, type:'residential'),
  // ── Noida ──────────────────────────────────────────────────
  CityArea(cityName:'Noida', name:'Sector 18',   latitude:28.5697, longitude:77.3213, type:'commercial'),
  CityArea(cityName:'Noida', name:'Sector 62',   latitude:28.6257, longitude:77.3689, type:'commercial'),
  CityArea(cityName:'Noida', name:'Sector 137',  latitude:28.5023, longitude:77.3907, type:'residential'),
  CityArea(cityName:'Noida', name:'Greater Noida',latitude:28.4744,longitude:77.5040, type:'mixed'),
  CityArea(cityName:'Noida', name:'Dadri',        latitude:28.5523, longitude:77.5540, type:'industrial'),
  CityArea(cityName:'Noida', name:'Sector 10',   latitude:28.5849, longitude:77.3172, type:'residential'),
  // ── Haridwar ───────────────────────────────────────────────
  CityArea(cityName:'Haridwar', name:'Har Ki Pauri',  latitude:29.9583, longitude:78.1644, type:'mixed'),
  CityArea(cityName:'Haridwar', name:'Jwalapur',      latitude:29.9237, longitude:78.1504, type:'mixed'),
  CityArea(cityName:'Haridwar', name:'BHEL Ranipur',  latitude:29.9457, longitude:78.1642, type:'industrial'),
  CityArea(cityName:'Haridwar', name:'Roorkee',       latitude:29.8543, longitude:77.8880, type:'mixed'),
  CityArea(cityName:'Haridwar', name:'Laksar',        latitude:29.7503, longitude:78.0278, type:'industrial'),
  CityArea(cityName:'Haridwar', name:'Bahadrabad',    latitude:29.9097, longitude:78.2258, type:'industrial'),
  // ── Durgapur ───────────────────────────────────────────────
  CityArea(cityName:'Durgapur', name:'City Centre',   latitude:23.5204, longitude:87.3119, type:'commercial'),
  CityArea(cityName:'Durgapur', name:'Steel Township',latitude:23.5369, longitude:87.2982, type:'industrial'),
  CityArea(cityName:'Durgapur', name:'Bidhannagar',   latitude:23.5047, longitude:87.3241, type:'residential'),
  CityArea(cityName:'Durgapur', name:'Benachity',     latitude:23.5157, longitude:87.3371, type:'commercial'),
  CityArea(cityName:'Durgapur', name:'Andal',         latitude:23.5872, longitude:87.2059, type:'industrial'),
  CityArea(cityName:'Durgapur', name:'Mejia',         latitude:23.4981, longitude:87.1286, type:'industrial'),
  // ── Siliguri ───────────────────────────────────────────────
  CityArea(cityName:'Siliguri', name:'Sevoke Road',  latitude:26.7155, longitude:88.4234, type:'commercial'),
  CityArea(cityName:'Siliguri', name:'Hill Cart Road',latitude:26.7271, longitude:88.3953, type:'commercial'),
  CityArea(cityName:'Siliguri', name:'Matigara',     latitude:26.7625, longitude:88.3996, type:'mixed'),
  CityArea(cityName:'Siliguri', name:'Bagdogra',     latitude:26.6816, longitude:88.3282, type:'mixed'),
  CityArea(cityName:'Siliguri', name:'Dabgram',      latitude:26.7409, longitude:88.4085, type:'industrial'),
  CityArea(cityName:'Siliguri', name:'Naxalbari',    latitude:26.8570, longitude:88.2309, type:'industrial'),
  // ── Port Blair ─────────────────────────────────────────────
  CityArea(cityName:'Port Blair', name:'Aberdeen Bazar', latitude:11.6612, longitude:92.7363, type:'commercial'),
  CityArea(cityName:'Port Blair', name:'Haddo',          latitude:11.6782, longitude:92.7255, type:'mixed'),
  CityArea(cityName:'Port Blair', name:'Prothrapur',     latitude:11.6406, longitude:92.7058, type:'residential'),
  CityArea(cityName:'Port Blair', name:'Bambooflat',     latitude:11.5841, longitude:92.6898, type:'mixed'),
  CityArea(cityName:'Port Blair', name:'Dollygunj',      latitude:11.6258, longitude:92.7088, type:'residential'),
  CityArea(cityName:'Port Blair', name:'Beadnabad',      latitude:11.6532, longitude:92.7564, type:'industrial'),
  // ── Silvassa ───────────────────────────────────────────────
  CityArea(cityName:'Silvassa', name:'Naroli',       latitude:20.3003, longitude:73.0111, type:'industrial'),
  CityArea(cityName:'Silvassa', name:'Khadoli',      latitude:20.2921, longitude:73.0215, type:'industrial'),
  CityArea(cityName:'Silvassa', name:'Piparia',      latitude:20.2666, longitude:73.0169, type:'commercial'),
  CityArea(cityName:'Silvassa', name:'Amli',         latitude:20.2484, longitude:73.0288, type:'residential'),
  CityArea(cityName:'Silvassa', name:'Rakholi',      latitude:20.3258, longitude:73.0339, type:'industrial'),
  CityArea(cityName:'Silvassa', name:'Dadra',        latitude:20.2893, longitude:72.9748, type:'mixed'),
  // ── Daman ──────────────────────────────────────────────────
  CityArea(cityName:'Daman', name:'Daman Town',   latitude:20.4140, longitude:72.8328, type:'commercial'),
  CityArea(cityName:'Daman', name:'Moti Daman',   latitude:20.3974, longitude:72.8347, type:'mixed'),
  CityArea(cityName:'Daman', name:'Vapi',         latitude:20.3727, longitude:72.9081, type:'industrial'),
  CityArea(cityName:'Daman', name:'Bhimpore',     latitude:20.3831, longitude:72.8512, type:'residential'),
  CityArea(cityName:'Daman', name:'Somnath',      latitude:20.4237, longitude:72.8466, type:'residential'),
  CityArea(cityName:'Daman', name:'Kadaiya',      latitude:20.4052, longitude:72.8218, type:'industrial'),
  // ── Kavaratti ──────────────────────────────────────────────
  CityArea(cityName:'Kavaratti', name:'North Kavaratti', latitude:10.5660, longitude:72.6327, type:'residential'),
  CityArea(cityName:'Kavaratti', name:'South Kavaratti', latitude:10.5512, longitude:72.6363, type:'residential'),
  CityArea(cityName:'Kavaratti', name:'Harbour Area',    latitude:10.5593, longitude:72.6358, type:'commercial'),
  CityArea(cityName:'Kavaratti', name:'Agatti Island',   latitude:10.8610, longitude:72.1736, type:'mixed'),
  CityArea(cityName:'Kavaratti', name:'Minicoy',         latitude:8.2978,  longitude:73.0466, type:'mixed'),
  CityArea(cityName:'Kavaratti', name:'Kalpeni',         latitude:10.0893, longitude:73.6494, type:'mixed'),
  // ── Leh ────────────────────────────────────────────────────
  CityArea(cityName:'Leh', name:'Main Bazar',   latitude:34.1648, longitude:77.5847, type:'commercial'),
  CityArea(cityName:'Leh', name:'Changspa',     latitude:34.1577, longitude:77.5673, type:'residential'),
  CityArea(cityName:'Leh', name:'Shyok',        latitude:34.2105, longitude:77.5782, type:'mixed'),
  CityArea(cityName:'Leh', name:'Choglamsar',   latitude:34.1203, longitude:77.5837, type:'mixed'),
  CityArea(cityName:'Leh', name:'Spituk',       latitude:34.1424, longitude:77.5336, type:'industrial'),
  CityArea(cityName:'Leh', name:'Kargil',       latitude:34.5539, longitude:76.1349, type:'commercial'),
];

// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
// CustomLocation — a geocoded result that isn't in the static list
// ─────────────────────────────────────────────────────────────
class CustomLocation {
  final String displayName;   // "Connaught Place, New Delhi, Delhi"
  final String shortLabel;    // "Connaught Place"
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final bool   isGps;         // true when obtained from device GPS

  const CustomLocation({
    required this.displayName,
    required this.shortLabel,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.isGps = false,
  });

  String get locationLabel => shortLabel.isNotEmpty ? shortLabel : displayName;
}

// Provider
// ─────────────────────────────────────────────────────────────
class LocationProvider extends ChangeNotifier {
  static const _prefKeyCity       = 'selected_city_name';
  static const _prefKeyArea       = 'selected_area_name';
  static const _prefKeyCustomLat  = 'custom_lat';
  static const _prefKeyCustomLon  = 'custom_lon';
  static const _prefKeyCustomName = 'custom_name';

  AqiCity         _selectedCity      = kSupportedCities.first;
  CityArea?       _selectedArea;
  CustomLocation? _customLocation;     // set when user picks a geocoded result
  bool            _isGpsLoading = false;

  String    _citySearchQuery = '';
  String    _areaSearchQuery = '';
  bool      _isListeningMic  = false;
  String    _micStatus       = '';
  String?   _voiceError;

  // ── Getters ────────────────────────────────────────────────
  AqiCity         get selectedCity    => _selectedCity;
  CityArea?       get selectedArea    => _selectedArea;
  CustomLocation? get customLocation  => _customLocation;
  bool            get isGpsLoading    => _isGpsLoading;

  /// True when a geocoded/GPS location overrides the static city list.
  bool get isCustomLocation => _customLocation != null;

  /// Effective coordinates — custom → area → city, in priority order.
  double get latitude {
    if (_customLocation != null) return _customLocation!.latitude;
    return _selectedArea?.latitude ?? _selectedCity.latitude;
  }

  double get longitude {
    if (_customLocation != null) return _customLocation!.longitude;
    return _selectedArea?.longitude ?? _selectedCity.longitude;
  }

  bool   get isAreaSelected => _selectedArea != null && _customLocation == null;

  /// Human-readable label for the active location.
  String get locationLabel {
    if (_customLocation != null) return _customLocation!.locationLabel;
    if (_selectedArea   != null) {
      return '${_selectedArea!.name}, ${_selectedCity.name}';
    }
    return _selectedCity.name;
  }

  String  get citySearchQuery => _citySearchQuery;
  String  get areaSearchQuery => _areaSearchQuery;
  bool    get isListeningMic  => _isListeningMic;
  String  get micStatus       => _micStatus;
  String? get voiceError      => _voiceError;

  List<AqiCity>  get cities => kSupportedCities;

  List<CityArea> get areasForSelectedCity =>
      kCityAreas.where((a) => a.cityName == _selectedCity.name).toList();

  List<CityArea> get filteredAreas {
    final all = areasForSelectedCity;
    if (_areaSearchQuery.trim().isEmpty) return all;
    final q = _areaSearchQuery.toLowerCase().trim();
    final scored = all.map((a) {
      final n = a.name.toLowerCase();
      int s = 0;
      if (n == q) {
        s = 100;
      } else if (n.startsWith(q)) {
        s = 80;
      } else if (n.contains(q)) {
        s = 50;
      } else if (a.type.contains(q)) {
        s = 20;
      }
      return _ScoredArea(a, s);
    }).where((x) => x.score > 0).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.map((x) => x.area).toList();
  }

  List<AqiCity> get filteredCities {
    if (_citySearchQuery.trim().isEmpty) return kSupportedCities;
    final q = _citySearchQuery.toLowerCase().trim();
    final scored = kSupportedCities.map((c) {
      int score = 0;
      final name  = c.name.toLowerCase();
      final state = c.state.toLowerCase();
      if (name == q) {
        score = 100;
      } else if (name.startsWith(q)) {
        score = 80;
      } else if (name.contains(q)) {
        score = 50;
      } else if (state.contains(q)) {
        score = 30;
      }
      return _ScoredCity(c, score);
    }).where((s) => s.score > 0).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.city).toList();
  }

  LocationProvider() { _restoreSelection(); }

  Future<void> _restoreSelection() async {
    try {
      final prefs    = await SharedPreferences.getInstance();
      final cityName = prefs.getString(_prefKeyCity);
      final areaName = prefs.getString(_prefKeyArea);
      final customLat  = prefs.getDouble(_prefKeyCustomLat);
      final customLon  = prefs.getDouble(_prefKeyCustomLon);
      final customName = prefs.getString(_prefKeyCustomName);

      if (customLat != null && customLon != null && customName != null
          && customName.isNotEmpty) {
        _customLocation = CustomLocation(
          displayName: customName,
          shortLabel : customName.split(',').first.trim(),
          city       : '',
          state      : '',
          latitude   : customLat,
          longitude  : customLon,
        );
      } else if (cityName != null) {
        final match = kSupportedCities.where((c) => c.name == cityName).firstOrNull;
        if (match != null) { _selectedCity = match; }
        if (areaName != null && areaName.isNotEmpty) {
          final areaMatch = kCityAreas.where(
            (a) => a.cityName == _selectedCity.name && a.name == areaName,
          ).firstOrNull;
          _selectedArea = areaMatch;
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistSelection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customLocation != null) {
        await prefs.setDouble(_prefKeyCustomLat,  _customLocation!.latitude);
        await prefs.setDouble(_prefKeyCustomLon,  _customLocation!.longitude);
        await prefs.setString(_prefKeyCustomName, _customLocation!.displayName);
        await prefs.remove(_prefKeyCity);
        await prefs.remove(_prefKeyArea);
      } else {
        await prefs.remove(_prefKeyCustomLat);
        await prefs.remove(_prefKeyCustomLon);
        await prefs.remove(_prefKeyCustomName);
        await prefs.setString(_prefKeyCity, _selectedCity.name);
        await prefs.setString(_prefKeyArea, _selectedArea?.name ?? '');
      }
    } catch (_) {}
  }

  // ── Select from static city list ──────────────────────────
  Future<void> selectCity(AqiCity city) async {
    if (city == _selectedCity && _selectedArea == null
        && _customLocation == null) {
      return;
    }
    _selectedCity    = city;
    _selectedArea    = null;
    _customLocation  = null;
    _areaSearchQuery = '';
    notifyListeners();
    await _persistSelection();
  }

  Future<void> selectArea(CityArea area) async {
    if (area == _selectedArea) return;
    _selectedArea   = area;
    _customLocation = null;
    notifyListeners();
    await _persistSelection();
  }

  Future<void> clearArea() async {
    if (_selectedArea == null) return;
    _selectedArea = null;
    notifyListeners();
    await _persistSelection();
  }

  // ── Set a geocoded / GPS location ──────────────────────────
  /// Sets a custom location from Nominatim geocoding or GPS.
  /// This overrides city/area selection.
  Future<void> setCustomLocation(CustomLocation loc) async {
    _customLocation  = loc;
    _selectedArea    = null;
    notifyListeners();
    await _persistSelection();
  }

  /// Clears the custom location and reverts to the static city/area.
  Future<void> clearCustomLocation() async {
    if (_customLocation == null) return;
    _customLocation = null;
    notifyListeners();
    await _persistSelection();
  }

  // ── GPS location ──────────────────────────────────────────
  /// Requests device GPS location, reverse-geocodes it via Nominatim,
  /// and sets a [CustomLocation].
  /// Returns an error string on failure, or null on success.
  Future<String?> useGpsLocation() async {
    _isGpsLoading = true; notifyListeners();
    try {
      // Import geolocator at call site to avoid compile errors on unsupported platforms
      final pos = await _getGpsPosition();
      if (pos == null) {
        _isGpsLoading = false; notifyListeners();
        return 'Location permission denied or GPS unavailable.';
      }
      // Reverse geocode
      final result = await GeocodingService.reverse(pos.latitude, pos.longitude);
      if (result == null) {
        _isGpsLoading = false; notifyListeners();
        return 'Could not identify your location. Check if you are in India.';
      }
      await setCustomLocation(CustomLocation(
        displayName : result.displayName,
        shortLabel  : result.shortName,
        city        : result.city,
        state       : result.state,
        latitude    : pos.latitude,
        longitude   : pos.longitude,
        isGps       : true,
      ));
      _isGpsLoading = false; notifyListeners();
      return null; // success
    } catch (e) {
      _isGpsLoading = false; notifyListeners();
      return 'GPS error: $e';
    }
  }

  Future<GpsCoordinates?> _getGpsPosition() async {
    return GeolocatorHelper.getCurrentPosition();
  }

  void setCitySearchQuery(String q) { _citySearchQuery = q; notifyListeners(); }
  void clearCitySearch()             { _citySearchQuery = ''; notifyListeners(); }
  // Back-compat
  void setSearchQuery(String q) => setCitySearchQuery(q);
  void clearSearch()             => clearCitySearch();
  String get searchQuery         => _citySearchQuery;

  void setAreaSearchQuery(String q) { _areaSearchQuery = q; notifyListeners(); }
  void clearAreaSearch()             { _areaSearchQuery = ''; notifyListeners(); }

  void setMicListening(bool listening) {
    _isListeningMic = listening;
    _micStatus      = listening ? 'listening' : '';
    _voiceError     = null;
    notifyListeners();
  }

  void setMicError(String message) {
    _isListeningMic = false;
    _micStatus      = 'error';
    _voiceError     = message;
    notifyListeners();
  }

  void clearMicError() { _voiceError = null; _micStatus = ''; notifyListeners(); }

  AqiCity? resolveLocation(String text) {
    if (text.trim().isEmpty) return null;
    final q = text.toLowerCase().trim();
    final cleaned = q.replaceAll(
        RegExp(r'\b(city|of|in|the|air|quality|for|show|select|weather)\b'), '').trim();
    int bestScore = 0;
    AqiCity? bestCity;
    for (final city in kSupportedCities) {
      final name  = city.name.toLowerCase();
      final state = city.state.toLowerCase();
      int score = 0;
      if (name == cleaned || name == q) {
        score = 100;
      } else if (name.startsWith(cleaned) || name.startsWith(q)) {
        score = 85;
      } else if (name.contains(cleaned) || name.contains(q)) {
        score = 60;
      } else if (state.contains(cleaned) || state.contains(q)) {
        score = 40;
      }
      if (score > bestScore) { bestScore = score; bestCity = city; }
    }
    return bestScore >= 30 ? bestCity : null;
  }

  CityArea? resolveArea(String text) {
    if (text.trim().isEmpty) return null;
    final q = text.toLowerCase().trim();
    final cleaned = q.replaceAll(
        RegExp(r'\b(area|locality|zone|sector|nagar|road|in|the|of|for)\b'), '').trim();
    final areas = areasForSelectedCity;
    int bestScore = 0;
    CityArea? bestArea;
    for (final area in areas) {
      final name = area.name.toLowerCase();
      int score = 0;
      if (name == cleaned || name == q) {
        score = 100;
      } else if (name.startsWith(cleaned) || name.startsWith(q)) {
        score = 85;
      } else if (name.contains(cleaned) || name.contains(q)) {
        score = 60;
      }
      if (score > bestScore) { bestScore = score; bestArea = area; }
    }
    return bestScore >= 30 ? bestArea : null;
  }

  Future<bool> handleVoiceResult(String recognizedText) async {
    _isListeningMic = false; _micStatus = ''; notifyListeners();
    final city = resolveLocation(recognizedText);
    if (city != null) { await selectCity(city); return true; }
    _voiceError = 'Could not find "$recognizedText". Try a city name like "Mumbai".';
    notifyListeners();
    return false;
  }

  Future<bool> handleAreaVoiceResult(String recognizedText) async {
    _isListeningMic = false; _micStatus = ''; notifyListeners();
    final area = resolveArea(recognizedText);
    if (area != null) { await selectArea(area); return true; }
    _voiceError =
        'Could not find "$recognizedText" in ${_selectedCity.name}. '
        'Try an area name like "Andheri".';
    notifyListeners();
    return false;
  }
}

// ─────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────
class _ScoredCity {
  final AqiCity city;
  final int     score;
  const _ScoredCity(this.city, this.score);
}

class _ScoredArea {
  final CityArea area;
  final int      score;
  const _ScoredArea(this.area, this.score);
}

// Back-compat alias kept for any older imports that might reference _Scored
// ignore: unused_element
typedef _Scored = _ScoredCity;

