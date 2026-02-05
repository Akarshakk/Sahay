import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/widgets/document_upload_widget.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../providers/auth_provider.dart';

/// Citizen/Volunteer Registration Form Screen
class CitizenVolunteerRegistrationScreen extends ConsumerStatefulWidget {
  final UserRole userRole;
  final String phoneNumber;
  final String? verifiedEmail;

  const CitizenVolunteerRegistrationScreen({
    super.key,
    required this.userRole,
    required this.phoneNumber,
    this.verifiedEmail,
  });

  @override
  ConsumerState<CitizenVolunteerRegistrationScreen> createState() =>
      _CitizenVolunteerRegistrationScreenState();
}

class _CitizenVolunteerRegistrationScreenState
    extends ConsumerState<CitizenVolunteerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _professionController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Location selection
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedCity;
  List<String> _availableDistricts = [];
  List<String> _availableCities = [];

  // Indian States and their districts/cities
  static const Map<String, Map<String, List<String>>> _indianLocations = {
    'Andhra Pradesh': {
      'Anantapur': ['Anantapur', 'Dharmavaram', 'Hindupur', 'Kadiri', 'Tadipatri'],
      'Chittoor': ['Chittoor', 'Tirupati', 'Madanapalle', 'Srikalahasti', 'Punganur'],
      'East Godavari': ['Kakinada', 'Rajahmundry', 'Amalapuram', 'Samalkot', 'Peddapuram'],
      'Guntur': ['Guntur', 'Tenali', 'Mangalagiri', 'Narasaraopet', 'Bapatla'],
      'Krishna': ['Vijayawada', 'Machilipatnam', 'Gudivada', 'Nuzvid', 'Jaggaiahpet'],
      'Kurnool': ['Kurnool', 'Nandyal', 'Adoni', 'Yemmiganur', 'Atmakur'],
      'Nellore': ['Nellore', 'Kavali', 'Gudur', 'Venkatagiri', 'Atmakur'],
      'Prakasam': ['Ongole', 'Markapur', 'Chirala', 'Kandukur', 'Giddalur'],
      'Srikakulam': ['Srikakulam', 'Palasa', 'Tekkali', 'Amadalavalasa', 'Rajam'],
      'Visakhapatnam': ['Visakhapatnam', 'Anakapalli', 'Bheemunipatnam', 'Narsipatnam', 'Yelamanchili'],
      'Vizianagaram': ['Vizianagaram', 'Bobbili', 'Parvathipuram', 'Rajam', 'Salur'],
      'West Godavari': ['Eluru', 'Bhimavaram', 'Tadepalligudem', 'Tanuku', 'Narsapur'],
      'YSR Kadapa': ['Kadapa', 'Proddatur', 'Rajampet', 'Pulivendla', 'Jammalamadugu'],
    },
    'Arunachal Pradesh': {
      'Itanagar Capital Complex': ['Itanagar', 'Naharlagun', 'Nirjuli', 'Banderdewa'],
      'Changlang': ['Changlang', 'Miao', 'Nampong', 'Bordumsa'],
      'East Kameng': ['Seppa', 'Pipu', 'Chayangtajo', 'Bameng'],
      'East Siang': ['Pasighat', 'Ruksin', 'Mebo', 'Namsing'],
      'Lohit': ['Tezu', 'Wakro', 'Sunpura', 'Chowkham'],
      'Papum Pare': ['Yupia', 'Balijan', 'Doimukh', 'Kimin'],
      'Tawang': ['Tawang', 'Jang', 'Lumla', 'Mukto'],
      'Tirap': ['Khonsa', 'Deomali', 'Lazu', 'Dadam'],
      'West Kameng': ['Bomdila', 'Dirang', 'Kalaktang', 'Rupa'],
      'West Siang': ['Aalo', 'Likabali', 'Basar', 'Darak'],
    },
    'Assam': {
      'Baksa': ['Mushalpur', 'Tamulpur', 'Salbari', 'Barama'],
      'Barpeta': ['Barpeta', 'Barpeta Road', 'Sarthebari', 'Howly'],
      'Cachar': ['Silchar', 'Lakhipur', 'Katigorah', 'Sonai'],
      'Darrang': ['Mangaldoi', 'Kharupetia', 'Sipajhar', 'Dalgaon'],
      'Dhubri': ['Dhubri', 'Gauripur', 'Bilasipara', 'Golokganj'],
      'Dibrugarh': ['Dibrugarh', 'Naharkatia', 'Chabua', 'Lahoal'],
      'Goalpara': ['Goalpara', 'Dudhnoi', 'Lakhipur', 'Krishnai'],
      'Golaghat': ['Golaghat', 'Bokakhat', 'Dergaon', 'Sarupathar'],
      'Jorhat': ['Jorhat', 'Mariani', 'Teok', 'Titabor'],
      'Kamrup': ['Guwahati', 'Amingaon', 'Rangia', 'Hajo'],
      'Kamrup Metropolitan': ['Guwahati', 'Dispur', 'Paltan Bazaar', 'Uzanbazar'],
      'Karbi Anglong': ['Diphu', 'Bokajan', 'Howraghat', 'Langsomepi'],
      'Karimganj': ['Karimganj', 'Badarpur', 'Patharkandi', 'Nilambazar'],
      'Kokrajhar': ['Kokrajhar', 'Gossaigaon', 'Bijni', 'Dotma'],
      'Lakhimpur': ['North Lakhimpur', 'Dhakuakhana', 'Ghilamara', 'Narayanpur'],
      'Nagaon': ['Nagaon', 'Hojai', 'Dhing', 'Samaguri'],
      'Nalbari': ['Nalbari', 'Tihu', 'Mukalmua', 'Barkhetri'],
      'Sivasagar': ['Sivasagar', 'Nazira', 'Gaurisagar', 'Demow'],
      'Sonitpur': ['Tezpur', 'Rangapara', 'Dhekiajuli', 'Biswanath Chariali'],
      'Tinsukia': ['Tinsukia', 'Digboi', 'Margherita', 'Doom Dooma'],
    },
    'Bihar': {
      'Araria': ['Araria', 'Forbesganj', 'Sikti', 'Jokihat'],
      'Arwal': ['Arwal', 'Kurtha', 'Kaler', 'Sonbhadra Banshi Suryapur'],
      'Aurangabad': ['Aurangabad', 'Obra', 'Rafiganj', 'Daudnagar'],
      'Banka': ['Banka', 'Amarpur', 'Rajoun', 'Barahat'],
      'Begusarai': ['Begusarai', 'Barauni', 'Teghra', 'Bakhri'],
      'Bhagalpur': ['Bhagalpur', 'Naugachhia', 'Sultanganj', 'Kahalgaon'],
      'Bhojpur': ['Arrah', 'Jagdishpur', 'Piro', 'Koilwar'],
      'Buxar': ['Buxar', 'Dumraon', 'Chausa', 'Rajpur'],
      'Darbhanga': ['Darbhanga', 'Benipur', 'Jale', 'Keoti'],
      'East Champaran': ['Motihari', 'Pakridayal', 'Raxaul', 'Dhaka'],
      'Gaya': ['Gaya', 'Bodh Gaya', 'Sherghati', 'Tekari'],
      'Gopalganj': ['Gopalganj', 'Hathua', 'Phulwaria', 'Barauli'],
      'Jamui': ['Jamui', 'Sikandra', 'Sono', 'Jhajha'],
      'Jehanabad': ['Jehanabad', 'Makhdumpur', 'Kako', 'Ghoshi'],
      'Kaimur': ['Bhabua', 'Mohania', 'Chainpur', 'Kudra'],
      'Katihar': ['Katihar', 'Barsoi', 'Manihari', 'Korha'],
      'Khagaria': ['Khagaria', 'Gogri', 'Alauli', 'Beldaur'],
      'Kishanganj': ['Kishanganj', 'Bahadurganj', 'Thakurganj', 'Pothia'],
      'Lakhisarai': ['Lakhisarai', 'Suryagarha', 'Halsi', 'Pipariya'],
      'Madhepura': ['Madhepura', 'Bihariganj', 'Singheshwar', 'Ghailar'],
      'Madhubani': ['Madhubani', 'Jhanjharpur', 'Benipatti', 'Phulparas'],
      'Munger': ['Munger', 'Jamalpur', 'Tarapur', 'Bariarpur'],
      'Muzaffarpur': ['Muzaffarpur', 'Kanti', 'Marwan', 'Gaighat'],
      'Nalanda': ['Bihar Sharif', 'Rajgir', 'Hilsa', 'Islampur'],
      'Nawada': ['Nawada', 'Rajauli', 'Akbarpur', 'Warisaliganj'],
      'Patna': ['Patna', 'Danapur', 'Phulwari Sharif', 'Khagaul'],
      'Purnia': ['Purnia', 'Banmankhi', 'Kasba', 'Baisi'],
      'Rohtas': ['Sasaram', 'Dehri', 'Bikramganj', 'Nokha'],
      'Saharsa': ['Saharsa', 'Simri Bakhtiarpur', 'Sonbarsa', 'Mahishi'],
      'Samastipur': ['Samastipur', 'Rosera', 'Dalsinghsarai', 'Patori'],
      'Saran': ['Chapra', 'Revelganj', 'Sonpur', 'Marhaura'],
      'Sheikhpura': ['Sheikhpura', 'Barbigha', 'Ariari', 'Chewara'],
      'Sheohar': ['Sheohar', 'Dumri Katsari', 'Piprahi', 'Purnahiya'],
      'Sitamarhi': ['Sitamarhi', 'Pupri', 'Dumra', 'Sonbarsa'],
      'Siwan': ['Siwan', 'Mairwa', 'Darauli', 'Raghunathpur'],
      'Supaul': ['Supaul', 'Birpur', 'Triveniganj', 'Nirmali'],
      'Vaishali': ['Hajipur', 'Lalganj', 'Mahua', 'Jandaha'],
      'West Champaran': ['Bettiah', 'Bagaha', 'Narkatiaganj', 'Chanpatia'],
    },
    'Chhattisgarh': {
      'Balod': ['Balod', 'Gunderdehi', 'Dondi', 'Lohara'],
      'Baloda Bazar': ['Baloda Bazar', 'Bhatapara', 'Simga', 'Kasdol'],
      'Balrampur': ['Balrampur', 'Rajpur', 'Wadrafnagar', 'Shankargarh'],
      'Bastar': ['Jagdalpur', 'Bastar', 'Lohandiguda', 'Tokapal'],
      'Bemetara': ['Bemetara', 'Berla', 'Saja', 'Nawagarh'],
      'Bijapur': ['Bijapur', 'Bhairamgarh', 'Usoor', 'Bhopalpatnam'],
      'Bilaspur': ['Bilaspur', 'Ratanpur', 'Takhatpur', 'Masturi'],
      'Dantewada': ['Dantewada', 'Geedam', 'Kuakonda', 'Katekalyan'],
      'Dhamtari': ['Dhamtari', 'Kurud', 'Nagri', 'Magarlod'],
      'Durg': ['Durg', 'Bhilai', 'Dhamdha', 'Patan'],
      'Gariaband': ['Gariaband', 'Chhura', 'Mainpur', 'Deobhog'],
      'Janjgir-Champa': ['Janjgir', 'Champa', 'Naila', 'Sakti'],
      'Jashpur': ['Jashpur', 'Kunkuri', 'Bagicha', 'Pathalgaon'],
      'Kabirdham': ['Kawardha', 'Bodla', 'Pandariya', 'Sahaspur Lohara'],
      'Kanker': ['Kanker', 'Antagarh', 'Bhanupratappur', 'Charama'],
      'Kondagaon': ['Kondagaon', 'Keshkal', 'Makdi', 'Pharasgaon'],
      'Korba': ['Korba', 'Katghora', 'Kartala', 'Poundi Uproda'],
      'Koriya': ['Baikunthpur', 'Manendragarh', 'Khadgawan', 'Sonhat'],
      'Mahasamund': ['Mahasamund', 'Saraipali', 'Bagbahra', 'Basna'],
      'Mungeli': ['Mungeli', 'Lormi', 'Patharia', 'Akaltara'],
      'Narayanpur': ['Narayanpur', 'Orchha', 'Chhotedongar', 'Abujhmarh'],
      'Raigarh': ['Raigarh', 'Sarangarh', 'Dharamjaigarh', 'Tamnar'],
      'Raipur': ['Raipur', 'Abhanpur', 'Arang', 'Tilda'],
      'Rajnandgaon': ['Rajnandgaon', 'Dongargarh', 'Chhuria', 'Khairagarh'],
      'Sukma': ['Sukma', 'Konta', 'Chindgarh', 'Dornapal'],
      'Surajpur': ['Surajpur', 'Pratappur', 'Premnagar', 'Odgi'],
      'Surguja': ['Ambikapur', 'Lakhanpur', 'Udaipur', 'Mainpat'],
    },
    'Goa': {
      'North Goa': ['Panaji', 'Mapusa', 'Vasco da Gama', 'Ponda', 'Bicholim', 'Pernem'],
      'South Goa': ['Margao', 'Mormugao', 'Quepem', 'Sanguem', 'Canacona', 'Cuncolim'],
    },
    'Gujarat': {
      'Ahmedabad': ['Ahmedabad', 'Dholka', 'Sanand', 'Viramgam', 'Mandal', 'Dhandhuka'],
      'Amreli': ['Amreli', 'Rajula', 'Savarkundla', 'Dhari', 'Jafrabad'],
      'Anand': ['Anand', 'Khambhat', 'Borsad', 'Petlad', 'Tarapur'],
      'Aravalli': ['Modasa', 'Malpur', 'Bayad', 'Dhansura', 'Bhiloda'],
      'Banaskantha': ['Palanpur', 'Deesa', 'Dhanera', 'Tharad', 'Radhanpur'],
      'Bharuch': ['Bharuch', 'Ankleshwar', 'Jambusar', 'Hansot', 'Amod'],
      'Bhavnagar': ['Bhavnagar', 'Mahuva', 'Palitana', 'Sihor', 'Gariadhar'],
      'Botad': ['Botad', 'Gadhada', 'Ranpur', 'Barwala'],
      'Chhota Udaipur': ['Chhota Udaipur', 'Sankheda', 'Bodeli', 'Jetpur Pavi', 'Naswadi'],
      'Dahod': ['Dahod', 'Devgadh Baria', 'Jhalod', 'Limkheda', 'Garbada'],
      'Dang': ['Ahwa', 'Waghai', 'Subir', 'Saputara'],
      'Devbhoomi Dwarka': ['Khambhalia', 'Dwarka', 'Kalyanpur', 'Bhanvad', 'Okha'],
      'Gandhinagar': ['Gandhinagar', 'Kalol', 'Mansa', 'Dehgam'],
      'Gir Somnath': ['Veraval', 'Una', 'Talala', 'Sutrapada', 'Kodinar'],
      'Jamnagar': ['Jamnagar', 'Dhrol', 'Jodia', 'Lalpur', 'Kalavad'],
      'Junagadh': ['Junagadh', 'Keshod', 'Mangrol', 'Visavadar', 'Mendarda'],
      'Kheda': ['Nadiad', 'Kapadvanj', 'Mehmedabad', 'Thasra', 'Matar'],
      'Kutch': ['Bhuj', 'Gandhidham', 'Mundra', 'Mandvi', 'Anjar'],
      'Mahisagar': ['Lunawada', 'Santrampur', 'Kadana', 'Balasinor'],
      'Mehsana': ['Mehsana', 'Visnagar', 'Kadi', 'Unjha', 'Vadnagar'],
      'Morbi': ['Morbi', 'Wankaner', 'Halvad', 'Tankara', 'Maliya'],
      'Narmada': ['Rajpipla', 'Sagbara', 'Nandod', 'Dediapada', 'Tilakwada'],
      'Navsari': ['Navsari', 'Billimora', 'Gandevi', 'Chikhli', 'Jalalpore'],
      'Panchmahal': ['Godhra', 'Halol', 'Kalol', 'Jambughoda', 'Shehera'],
      'Patan': ['Patan', 'Radhanpur', 'Chanasma', 'Siddhpur', 'Harij'],
      'Porbandar': ['Porbandar', 'Kutiyana', 'Ranavav'],
      'Rajkot': ['Rajkot', 'Gondal', 'Jetpur', 'Dhoraji', 'Upleta'],
      'Sabarkantha': ['Himmatnagar', 'Idar', 'Khedbrahma', 'Prantij', 'Talod'],
      'Surat': ['Surat', 'Bardoli', 'Mandvi', 'Mahuva', 'Kamrej'],
      'Surendranagar': ['Surendranagar', 'Wadhwan', 'Limdi', 'Chotila', 'Dhangadhra'],
      'Tapi': ['Vyara', 'Songadh', 'Ucchal', 'Valod', 'Nizar'],
      'Vadodara': ['Vadodara', 'Padra', 'Dabhoi', 'Karjan', 'Savli'],
      'Valsad': ['Valsad', 'Dharampur', 'Pardi', 'Umargam', 'Kaprada'],
    },
    'Haryana': {
      'Ambala': ['Ambala', 'Ambala Cantt', 'Barara', 'Saha', 'Naraingarh'],
      'Bhiwani': ['Bhiwani', 'Charkhi Dadri', 'Loharu', 'Siwani', 'Tosham'],
      'Faridabad': ['Faridabad', 'Ballabgarh', 'Tigaon', 'NIT Faridabad'],
      'Fatehabad': ['Fatehabad', 'Tohana', 'Ratia', 'Jakhal'],
      'Gurugram': ['Gurugram', 'Pataudi', 'Sohna', 'Farrukhnagar', 'Manesar'],
      'Hisar': ['Hisar', 'Hansi', 'Barwala', 'Adampur', 'Uklana'],
      'Jhajjar': ['Jhajjar', 'Bahadurgarh', 'Beri', 'Machhrauli'],
      'Jind': ['Jind', 'Narwana', 'Safidon', 'Julana', 'Uchana'],
      'Kaithal': ['Kaithal', 'Pundri', 'Cheeka', 'Kalayat', 'Guhla'],
      'Karnal': ['Karnal', 'Assandh', 'Nilokheri', 'Indri', 'Taraori'],
      'Kurukshetra': ['Kurukshetra', 'Thanesar', 'Pehowa', 'Shahbad', 'Ladwa'],
      'Mahendragarh': ['Narnaul', 'Mahendragarh', 'Ateli', 'Kanina', 'Nangal Chaudhry'],
      'Nuh': ['Nuh', 'Ferozepur Jhirka', 'Taoru', 'Punhana', 'Nagina'],
      'Palwal': ['Palwal', 'Hodal', 'Hathin', 'Hassanpur'],
      'Panchkula': ['Panchkula', 'Kalka', 'Raipur Rani', 'Morni', 'Barwala'],
      'Panipat': ['Panipat', 'Samalkha', 'Israna', 'Madlauda'],
      'Rewari': ['Rewari', 'Bawal', 'Kosli', 'Dharuhera', 'Nahar'],
      'Rohtak': ['Rohtak', 'Kalanaur', 'Meham', 'Lakhan Majra', 'Sampla'],
      'Sirsa': ['Sirsa', 'Dabwali', 'Ellenabad', 'Rania', 'Odhan'],
      'Sonipat': ['Sonipat', 'Gohana', 'Ganaur', 'Kharkhoda', 'Mundlana'],
      'Yamunanagar': ['Yamunanagar', 'Jagadhri', 'Chhachhrauli', 'Radaur', 'Bilaspur'],
    },
    'Himachal Pradesh': {
      'Bilaspur': ['Bilaspur', 'Ghumarwin', 'Naina Devi', 'Jhandutta', 'Swarghat'],
      'Chamba': ['Chamba', 'Dalhousie', 'Bharmour', 'Churah', 'Salooni'],
      'Hamirpur': ['Hamirpur', 'Nadaun', 'Barsar', 'Bijhari', 'Bhoranj'],
      'Kangra': ['Dharamshala', 'Kangra', 'Palampur', 'Nagrota Bagwan', 'Jawali'],
      'Kinnaur': ['Reckong Peo', 'Kalpa', 'Nichar', 'Sangla', 'Pooh'],
      'Kullu': ['Kullu', 'Manali', 'Bhuntar', 'Anni', 'Banjar'],
      'Lahaul and Spiti': ['Keylong', 'Kaza', 'Udaipur', 'Sissu', 'Tabo'],
      'Mandi': ['Mandi', 'Sundernagar', 'Jogindernagar', 'Karsog', 'Sarkaghat'],
      'Shimla': ['Shimla', 'Rampur', 'Rohru', 'Theog', 'Jubbal'],
      'Sirmaur': ['Nahan', 'Paonta Sahib', 'Rajgarh', 'Shillai', 'Renuka'],
      'Solan': ['Solan', 'Nalagarh', 'Baddi', 'Parwanoo', 'Kasauli'],
      'Una': ['Una', 'Amb', 'Bangana', 'Haroli', 'Gagret'],
    },
    'Jharkhand': {
      'Bokaro': ['Bokaro Steel City', 'Chas', 'Bermo', 'Gomia', 'Jaridih'],
      'Chatra': ['Chatra', 'Simaria', 'Hunterganj', 'Tandwa', 'Pratappur'],
      'Deoghar': ['Deoghar', 'Madhupur', 'Sarath', 'Mohanpur', 'Palojori'],
      'Dhanbad': ['Dhanbad', 'Jharia', 'Sindri', 'Katras', 'Nirsa'],
      'Dumka': ['Dumka', 'Jamtara', 'Shikaripara', 'Ramgarh', 'Gopikandar'],
      'East Singhbhum': ['Jamshedpur', 'Gamharia', 'Jugsalai', 'Mango', 'Potka'],
      'Garhwa': ['Garhwa', 'Nagar Untari', 'Ranka', 'Meral', 'Bhandaria'],
      'Giridih': ['Giridih', 'Deori', 'Pirtand', 'Bengabad', 'Bagodar'],
      'Godda': ['Godda', 'Mahagama', 'Boarijor', 'Pathargama', 'Poreyahat'],
      'Gumla': ['Gumla', 'Chainpur', 'Bishunpur', 'Raidih', 'Ghaghra'],
      'Hazaribagh': ['Hazaribagh', 'Barhi', 'Ichak', 'Daru', 'Bishnugarh'],
      'Jamtara': ['Jamtara', 'Nala', 'Kundhit', 'Fatehpur', 'Naryanpur'],
      'Khunti': ['Khunti', 'Murhu', 'Torpa', 'Karra', 'Arki'],
      'Koderma': ['Koderma', 'Satgawan', 'Markacho', 'Chandwara', 'Jainagar'],
      'Latehar': ['Latehar', 'Manika', 'Chandwa', 'Garu', 'Balumath'],
      'Lohardaga': ['Lohardaga', 'Kuru', 'Bhandra', 'Senha', 'Kisko'],
      'Pakur': ['Pakur', 'Hiranpur', 'Maheshpur', 'Amrapara', 'Pakuria'],
      'Palamu': ['Daltonganj', 'Medininagar', 'Hussainabad', 'Chainpur', 'Panki'],
      'Ramgarh': ['Ramgarh', 'Patratu', 'Mandu', 'Gola', 'Dulmi'],
      'Ranchi': ['Ranchi', 'Bundu', 'Kanke', 'Mandar', 'Ratu'],
      'Sahebganj': ['Sahebganj', 'Rajmahal', 'Borio', 'Barharwa', 'Taljhari'],
      'Seraikela Kharsawan': ['Seraikela', 'Kharsawan', 'Chandil', 'Adityapur', 'Gamharia'],
      'Simdega': ['Simdega', 'Bano', 'Kolebira', 'Thethaitangar', 'Kurdeg'],
      'West Singhbhum': ['Chaibasa', 'Chakradharpur', 'Jagannathpur', 'Sonua', 'Kumardungi'],
    },
    'Karnataka': {
      'Bagalkot': ['Bagalkot', 'Badami', 'Bilgi', 'Jamkhandi', 'Mudhol'],
      'Ballari': ['Ballari', 'Hospet', 'Siruguppa', 'Sandur', 'Kampli'],
      'Belagavi': ['Belagavi', 'Gokak', 'Athani', 'Chikodi', 'Khanapur'],
      'Bengaluru Rural': ['Devanahalli', 'Doddaballapura', 'Hosakote', 'Nelamangala'],
      'Bengaluru Urban': ['Bengaluru', 'Yelahanka', 'Bommanahalli', 'Anekal', 'Bangalore North'],
      'Bidar': ['Bidar', 'Humnabad', 'Basavakalyan', 'Bhalki', 'Aurad'],
      'Chamarajanagar': ['Chamarajanagar', 'Kollegal', 'Gundlupet', 'Yelandur'],
      'Chikkaballapura': ['Chikkaballapura', 'Chintamani', 'Sidlaghatta', 'Gowribidanur', 'Bagepalli'],
      'Chikkamagaluru': ['Chikkamagaluru', 'Kadur', 'Tarikere', 'Koppa', 'Mudigere'],
      'Chitradurga': ['Chitradurga', 'Davangere', 'Hiriyur', 'Challakere', 'Holalkere'],
      'Dakshina Kannada': ['Mangaluru', 'Bantwal', 'Puttur', 'Sullia', 'Belthangady'],
      'Davanagere': ['Davanagere', 'Harihar', 'Jagalur', 'Channagiri', 'Harapanahalli'],
      'Dharwad': ['Dharwad', 'Hubballi', 'Kundgol', 'Navalgund', 'Kalghatgi'],
      'Gadag': ['Gadag', 'Ron', 'Nargund', 'Mundargi', 'Shirahatti'],
      'Hassan': ['Hassan', 'Channarayapatna', 'Arkalgud', 'Holenarasipura', 'Sakleshpur'],
      'Haveri': ['Haveri', 'Ranebennur', 'Byadgi', 'Savanur', 'Shiggaon'],
      'Kalaburagi': ['Kalaburagi', 'Gulbarga', 'Aland', 'Jevargi', 'Sedam'],
      'Kodagu': ['Madikeri', 'Virajpet', 'Somwarpet', 'Kushalnagar'],
      'Kolar': ['Kolar', 'KGF', 'Malur', 'Bangarapet', 'Mulbagal'],
      'Koppal': ['Koppal', 'Gangavathi', 'Kustagi', 'Yelburga'],
      'Mandya': ['Mandya', 'Maddur', 'Malavalli', 'Pandavapura', 'Srirangapatna'],
      'Mysuru': ['Mysuru', 'Nanjangud', 'Hunsur', 'K R Nagar', 'T Narasipur'],
      'Raichur': ['Raichur', 'Sindhanur', 'Manvi', 'Lingasugur', 'Devadurga'],
      'Ramanagara': ['Ramanagara', 'Channapatna', 'Kanakapura', 'Magadi'],
      'Shivamogga': ['Shivamogga', 'Bhadravati', 'Sagar', 'Shikaripura', 'Thirthahalli'],
      'Tumakuru': ['Tumakuru', 'Tiptur', 'Sira', 'Madhugiri', 'Koratagere'],
      'Udupi': ['Udupi', 'Kundapura', 'Karkala', 'Brahmavara'],
      'Uttara Kannada': ['Karwar', 'Sirsi', 'Kumta', 'Ankola', 'Haliyal'],
      'Vijayapura': ['Vijayapura', 'Muddebihal', 'Sindagi', 'Indi', 'Basavana Bagewadi'],
      'Yadgir': ['Yadgir', 'Shahpur', 'Shorapur', 'Gurumitkal', 'Hunasagi'],
    },
    'Kerala': {
      'Alappuzha': ['Alappuzha', 'Cherthala', 'Kayamkulam', 'Haripad', 'Mavelikkara'],
      'Ernakulam': ['Kochi', 'Ernakulam', 'Aluva', 'Perumbavoor', 'Muvattupuzha'],
      'Idukki': ['Idukki', 'Thodupuzha', 'Adimali', 'Nedumkandam', 'Munnar'],
      'Kannur': ['Kannur', 'Thalassery', 'Payyanur', 'Iritty', 'Mattannur'],
      'Kasaragod': ['Kasaragod', 'Kanhangad', 'Nileshwaram', 'Manjeshwaram', 'Uppala'],
      'Kollam': ['Kollam', 'Karunagappally', 'Punalur', 'Kottarakkara', 'Paravur'],
      'Kottayam': ['Kottayam', 'Pala', 'Changanassery', 'Ettumanoor', 'Vaikom'],
      'Kozhikode': ['Kozhikode', 'Vadakara', 'Koyilandy', 'Ramanattukara', 'Feroke'],
      'Malappuram': ['Malappuram', 'Manjeri', 'Perinthalmanna', 'Tirur', 'Ponnani'],
      'Palakkad': ['Palakkad', 'Shornur', 'Ottapalam', 'Mannarkkad', 'Chittur'],
      'Pathanamthitta': ['Pathanamthitta', 'Adoor', 'Thiruvalla', 'Ranni', 'Konni'],
      'Thiruvananthapuram': ['Thiruvananthapuram', 'Neyyattinkara', 'Attingal', 'Varkala', 'Nedumangad'],
      'Thrissur': ['Thrissur', 'Kodungallur', 'Chalakudy', 'Irinjalakuda', 'Kunnamkulam'],
      'Wayanad': ['Kalpetta', 'Sulthan Bathery', 'Mananthavady', 'Vythiri'],
    },
    'Madhya Pradesh': {
      'Agar Malwa': ['Agar', 'Nalkheda', 'Barod', 'Susner'],
      'Alirajpur': ['Alirajpur', 'Jobat', 'Bhabra', 'Katthiwada', 'Sondwa'],
      'Anuppur': ['Anuppur', 'Pushprajgarh', 'Jaithari', 'Kotma'],
      'Ashoknagar': ['Ashoknagar', 'Chanderi', 'Mungaoli', 'Isagarh'],
      'Balaghat': ['Balaghat', 'Waraseoni', 'Katangi', 'Baihar', 'Lanji'],
      'Barwani': ['Barwani', 'Sendhwa', 'Pansemal', 'Rajpur', 'Niwali'],
      'Betul': ['Betul', 'Multai', 'Amla', 'Bhainsdehi', 'Chicholi'],
      'Bhind': ['Bhind', 'Lahar', 'Mehgaon', 'Ater', 'Gormi'],
      'Bhopal': ['Bhopal', 'Berasia', 'Huzur', 'Sehore', 'Phanda'],
      'Burhanpur': ['Burhanpur', 'Nepanagar', 'Khaknar', 'Shahpur'],
      'Chhindwara': ['Chhindwara', 'Pandhurna', 'Sausar', 'Parasia', 'Amarwara'],
      'Damoh': ['Damoh', 'Hatta', 'Patharia', 'Jabera', 'Batiyagarh'],
      'Datia': ['Datia', 'Seondha', 'Bhander', 'Indergarh'],
      'Dewas': ['Dewas', 'Sonkatch', 'Kannod', 'Khategaon', 'Bagli'],
      'Dhar': ['Dhar', 'Manawar', 'Sardarpur', 'Badnawar', 'Dahi'],
      'Dindori': ['Dindori', 'Shahpura', 'Bajag', 'Karanjia', 'Mehandwani'],
      'Guna': ['Guna', 'Raghogarh', 'Chachoda', 'Aron', 'Bamori'],
      'Gwalior': ['Gwalior', 'Dabra', 'Bhitarwar', 'Morar', 'Ghatigaon'],
      'Harda': ['Harda', 'Timarni', 'Khirkiya', 'Rahatgarh'],
      'Hoshangabad': ['Hoshangabad', 'Seoni Malwa', 'Pipariya', 'Sohagpur', 'Babai'],
      'Indore': ['Indore', 'Mhow', 'Depalpur', 'Sanwer', 'Gautampura'],
      'Jabalpur': ['Jabalpur', 'Sihora', 'Katni', 'Patan', 'Shahpura'],
      'Jhabua': ['Jhabua', 'Petlawad', 'Meghnagar', 'Ranapur', 'Thandla'],
      'Katni': ['Katni', 'Vijayraghavgarh', 'Bahoriband', 'Rithi', 'Barhi'],
      'Khandwa': ['Khandwa', 'Pandhana', 'Harsud', 'Mundi', 'Khalwa'],
      'Khargone': ['Khargone', 'Maheshwar', 'Kasrawad', 'Barwaha', 'Bhikangaon'],
      'Mandla': ['Mandla', 'Nainpur', 'Bichhiya', 'Niwas', 'Mawai'],
      'Mandsaur': ['Mandsaur', 'Neemuch', 'Garoth', 'Malhargarh', 'Sitamau'],
      'Morena': ['Morena', 'Ambah', 'Joura', 'Porsa', 'Sabalgarh'],
      'Narsinghpur': ['Narsinghpur', 'Gadarwara', 'Gotegaon', 'Kareli', 'Tendukheda'],
      'Neemuch': ['Neemuch', 'Manasa', 'Jawad', 'Singoli', 'Rampura'],
      'Panna': ['Panna', 'Ajaigarh', 'Pawai', 'Shahnagar', 'Gunour'],
      'Raisen': ['Raisen', 'Begamganj', 'Gairatganj', 'Sanchi', 'Silwani'],
      'Rajgarh': ['Rajgarh', 'Biaora', 'Khilchipur', 'Sarangpur', 'Narsinghgarh'],
      'Ratlam': ['Ratlam', 'Jaora', 'Alot', 'Sailana', 'Piploda'],
      'Rewa': ['Rewa', 'Sirmour', 'Tyonthar', 'Mauganj', 'Hanumana'],
      'Sagar': ['Sagar', 'Khurai', 'Bina', 'Banda', 'Rahatgarh'],
      'Satna': ['Satna', 'Maihar', 'Nagod', 'Amarpatan', 'Rampur Baghelan'],
      'Sehore': ['Sehore', 'Ashta', 'Ichhawar', 'Budni', 'Nasrullaganj'],
      'Seoni': ['Seoni', 'Barghat', 'Lakhnadon', 'Chhapara', 'Ghansore'],
      'Shahdol': ['Shahdol', 'Beohari', 'Burhar', 'Jaisinghnagar', 'Sohagpur'],
      'Shajapur': ['Shajapur', 'Shujalpur', 'Kalapipal', 'Maksi', 'Moman Badodia'],
      'Sheopur': ['Sheopur', 'Vijaypur', 'Karahal', 'Baroda'],
      'Shivpuri': ['Shivpuri', 'Pichhore', 'Pohari', 'Kolaras', 'Narwar'],
      'Sidhi': ['Sidhi', 'Churhat', 'Kusmi', 'Majhauli', 'Gopad Banas'],
      'Singrauli': ['Singrauli', 'Waidhan', 'Devsar', 'Chitrangi', 'Mada'],
      'Tikamgarh': ['Tikamgarh', 'Niwari', 'Prithvipur', 'Jatara', 'Palera'],
      'Ujjain': ['Ujjain', 'Nagda', 'Mahidpur', 'Tarana', 'Khachrod'],
      'Umaria': ['Umaria', 'Chandia', 'Pali', 'Karkeli', 'Manpur'],
      'Vidisha': ['Vidisha', 'Basoda', 'Sironj', 'Lateri', 'Nateran'],
    },
    'Maharashtra': {
      'Ahmednagar': ['Ahmednagar', 'Sangamner', 'Shrirampur', 'Newasa', 'Rahuri'],
      'Akola': ['Akola', 'Murtijapur', 'Balapur', 'Akot', 'Telhara'],
      'Amravati': ['Amravati', 'Achalpur', 'Morshi', 'Daryapur', 'Chandur Railway'],
      'Aurangabad': ['Aurangabad', 'Paithan', 'Kannad', 'Sillod', 'Vaijapur'],
      'Beed': ['Beed', 'Ambejogai', 'Parli', 'Gevrai', 'Majalgaon'],
      'Bhandara': ['Bhandara', 'Tumsar', 'Pauni', 'Mohadi', 'Sakoli'],
      'Buldhana': ['Buldhana', 'Chikhli', 'Khamgaon', 'Malkapur', 'Shegaon'],
      'Chandrapur': ['Chandrapur', 'Ballarpur', 'Warora', 'Rajura', 'Bramhapuri'],
      'Dhule': ['Dhule', 'Shirpur', 'Shindkheda', 'Sakri', 'Dondaicha'],
      'Gadchiroli': ['Gadchiroli', 'Aheri', 'Chamorshi', 'Armori', 'Kurkheda'],
      'Gondia': ['Gondia', 'Tirora', 'Goregaon', 'Arjuni Morgaon', 'Deori'],
      'Hingoli': ['Hingoli', 'Basmath', 'Sengaon', 'Kalamnuri', 'Aundha Nagnath'],
      'Jalgaon': ['Jalgaon', 'Bhusawal', 'Chalisgaon', 'Pachora', 'Erandol'],
      'Jalna': ['Jalna', 'Partur', 'Bhokardan', 'Jafrabad', 'Ambad'],
      'Kolhapur': ['Kolhapur', 'Ichalkaranji', 'Jaysingpur', 'Kagal', 'Gadhinglaj'],
      'Latur': ['Latur', 'Udgir', 'Nilanga', 'Ausa', 'Ahmedpur'],
      'Mumbai City': ['Mumbai', 'Colaba', 'Dadar', 'Byculla', 'Worli'],
      'Mumbai Suburban': ['Bandra', 'Andheri', 'Borivali', 'Mulund', 'Kurla'],
      'Nagpur': ['Nagpur', 'Kamptee', 'Hingna', 'Katol', 'Ramtek'],
      'Nanded': ['Nanded', 'Deglur', 'Mukhed', 'Hadgaon', 'Kinwat'],
      'Nandurbar': ['Nandurbar', 'Shahada', 'Taloda', 'Akkalkuwa', 'Dhadgaon'],
      'Nashik': ['Nashik', 'Malegaon', 'Deolali', 'Sinnar', 'Igatpuri'],
      'Osmanabad': ['Osmanabad', 'Tuljapur', 'Paranda', 'Bhum', 'Kalamb'],
      'Palghar': ['Palghar', 'Vasai', 'Dahanu', 'Boisar', 'Talasari'],
      'Parbhani': ['Parbhani', 'Pathri', 'Gangakhed', 'Jintur', 'Purna'],
      'Pune': ['Pune', 'Pimpri-Chinchwad', 'Baramati', 'Junnar', 'Shirur'],
      'Raigad': ['Alibag', 'Panvel', 'Khopoli', 'Pen', 'Mahad'],
      'Ratnagiri': ['Ratnagiri', 'Chiplun', 'Dapoli', 'Khed', 'Lanja'],
      'Sangli': ['Sangli', 'Miraj', 'Islampur', 'Vita', 'Tasgaon'],
      'Satara': ['Satara', 'Karad', 'Wai', 'Mahabaleshwar', 'Phaltan'],
      'Sindhudurg': ['Sindhudurg', 'Sawantwadi', 'Kudal', 'Malvan', 'Vengurla'],
      'Solapur': ['Solapur', 'Pandharpur', 'Barshi', 'Sangola', 'Akkalkot'],
      'Thane': ['Thane', 'Kalyan', 'Dombivli', 'Ulhasnagar', 'Bhiwandi'],
      'Wardha': ['Wardha', 'Arvi', 'Hinganghat', 'Deoli', 'Seloo'],
      'Washim': ['Washim', 'Risod', 'Mangrulpir', 'Malegaon', 'Karanja'],
      'Yavatmal': ['Yavatmal', 'Pusad', 'Wani', 'Darwha', 'Digras'],
    },
    'Manipur': {
      'Bishnupur': ['Bishnupur', 'Moirang', 'Nambol', 'Kumbi'],
      'Chandel': ['Chandel', 'Machi', 'Chakpikarong', 'Tengnoupal'],
      'Churachandpur': ['Churachandpur', 'Tuibong', 'Singngat', 'Tipaimukh'],
      'Imphal East': ['Porompat', 'Sawombung', 'Heingang', 'Keirao'],
      'Imphal West': ['Imphal', 'Lamphel', 'Wangoi', 'Sekmai'],
      'Jiribam': ['Jiribam', 'Borobekra', 'Tamenglong'],
      'Kakching': ['Kakching', 'Hiyanglam', 'Pallel', 'Waikhong'],
      'Kamjong': ['Kamjong', 'Phungyar', 'Chassad', 'Kasom'],
      'Kangpokpi': ['Kangpokpi', 'Saikul', 'Sadar Hills', 'Bungte'],
      'Noney': ['Noney', 'Longmai', 'Khoupum', 'Haochong'],
      'Pherzawl': ['Pherzawl', 'Tipaimukh', 'Thanlon'],
      'Senapati': ['Senapati', 'Kangpokpi', 'Mao', 'Maram'],
      'Tamenglong': ['Tamenglong', 'Nungba', 'Tousem', 'Khongsang'],
      'Tengnoupal': ['Tengnoupal', 'Moreh', 'Machi', 'Tujang'],
      'Thoubal': ['Thoubal', 'Lilong', 'Wangjing', 'Yairipok'],
      'Ukhrul': ['Ukhrul', 'Kamjong', 'Chingai', 'Phungyar'],
    },
    'Meghalaya': {
      'East Garo Hills': ['Williamnagar', 'Songsak', 'Samanda', 'Rongjeng'],
      'East Jaintia Hills': ['Khliehriat', 'Saipung', 'Sutnga'],
      'East Khasi Hills': ['Shillong', 'Sohra', 'Pynursla', 'Mawsynram'],
      'North Garo Hills': ['Resubelpara', 'Kharkutta', 'Bajengdoba'],
      'Ri Bhoi': ['Nongpoh', 'Umsning', 'Umling', 'Jirang'],
      'South Garo Hills': ['Baghmara', 'Gasuapara', 'Chokpot'],
      'South West Garo Hills': ['Ampati', 'Mahendraganj', 'Tikrikilla'],
      'South West Khasi Hills': ['Mawkyrwat', 'Ranikor', 'Nongstoin'],
      'West Garo Hills': ['Tura', 'Dadenggre', 'Phulbari', 'Selsella'],
      'West Jaintia Hills': ['Jowai', 'Laskein', 'Amlarem', 'Thadlaskein'],
      'West Khasi Hills': ['Nongstoin', 'Mairang', 'Mawshynrut'],
    },
    'Mizoram': {
      'Aizawl': ['Aizawl', 'Darlawn', 'Thingsulthliah', 'Phullen'],
      'Champhai': ['Champhai', 'Khawzawl', 'Biate', 'Ngopa'],
      'Hnahthial': ['Hnahthial', 'Thenzawl'],
      'Khawzawl': ['Khawzawl', 'Champhai'],
      'Kolasib': ['Kolasib', 'Bairabi', 'Bilkhawthlir'],
      'Lawngtlai': ['Lawngtlai', 'Chawngte', 'Sangau'],
      'Lunglei': ['Lunglei', 'Tlabung', 'Hnahthial'],
      'Mamit': ['Mamit', 'West Phaileng', 'Zawlnuam'],
      'Saiha': ['Saiha', 'Tuipang', 'Sangau'],
      'Saitual': ['Saitual', 'Phullen'],
      'Serchhip': ['Serchhip', 'Thenzawl', 'North Vanlaiphai'],
    },
    'Nagaland': {
      'Chümoukedima': ['Chümoukedima', 'Tuli', 'Dimapur'],
      'Dimapur': ['Dimapur', 'Chumukedima', 'Niuland', 'Dhansiripar'],
      'Kiphire': ['Kiphire', 'Pungro', 'Sitimi', 'Seyochung'],
      'Kohima': ['Kohima', 'Chiephobozou', 'Tseminyu', 'Jakhama'],
      'Longleng': ['Longleng', 'Tamlu', 'Sakshi'],
      'Mokokchung': ['Mokokchung', 'Tuli', 'Changtongya', 'Mangkolemba'],
      'Mon': ['Mon', 'Tobu', 'Chen', 'Aboi'],
      'Noklak': ['Noklak', 'Pangsha', 'Leangkonger'],
      'Peren': ['Peren', 'Jalukie', 'Athibung', 'Tening'],
      'Phek': ['Phek', 'Pfutsero', 'Chozuba', 'Meluri'],
      'Shamator': ['Shamator', 'Chare'],
      'Tuensang': ['Tuensang', 'Longleng', 'Noksen', 'Sangsangyu'],
      'Wokha': ['Wokha', 'Sanis', 'Bhandari', 'Wozhuro'],
      'Zunheboto': ['Zunheboto', 'Satakha', 'Aghunato', 'Akuluto'],
    },
    'Odisha': {
      'Angul': ['Angul', 'Talcher', 'Athmallik', 'Pallahara', 'Chhendipada'],
      'Balangir': ['Balangir', 'Kantabanji', 'Titilagarh', 'Patnagarh', 'Saintala'],
      'Balasore': ['Balasore', 'Soro', 'Jaleswar', 'Nilgiri', 'Basta'],
      'Bargarh': ['Bargarh', 'Padampur', 'Attabira', 'Bhatli', 'Ambabhona'],
      'Bhadrak': ['Bhadrak', 'Chandbali', 'Dhamnagar', 'Basudevpur', 'Bonth'],
      'Boudh': ['Boudh', 'Harabhanga', 'Kantamal', 'Manamunda'],
      'Cuttack': ['Cuttack', 'Choudwar', 'Athgarh', 'Banki', 'Baranga'],
      'Deogarh': ['Deogarh', 'Barkote', 'Reamal', 'Tileibani'],
      'Dhenkanal': ['Dhenkanal', 'Kamakhyanagar', 'Hindol', 'Parjang', 'Bhuban'],
      'Gajapati': ['Paralakhemundi', 'R. Udayagiri', 'Mohana', 'Kashinagara', 'Gumma'],
      'Ganjam': ['Berhampur', 'Chhatrapur', 'Gopalpur', 'Hinjili', 'Aska'],
      'Jagatsinghpur': ['Jagatsinghpur', 'Paradip', 'Kujang', 'Erasama', 'Tirtol'],
      'Jajpur': ['Jajpur', 'Jajpur Road', 'Chandikhol', 'Vyasanagar', 'Barchana'],
      'Jharsuguda': ['Jharsuguda', 'Brajarajnagar', 'Belpahar', 'Kirmira', 'Laikera'],
      'Kalahandi': ['Bhawanipatna', 'Kesinga', 'Dharmagarh', 'Junagarh', 'Lanjigarh'],
      'Kandhamal': ['Phulbani', 'G. Udayagiri', 'Baliguda', 'Tikabali', 'Chakapad'],
      'Kendrapara': ['Kendrapara', 'Pattamundai', 'Marshaghai', 'Aul', 'Rajnagar'],
      'Kendujhar': ['Kendujhar', 'Anandapur', 'Champua', 'Barbil', 'Joda'],
      'Khordha': ['Bhubaneswar', 'Khordha', 'Jatni', 'Balugaon', 'Banpur'],
      'Koraput': ['Koraput', 'Jeypore', 'Sunabeda', 'Kotpad', 'Laxmipur'],
      'Malkangiri': ['Malkangiri', 'Mathili', 'Korukonda', 'Kalimela', 'Kudumulugumma'],
      'Mayurbhanj': ['Baripada', 'Rairangpur', 'Karanjia', 'Udala', 'Betanati'],
      'Nabarangpur': ['Nabarangpur', 'Umerkote', 'Raighar', 'Dabugam', 'Jharigaon'],
      'Nayagarh': ['Nayagarh', 'Khandapara', 'Daspalla', 'Odagaon', 'Ranpur'],
      'Nuapada': ['Nuapada', 'Khariar', 'Komna', 'Sinapali', 'Boden'],
      'Puri': ['Puri', 'Konark', 'Pipili', 'Nimapara', 'Kakatpur'],
      'Rayagada': ['Rayagada', 'Gunupur', 'Muniguda', 'Padmapur', 'Bissam Cuttack'],
      'Sambalpur': ['Sambalpur', 'Burla', 'Hirakud', 'Kuchinda', 'Rengali'],
      'Subarnapur': ['Sonepur', 'Birmaharajpur', 'Dunguripali', 'Tarbha', 'Ullunda'],
      'Sundargarh': ['Sundargarh', 'Rourkela', 'Rajgangpur', 'Birmitrapur', 'Biramitrapur'],
    },
    'Punjab': {
      'Amritsar': ['Amritsar', 'Majitha', 'Ajnala', 'Baba Bakala', 'Verka'],
      'Barnala': ['Barnala', 'Tapa', 'Dhanaula', 'Mehal Kalan'],
      'Bathinda': ['Bathinda', 'Rampura Phul', 'Talwandi Sabo', 'Goniana', 'Sangat'],
      'Faridkot': ['Faridkot', 'Kotkapura', 'Jaitu', 'Bajakhana'],
      'Fatehgarh Sahib': ['Fatehgarh Sahib', 'Bassi Pathana', 'Amloh', 'Khamanon'],
      'Fazilka': ['Fazilka', 'Abohar', 'Jalalabad', 'Arniwala'],
      'Ferozepur': ['Ferozepur', 'Zira', 'Makhu', 'Guruharsahai', 'Talwandi Bhai'],
      'Gurdaspur': ['Gurdaspur', 'Batala', 'Pathankot', 'Dera Baba Nanak', 'Fatehgarh Churian'],
      'Hoshiarpur': ['Hoshiarpur', 'Dasuya', 'Mukerian', 'Tanda', 'Garhshankar'],
      'Jalandhar': ['Jalandhar', 'Nakodar', 'Phillaur', 'Shahkot', 'Adampur'],
      'Kapurthala': ['Kapurthala', 'Phagwara', 'Sultanpur Lodhi', 'Bhulath'],
      'Ludhiana': ['Ludhiana', 'Khanna', 'Jagraon', 'Samrala', 'Raikot'],
      'Mansa': ['Mansa', 'Sardulgarh', 'Budhlada', 'Jhunir', 'Bhikhi'],
      'Moga': ['Moga', 'Baghapurana', 'Dharamkot', 'Nihal Singh Wala'],
      'Mohali': ['Mohali', 'Kharar', 'Kurali', 'Derabassi', 'Lalru'],
      'Muktsar': ['Muktsar', 'Giddarbaha', 'Malout', 'Lambi'],
      'Pathankot': ['Pathankot', 'Sujanpur', 'Narot Jaimal Singh', 'Dhar Kalan'],
      'Patiala': ['Patiala', 'Rajpura', 'Nabha', 'Samana', 'Patran'],
      'Rupnagar': ['Rupnagar', 'Anandpur Sahib', 'Nangal', 'Morinda', 'Chamkaur Sahib'],
      'Sangrur': ['Sangrur', 'Malerkotla', 'Sunam', 'Dhuri', 'Lehragaga'],
      'Shaheed Bhagat Singh Nagar': ['Nawanshahr', 'Balachaur', 'Banga', 'Aur', 'Saroya'],
      'Tarn Taran': ['Tarn Taran', 'Patti', 'Khadoor Sahib', 'Bhikhiwind', 'Valtoha'],
    },
    'Rajasthan': {
      'Ajmer': ['Ajmer', 'Kishangarh', 'Beawar', 'Nasirabad', 'Pushkar'],
      'Alwar': ['Alwar', 'Bhiwadi', 'Behror', 'Rajgarh', 'Kishangarh Bas'],
      'Banswara': ['Banswara', 'Garhi', 'Bagidora', 'Kushalgarh', 'Ghatol'],
      'Baran': ['Baran', 'Atru', 'Chhipaborad', 'Kishanganj', 'Shahbad'],
      'Barmer': ['Barmer', 'Balotra', 'Siwana', 'Gudamalani', 'Pachpadra'],
      'Bharatpur': ['Bharatpur', 'Deeg', 'Kumher', 'Nadbai', 'Weir'],
      'Bhilwara': ['Bhilwara', 'Gangapur', 'Gulabpura', 'Mandal', 'Shahpura'],
      'Bikaner': ['Bikaner', 'Nokha', 'Lunkaransar', 'Kolayat', 'Dungargarh'],
      'Bundi': ['Bundi', 'Keshoraipatan', 'Nainwa', 'Indergarh', 'Hindoli'],
      'Chittorgarh': ['Chittorgarh', 'Nimbahera', 'Begun', 'Kapasan', 'Rashmi'],
      'Churu': ['Churu', 'Ratangarh', 'Sujangarh', 'Sardarshahar', 'Rajgarh'],
      'Dausa': ['Dausa', 'Lalsot', 'Bandikui', 'Sikrai', 'Baswa'],
      'Dholpur': ['Dholpur', 'Rajakhera', 'Bari', 'Baseri', 'Saipau'],
      'Dungarpur': ['Dungarpur', 'Sagwara', 'Aspur', 'Simalwara', 'Bichhiwara'],
      'Hanumangarh': ['Hanumangarh', 'Nohar', 'Bhadra', 'Pilibanga', 'Rawatsar'],
      'Jaipur': ['Jaipur', 'Sanganer', 'Chomu', 'Shahpura', 'Kotputli'],
      'Jaisalmer': ['Jaisalmer', 'Pokaran', 'Fatehgarh', 'Bhaniyana', 'Sam'],
      'Jalore': ['Jalore', 'Sanchore', 'Raniwara', 'Bhinmal', 'Ahore'],
      'Jhalawar': ['Jhalawar', 'Jhalrapatan', 'Pirawa', 'Aklera', 'Khanpur'],
      'Jhunjhunu': ['Jhunjhunu', 'Chirawa', 'Pilani', 'Nawalgarh', 'Udaipurwati'],
      'Jodhpur': ['Jodhpur', 'Phalodi', 'Bilara', 'Osian', 'Shergarh'],
      'Karauli': ['Karauli', 'Hindaun', 'Todabhim', 'Sapotra', 'Mandrayal'],
      'Kota': ['Kota', 'Ramganjmandi', 'Sangod', 'Sultanpur', 'Ladpura'],
      'Nagaur': ['Nagaur', 'Makrana', 'Merta', 'Ladnu', 'Didwana'],
      'Pali': ['Pali', 'Sojat', 'Marwar Junction', 'Sumerpur', 'Rohat'],
      'Pratapgarh': ['Pratapgarh', 'Chhotisadri', 'Arnod', 'Dhariawad', 'Peepalkhunt'],
      'Rajsamand': ['Rajsamand', 'Nathdwara', 'Kumbhalgarh', 'Amet', 'Bhim'],
      'Sawai Madhopur': ['Sawai Madhopur', 'Gangapur City', 'Bonli', 'Khandar', 'Bamanwas'],
      'Sikar': ['Sikar', 'Fatehpur', 'Lachhmangarh', 'Neem Ka Thana', 'Shri Madhopur'],
      'Sirohi': ['Sirohi', 'Abu Road', 'Pindwara', 'Reodar', 'Sheoganj'],
      'Sri Ganganagar': ['Sri Ganganagar', 'Suratgarh', 'Raisinghnagar', 'Anupgarh', 'Gharsana'],
      'Tonk': ['Tonk', 'Deoli', 'Niwai', 'Malpura', 'Uniara'],
      'Udaipur': ['Udaipur', 'Mavli', 'Kherwara', 'Salumber', 'Gogunda'],
    },
    'Sikkim': {
      'East Sikkim': ['Gangtok', 'Rangpo', 'Singtam', 'Rongli', 'Pakyong'],
      'North Sikkim': ['Mangan', 'Chungthang', 'Dzongu', 'Kabi', 'Phodong'],
      'South Sikkim': ['Namchi', 'Jorethang', 'Ravangla', 'Melli', 'Temi'],
      'West Sikkim': ['Gyalshing', 'Pelling', 'Soreng', 'Dentam', 'Yuksom'],
    },
    'Tamil Nadu': {
      'Ariyalur': ['Ariyalur', 'Jayankondam', 'Sendurai', 'Udayarpalayam', 'Andimadam'],
      'Chengalpattu': ['Chengalpattu', 'Mahabalipuram', 'Tambaram', 'Pallavaram', 'Vandalur'],
      'Chennai': ['Chennai', 'Perambur', 'Adyar', 'T. Nagar', 'Anna Nagar'],
      'Coimbatore': ['Coimbatore', 'Pollachi', 'Mettupalayam', 'Annur', 'Sulur'],
      'Cuddalore': ['Cuddalore', 'Chidambaram', 'Virudhachalam', 'Panruti', 'Nellikuppam'],
      'Dharmapuri': ['Dharmapuri', 'Hosur', 'Krishnagiri', 'Palacode', 'Pennagaram'],
      'Dindigul': ['Dindigul', 'Palani', 'Oddanchatram', 'Natham', 'Vedasandur'],
      'Erode': ['Erode', 'Gobichettipalayam', 'Bhavani', 'Perundurai', 'Sathyamangalam'],
      'Kallakurichi': ['Kallakurichi', 'Chinnasalem', 'Ulundurpet', 'Sankarapuram', 'Tirukovilur'],
      'Kancheepuram': ['Kancheepuram', 'Sriperumbudur', 'Uthiramerur', 'Kundrathur', 'Walajabad'],
      'Kanyakumari': ['Nagercoil', 'Marthandam', 'Colachel', 'Padmanabhapuram', 'Kuzhithurai'],
      'Karur': ['Karur', 'Kulithalai', 'Aravakurichi', 'Krishnarayapuram', 'Kadavur'],
      'Krishnagiri': ['Krishnagiri', 'Hosur', 'Denkanikottai', 'Pochampalli', 'Bargur'],
      'Madurai': ['Madurai', 'Melur', 'Vadipatti', 'Usilampatti', 'Thirumangalam'],
      'Mayiladuthurai': ['Mayiladuthurai', 'Sirkazhi', 'Tranquebar', 'Kuthalam', 'Kollidam'],
      'Nagapattinam': ['Nagapattinam', 'Velankanni', 'Kilvelur', 'Thirukkuvalai', 'Vedaranyam'],
      'Namakkal': ['Namakkal', 'Tiruchengode', 'Rasipuram', 'Kolli Hills', 'Paramathi Velur'],
      'Nilgiris': ['Ooty', 'Coonoor', 'Kotagiri', 'Gudalur', 'Wellington'],
      'Perambalur': ['Perambalur', 'Kunnam', 'Veppanthattai', 'Alathur'],
      'Pudukkottai': ['Pudukkottai', 'Aranthangi', 'Alangudi', 'Karambakudi', 'Thirumayam'],
      'Ramanathapuram': ['Ramanathapuram', 'Paramakudi', 'Rameswaram', 'Mandapam', 'Kamuthi'],
      'Ranipet': ['Ranipet', 'Arakkonam', 'Walajapet', 'Arcot', 'Sholingur'],
      'Salem': ['Salem', 'Mettur', 'Attur', 'Edappadi', 'Omalur'],
      'Sivaganga': ['Sivaganga', 'Karaikudi', 'Devakottai', 'Manamadurai', 'Tirupathur'],
      'Tenkasi': ['Tenkasi', 'Shenkottai', 'Sankarankovil', 'Kadayanallur', 'Alangulam'],
      'Thanjavur': ['Thanjavur', 'Kumbakonam', 'Pattukkottai', 'Orathanadu', 'Thiruvaiyaru'],
      'Theni': ['Theni', 'Periyakulam', 'Bodinayakkanur', 'Uthamapalayam', 'Andipatti'],
      'Thoothukudi': ['Thoothukudi', 'Kovilpatti', 'Tiruchendur', 'Eral', 'Kayalpattinam'],
      'Tiruchirappalli': ['Tiruchirappalli', 'Srirangam', 'Lalgudi', 'Musiri', 'Thuraiyur'],
      'Tirunelveli': ['Tirunelveli', 'Palayamkottai', 'Ambasamudram', 'Nanguneri', 'Cheranmahadevi'],
      'Tirupathur': ['Tirupathur', 'Vaniyambadi', 'Ambur', 'Natrampalli', 'Jolarpet'],
      'Tiruppur': ['Tiruppur', 'Avinashi', 'Palladam', 'Dharapuram', 'Udumalaipettai'],
      'Tiruvallur': ['Tiruvallur', 'Poonamallee', 'Avadi', 'Tiruttani', 'Ponneri'],
      'Tiruvannamalai': ['Tiruvannamalai', 'Polur', 'Chengam', 'Arani', 'Cheyyar'],
      'Tiruvarur': ['Tiruvarur', 'Mannargudi', 'Nannilam', 'Thiruthuraipoondi', 'Kodavasal'],
      'Vellore': ['Vellore', 'Gudiyattam', 'Katpadi', 'Anaicut', 'K.V. Kuppam'],
      'Viluppuram': ['Viluppuram', 'Tindivanam', 'Gingee', 'Kallakurichi', 'Sankarapuram'],
      'Virudhunagar': ['Virudhunagar', 'Sivakasi', 'Rajapalayam', 'Srivilliputhur', 'Aruppukkottai'],
    },
    'Telangana': {
      'Adilabad': ['Adilabad', 'Nirmal', 'Bhainsa', 'Jainath', 'Utnoor'],
      'Bhadradri Kothagudem': ['Kothagudem', 'Bhadrachalam', 'Sathupalli', 'Yellandu', 'Manuguru'],
      'Hyderabad': ['Hyderabad', 'Secunderabad', 'Begumpet', 'Ameerpet', 'Kukatpally'],
      'Jagtial': ['Jagtial', 'Dharmapuri', 'Koratla', 'Metpalli', 'Raikal'],
      'Jangaon': ['Jangaon', 'Station Ghanpur', 'Raghunathpalle', 'Lingalaghanpur'],
      'Jayashankar Bhupalpally': ['Bhupalpally', 'Mulugu', 'Kataram', 'Palimela', 'Venkatapuram'],
      'Jogulamba Gadwal': ['Gadwal', 'Alampur', 'Itikyal', 'Waddepally', 'Dharur'],
      'Kamareddy': ['Kamareddy', 'Yellareddy', 'Banswada', 'Domakonda', 'Madnoor'],
      'Karimnagar': ['Karimnagar', 'Jammikunta', 'Huzurabad', 'Choppadandi', 'Manakondur'],
      'Khammam': ['Khammam', 'Madhira', 'Wyra', 'Konijerla', 'Sathupalli'],
      'Komaram Bheem Asifabad': ['Asifabad', 'Sirpur', 'Kagaznagar', 'Wankdi', 'Koutala'],
      'Mahabubabad': ['Mahabubabad', 'Thorrur', 'Maripeda', 'Dornakal', 'Kesamudram'],
      'Mahabubnagar': ['Mahabubnagar', 'Shadnagar', 'Jadcherla', 'Wanaparthy', 'Narayanpet'],
      'Mancherial': ['Mancherial', 'Bellampalli', 'Ramakrishnapur', 'Luxettipet', 'Naspur'],
      'Medak': ['Medak', 'Narsapur', 'Toopran', 'Ramayampet', 'Havelighanpur'],
      'Medchal-Malkajgiri': ['Medchal', 'Malkajgiri', 'Secunderabad', 'Uppal', 'Kapra'],
      'Mulugu': ['Mulugu', 'Venkatapuram', 'Tadvai', 'Mangapet', 'Govindaraopet'],
      'Nagarkurnool': ['Nagarkurnool', 'Kollapur', 'Achampet', 'Kalwakurthy', 'Bijnapally'],
      'Nalgonda': ['Nalgonda', 'Miryalguda', 'Devarakonda', 'Suryapet', 'Kodad'],
      'Narayanpet': ['Narayanpet', 'Makthal', 'Marikal', 'Damaragidda', 'Narva'],
      'Nirmal': ['Nirmal', 'Bhainsa', 'Khanapur', 'Mudhole', 'Laxmanchanda'],
      'Nizamabad': ['Nizamabad', 'Armoor', 'Bodhan', 'Dichpally', 'Jakranpalle'],
      'Peddapalli': ['Peddapalli', 'Ramagundam', 'Godavarikhani', 'Manthani', 'Sultanabad'],
      'Rajanna Sircilla': ['Sircilla', 'Vemulawada', 'Mustabad', 'Gambhiraopet', 'Yellareddipet'],
      'Rangareddy': ['Rangareddy', 'Shamshabad', 'Chevella', 'Ibrahimpatnam', 'Rajendranagar'],
      'Sangareddy': ['Sangareddy', 'Zaheerabad', 'Jharasangam', 'Narayankhed', 'Patancheru'],
      'Siddipet': ['Siddipet', 'Gajwel', 'Dubbak', 'Husnabad', 'Thoguta'],
      'Suryapet': ['Suryapet', 'Kodad', 'Huzurnagar', 'Tungaturthi', 'Mattampalli'],
      'Vikarabad': ['Vikarabad', 'Tandur', 'Pargi', 'Basheerabad', 'Kodangal'],
      'Wanaparthy': ['Wanaparthy', 'Pebbair', 'Gopalpet', 'Peddamandadi', 'Kothakota'],
      'Warangal Rural': ['Warangal', 'Narsampet', 'Parkal', 'Ghanapur', 'Sangem'],
      'Warangal Urban': ['Warangal', 'Hanamkonda', 'Kazipet', 'Subedari', 'Hasanparthy'],
      'Yadadri Bhuvanagiri': ['Bhongir', 'Yadagirigutta', 'Choutuppal', 'Alair', 'Mothkur'],
    },
    'Tripura': {
      'Dhalai': ['Ambassa', 'Longtharai Valley', 'Gandacherra', 'Manu', 'Salema'],
      'Gomati': ['Udaipur', 'Amarpur', 'Karbook', 'Tepania', 'Silachari'],
      'Khowai': ['Khowai', 'Teliamura', 'Tulashikhar', 'Padmabil'],
      'North Tripura': ['Dharmanagar', 'Kanchanpur', 'Panisagar', 'Kadamtala', 'Damcherra'],
      'Sepahijala': ['Bishalgarh', 'Jirania', 'Boxanagar', 'Melaghar', 'Kathalia'],
      'South Tripura': ['Belonia', 'Sabroom', 'Santirbazar', 'Rajnagar', 'Matarbari'],
      'Unakoti': ['Kailashahar', 'Kumarghat', 'Pecharthal', 'Radhakishorepur'],
      'West Tripura': ['Agartala', 'Mohanpur', 'Mandai', 'Jirania', 'Dukli'],
    },
    'Uttar Pradesh': {
      'Agra': ['Agra', 'Firozabad', 'Fatehpur Sikri', 'Kiraoli', 'Shamsabad'],
      'Aligarh': ['Aligarh', 'Khair', 'Atrauli', 'Iglas', 'Gabhana'],
      'Allahabad': ['Prayagraj', 'Phulpur', 'Soraon', 'Handia', 'Karchhana'],
      'Ambedkar Nagar': ['Akbarpur', 'Tanda', 'Jalalpur', 'Alapur', 'Bhiti'],
      'Amethi': ['Amethi', 'Gauriganj', 'Tiloi', 'Salon', 'Jagdishpur'],
      'Amroha': ['Amroha', 'Gajraula', 'Hasanpur', 'Dhanaura', 'Joya'],
      'Auraiya': ['Auraiya', 'Bidhuna', 'Achalda', 'Ajitmal', 'Sahar'],
      'Ayodhya': ['Ayodhya', 'Faizabad', 'Rudauli', 'Bikapur', 'Milkipur'],
      'Azamgarh': ['Azamgarh', 'Mau', 'Phulpur', 'Lalganj', 'Sagri'],
      'Baghpat': ['Baghpat', 'Baraut', 'Khekra', 'Binauli', 'Pilana'],
      'Bahraich': ['Bahraich', 'Nanpara', 'Kaiserganj', 'Huzoorpur', 'Shravasti'],
      'Ballia': ['Ballia', 'Rasra', 'Sikanderpur', 'Bansdih', 'Nagra'],
      'Balrampur': ['Balrampur', 'Tulsipur', 'Utraula', 'Gaindas Bujurg', 'Pachperwa'],
      'Banda': ['Banda', 'Naraini', 'Baberu', 'Atarra', 'Kamasin'],
      'Barabanki': ['Barabanki', 'Fatehpur', 'Haidergarh', 'Ramsanehi Ghat', 'Sirauli Gauspur'],
      'Bareilly': ['Bareilly', 'Aonla', 'Faridpur', 'Baheri', 'Meerganj'],
      'Basti': ['Basti', 'Khalilabad', 'Harraiya', 'Gaur', 'Bhanpur'],
      'Bhadohi': ['Bhadohi', 'Gyanpur', 'Suriyawan', 'Aurai', 'Deegh'],
      'Bijnor': ['Bijnor', 'Najibabad', 'Nagina', 'Dhampur', 'Chandpur'],
      'Budaun': ['Budaun', 'Bilsi', 'Sahaswan', 'Dataganj', 'Gunnaur'],
      'Bulandshahr': ['Bulandshahr', 'Khurja', 'Sikandrabad', 'Jahangirabad', 'Shikarpur'],
      'Chandauli': ['Chandauli', 'Mughalsarai', 'Sakaldiha', 'Chahaniya', 'Naugarh'],
      'Chitrakoot': ['Chitrakoot', 'Karwi', 'Mau', 'Manikpur', 'Rajapur'],
      'Deoria': ['Deoria', 'Salempur', 'Bhatpar Rani', 'Padri', 'Pathardeva'],
      'Etah': ['Etah', 'Kasganj', 'Aliganj', 'Jalesar', 'Marehra'],
      'Etawah': ['Etawah', 'Jaswantnagar', 'Bharthana', 'Saifai', 'Basrehar'],
      'Farrukhabad': ['Fatehgarh', 'Farrukhabad', 'Kaimganj', 'Mohammadabad', 'Amritpur'],
      'Fatehpur': ['Fatehpur', 'Khaga', 'Bindki', 'Husainganj', 'Malwan'],
      'Firozabad': ['Firozabad', 'Shikohabad', 'Tundla', 'Jasrana', 'Eka'],
      'Gautam Buddha Nagar': ['Greater Noida', 'Noida', 'Dadri', 'Jewar', 'Bisrakh'],
      'Ghaziabad': ['Ghaziabad', 'Modinagar', 'Muradnagar', 'Hapur', 'Loni'],
      'Ghazipur': ['Ghazipur', 'Mohammadabad', 'Saidpur', 'Zamania', 'Karanda'],
      'Gonda': ['Gonda', 'Colonelganj', 'Nawabganj', 'Katra Bazar', 'Paraspur'],
      'Gorakhpur': ['Gorakhpur', 'Khorabar', 'Gola Bazar', 'Sahjanwa', 'Campierganj'],
      'Hamirpur': ['Hamirpur', 'Maudaha', 'Rath', 'Muskara', 'Kurara'],
      'Hapur': ['Hapur', 'Pilkhuwa', 'Dhaulana', 'Garhmukteshwar', 'Simbhaoli'],
      'Hardoi': ['Hardoi', 'Sandila', 'Shahabad', 'Bilgram', 'Pihani'],
      'Hathras': ['Hathras', 'Sikandra Rao', 'Sadabad', 'Sasni', 'Hasayan'],
      'Jalaun': ['Orai', 'Jalaun', 'Konch', 'Kalpi', 'Mahoba'],
      'Jaunpur': ['Jaunpur', 'Machhali Shahar', 'Mariahu', 'Shahganj', 'Badlapur'],
      'Jhansi': ['Jhansi', 'Lalitpur', 'Mauranipur', 'Moth', 'Chirgaon'],
      'Kannauj': ['Kannauj', 'Chhibramau', 'Tirwa', 'Talgram', 'Jalalabad'],
      'Kanpur Dehat': ['Akbarpur', 'Derapur', 'Rasulabad', 'Pukhrayan', 'Jhinjhak'],
      'Kanpur Nagar': ['Kanpur', 'Bilhaur', 'Ghatampur', 'Sarsaul', 'Bithoor'],
      'Kasganj': ['Kasganj', 'Sahawar', 'Patiyali', 'Soron', 'Amanpur'],
      'Kaushambi': ['Manjhanpur', 'Sirathu', 'Kaushambi', 'Chail', 'Mooratganj'],
      'Kushinagar': ['Kushinagar', 'Padrauna', 'Khadda', 'Hata', 'Ramkola'],
      'Lakhimpur Kheri': ['Lakhimpur', 'Gola Gokarnath', 'Oel', 'Pallia Kalan', 'Nighasan'],
      'Lalitpur': ['Lalitpur', 'Mehroni', 'Talbehat', 'Mahroni', 'Birdha'],
      'Lucknow': ['Lucknow', 'Mohanlalganj', 'Bakshi Ka Talab', 'Malihabad', 'Kakori'],
      'Maharajganj': ['Maharajganj', 'Nautanwa', 'Pharenda', 'Nichlaul', 'Siswa'],
      'Mahoba': ['Mahoba', 'Kulpahar', 'Charkhari', 'Panwari', 'Kabrai'],
      'Mainpuri': ['Mainpuri', 'Bhongaon', 'Shikohabad', 'Karhal', 'Kishni'],
      'Mathura': ['Mathura', 'Vrindavan', 'Kosikalan', 'Chhata', 'Mant'],
      'Mau': ['Mau', 'Ghosi', 'Muhammadabad', 'Kopaganj', 'Ratauli'],
      'Meerut': ['Meerut', 'Sardhana', 'Mawana', 'Daurala', 'Hastinapur'],
      'Mirzapur': ['Mirzapur', 'Chunar', 'Marihan', 'Lalganj', 'Ahraura'],
      'Moradabad': ['Moradabad', 'Chandausi', 'Sambhal', 'Kundarki', 'Thakurdwara'],
      'Muzaffarnagar': ['Muzaffarnagar', 'Shamli', 'Kairana', 'Budhana', 'Khatauli'],
      'Pilibhit': ['Pilibhit', 'Bisalpur', 'Puranpur', 'Barkhera', 'Marori'],
      'Pratapgarh': ['Pratapgarh', 'Kunda', 'Patti', 'Lalganj', 'Raniganj'],
      'Prayagraj': ['Prayagraj', 'Phulpur', 'Soraon', 'Handia', 'Karchhana'],
      'Rae Bareli': ['Rae Bareli', 'Lalganj', 'Salon', 'Dalmau', 'Unchahar'],
      'Rampur': ['Rampur', 'Bilaspur', 'Suar', 'Milak', 'Shahabad'],
      'Saharanpur': ['Saharanpur', 'Deoband', 'Gangoh', 'Rampur Maniharan', 'Nakur'],
      'Sambhal': ['Sambhal', 'Chandausi', 'Bahjoi', 'Gunnaur', 'Panwasa'],
      'Sant Kabir Nagar': ['Khalilabad', 'Mehdawal', 'Maghar', 'Baghauli', 'Hainsar Bazar'],
      'Shahjahanpur': ['Shahjahanpur', 'Tilhar', 'Powayan', 'Jalalabad', 'Khudaganj'],
      'Shamli': ['Shamli', 'Kairana', 'Un', 'Thanabhawan', 'Jhinjhana'],
      'Shravasti': ['Bhinga', 'Ikauna', 'Jamunaha', 'Sirsiya', 'Gilaula'],
      'Siddharthnagar': ['Naugarh', 'Itwa', 'Birdpur', 'Domariaganj', 'Uska'],
      'Sitapur': ['Sitapur', 'Biswan', 'Laharpur', 'Sidhauli', 'Misrikh'],
      'Sonbhadra': ['Robertsganj', 'Chopan', 'Obra', 'Renukoot', 'Dudhi'],
      'Sultanpur': ['Sultanpur', 'Kadipur', 'Dostpur', 'Lambhua', 'Baldirai'],
      'Unnao': ['Unnao', 'Shuklaganj', 'Bangarmau', 'Safipur', 'Purwa'],
      'Varanasi': ['Varanasi', 'Ramnagar', 'Cholapur', 'Pindra', 'Sewapuri'],
    },
    'Uttarakhand': {
      'Almora': ['Almora', 'Ranikhet', 'Bhowali', 'Dwarahat', 'Someshwar'],
      'Bageshwar': ['Bageshwar', 'Kapkot', 'Garur', 'Kanda'],
      'Chamoli': ['Chamoli', 'Joshimath', 'Karnaprayag', 'Gopeshwar', 'Pokhri'],
      'Champawat': ['Champawat', 'Lohaghat', 'Tanakpur', 'Pati', 'Barakot'],
      'Dehradun': ['Dehradun', 'Mussoorie', 'Rishikesh', 'Vikasnagar', 'Doiwala'],
      'Haridwar': ['Haridwar', 'Roorkee', 'Laksar', 'Jwalapur', 'Kankhal'],
      'Nainital': ['Nainital', 'Haldwani', 'Bhimtal', 'Mukteshwar', 'Ramnagar'],
      'Pauri Garhwal': ['Pauri', 'Kotdwar', 'Srinagar', 'Lansdowne', 'Satpuli'],
      'Pithoragarh': ['Pithoragarh', 'Berinag', 'Gangolihat', 'Dharchula', 'Munsyari'],
      'Rudraprayag': ['Rudraprayag', 'Ukhimath', 'Kedarnath', 'Augustmuni', 'Tilwara'],
      'Tehri Garhwal': ['New Tehri', 'Narendranagar', 'Chamba', 'Ghansali', 'Pratapnagar'],
      'Udham Singh Nagar': ['Rudrapur', 'Kashipur', 'Khatima', 'Sitarganj', 'Jaspur'],
      'Uttarkashi': ['Uttarkashi', 'Bhatwari', 'Gangotri', 'Yamunotri', 'Purola'],
    },
    'West Bengal': {
      'Alipurduar': ['Alipurduar', 'Madarihat', 'Falakata', 'Kalchini', 'Kumargram'],
      'Bankura': ['Bankura', 'Bishnupur', 'Sonamukhi', 'Kotulpur', 'Onda'],
      'Birbhum': ['Suri', 'Rampurhat', 'Bolpur', 'Nalhati', 'Sainthia'],
      'Cooch Behar': ['Cooch Behar', 'Dinhata', 'Mathabhanga', 'Tufanganj', 'Mekhliganj'],
      'Dakshin Dinajpur': ['Balurghat', 'Gangarampur', 'Buniadpur', 'Hili', 'Tapan'],
      'Darjeeling': ['Darjeeling', 'Siliguri', 'Kurseong', 'Kalimpong', 'Mirik'],
      'Hooghly': ['Hooghly', 'Chinsura', 'Chandannagar', 'Serampore', 'Dankuni'],
      'Howrah': ['Howrah', 'Uluberia', 'Shyampur', 'Amta', 'Bagnan'],
      'Jalpaiguri': ['Jalpaiguri', 'Mal', 'Rajganj', 'Maynaguri', 'Dhupguri'],
      'Jhargram': ['Jhargram', 'Nayagram', 'Gopiballavpur', 'Binpur', 'Jamboni'],
      'Kalimpong': ['Kalimpong', 'Pedong', 'Algarah', 'Gorubathan'],
      'Kolkata': ['Kolkata', 'Salt Lake', 'New Town', 'Behala', 'Tollygunge'],
      'Malda': ['Malda', 'Old Malda', 'Chanchal', 'Gazole', 'Ratua'],
      'Murshidabad': ['Berhampore', 'Jangipur', 'Domkal', 'Kandi', 'Lalbag'],
      'Nadia': ['Krishnanagar', 'Ranaghat', 'Nabadwip', 'Kalyani', 'Tehatta'],
      'North 24 Parganas': ['Barrackpore', 'Barasat', 'Dum Dum', 'Basirhat', 'Khardaha'],
      'Paschim Bardhaman': ['Durgapur', 'Asansol', 'Raniganj', 'Andal', 'Jamuria'],
      'Paschim Medinipur': ['Midnapore', 'Kharagpur', 'Ghatal', 'Debra', 'Chandrakona'],
      'Purba Bardhaman': ['Bardhaman', 'Kalna', 'Katwa', 'Memari', 'Manteswar'],
      'Purba Medinipur': ['Tamluk', 'Haldia', 'Contai', 'Egra', 'Mahishadal'],
      'Purulia': ['Purulia', 'Raghunathpur', 'Jhalda', 'Arsha', 'Balarampur'],
      'South 24 Parganas': ['Baruipur', 'Diamond Harbour', 'Kakdwip', 'Canning', 'Joynagar'],
      'Uttar Dinajpur': ['Raiganj', 'Islampur', 'Dalkhola', 'Kaliaganj', 'Hemtabad'],
    },
    'Andaman and Nicobar Islands': {
      'Nicobar': ['Car Nicobar', 'Nancowry', 'Campbell Bay', 'Katchal'],
      'North and Middle Andaman': ['Mayabunder', 'Diglipur', 'Rangat', 'Kalighat'],
      'South Andaman': ['Port Blair', 'Garacharma', 'Bamboo Flat', 'Prothrapur'],
    },
    'Chandigarh': {
      'Chandigarh': ['Chandigarh', 'Sector 17', 'Sector 22', 'Manimajra', 'Mohali Border'],
    },
    'Dadra and Nagar Haveli and Daman and Diu': {
      'Dadra and Nagar Haveli': ['Silvassa', 'Amli', 'Naroli', 'Khanvel'],
      'Daman': ['Daman', 'Moti Daman', 'Nani Daman', 'Devka'],
      'Diu': ['Diu', 'Ghoghla', 'Fudam', 'Nagoa'],
    },
    'Delhi': {
      'Central Delhi': ['Connaught Place', 'Karol Bagh', 'Daryaganj', 'Chandni Chowk', 'Paharganj'],
      'East Delhi': ['Preet Vihar', 'Laxmi Nagar', 'Mayur Vihar', 'Patparganj', 'Shahdara'],
      'New Delhi': ['New Delhi', 'Chanakyapuri', 'Lodhi Road', 'India Gate', 'Parliament Street'],
      'North Delhi': ['Civil Lines', 'Model Town', 'Pitampura', 'Rohini', 'Wazirpur'],
      'North East Delhi': ['Seelampur', 'Jaffrabad', 'Mustafabad', 'Bhajanpura', 'Gokulpuri'],
      'North West Delhi': ['Kanjhawala', 'Narela', 'Bawana', 'Sultanpuri', 'Mangolpuri'],
      'Shahdara': ['Shahdara', 'Vivek Vihar', 'Dilshad Garden', 'Anand Vihar', 'Karkardooma'],
      'South Delhi': ['Hauz Khas', 'Greater Kailash', 'Saket', 'Lajpat Nagar', 'Defence Colony'],
      'South East Delhi': ['Nehru Place', 'Kalkaji', 'Okhla', 'Jasola', 'Govindpuri'],
      'South West Delhi': ['Dwarka', 'Vasant Kunj', 'Najafgarh', 'Palam', 'Kapashera'],
      'West Delhi': ['Janakpuri', 'Rajouri Garden', 'Tilak Nagar', 'Vikaspuri', 'Uttam Nagar'],
    },
    'Jammu and Kashmir': {
      'Anantnag': ['Anantnag', 'Bijbehara', 'Pahalgam', 'Shangus', 'Mattan'],
      'Bandipora': ['Bandipora', 'Sumbal', 'Gurez', 'Sonawari', 'Hajin'],
      'Baramulla': ['Baramulla', 'Sopore', 'Pattan', 'Uri', 'Tangmarg'],
      'Budgam': ['Budgam', 'Chadoora', 'Khansahib', 'Beerwah', 'Magam'],
      'Doda': ['Doda', 'Bhaderwah', 'Ramban', 'Kishtwar', 'Thathri'],
      'Ganderbal': ['Ganderbal', 'Kangan', 'Lar', 'Gund', 'Wakura'],
      'Jammu': ['Jammu', 'Akhnoor', 'RS Pura', 'Bishnah', 'Marh'],
      'Kathua': ['Kathua', 'Hiranagar', 'Billawar', 'Basohli', 'Bani'],
      'Kishtwar': ['Kishtwar', 'Padder', 'Marwah', 'Warwan', 'Chatroo'],
      'Kulgam': ['Kulgam', 'DH Pora', 'Devsar', 'Qaimoh', 'Yaripora'],
      'Kupwara': ['Kupwara', 'Handwara', 'Karnah', 'Lolab', 'Kralpora'],
      'Poonch': ['Poonch', 'Surankote', 'Mendhar', 'Mandi', 'Haveli'],
      'Pulwama': ['Pulwama', 'Tral', 'Awantipora', 'Pampore', 'Kakapora'],
      'Rajouri': ['Rajouri', 'Nowshera', 'Sunderbani', 'Thanamandi', 'Budhal'],
      'Ramban': ['Ramban', 'Banihal', 'Batote', 'Gool', 'Khari'],
      'Reasi': ['Reasi', 'Katra', 'Arnas', 'Mahore', 'Chassana'],
      'Samba': ['Samba', 'Vijaypur', 'Ghagwal', 'Ramgarh', 'Bari Brahmana'],
      'Shopian': ['Shopian', 'Zainpora', 'Keegam', 'Hirpora', 'Chitragam'],
      'Srinagar': ['Srinagar', 'Khanyar', 'Hazratbal', 'Harwan', 'Rainawari'],
      'Udhampur': ['Udhampur', 'Chenani', 'Majalta', 'Ramnagar', 'Dudu'],
    },
    'Ladakh': {
      'Kargil': ['Kargil', 'Drass', 'Zanskar', 'Sankoo', 'Shakar Chiktan'],
      'Leh': ['Leh', 'Nubra', 'Khaltse', 'Diskit', 'Nyoma'],
    },
    'Lakshadweep': {
      'Lakshadweep': ['Kavaratti', 'Agatti', 'Minicoy', 'Amini', 'Andrott'],
    },
    'Puducherry': {
      'Karaikal': ['Karaikal', 'Kottucherry', 'Nedungadu', 'Thirunallar'],
      'Mahe': ['Mahe', 'Palloor', 'Chalakara'],
      'Puducherry': ['Puducherry', 'Ozhukarai', 'Villianur', 'Ariyankuppam', 'Bahour'],
      'Yanam': ['Yanam', 'Farampeta', 'Kanakalapeta'],
    },
  };

  // Volunteer area selection
  String? _selectedArea;
  String? _selectedAreaId;
  List<Map<String, dynamic>> _availableAreas = [];

  // Document upload
  String? _documentUrl;
  String? _documentType;

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumber.isNotEmpty) {
      _phoneController.text = widget.phoneNumber;
    }
    if (widget.verifiedEmail != null) {
      _emailController.text = widget.verifiedEmail!;
    }
    // Load available areas for volunteers
    if (widget.userRole == UserRole.volunteer) {
      _loadAvailableAreas();
    }
  }

  Future<void> _loadAvailableAreas() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('area_resources')
          .get();
      if (mounted) {
        setState(() {
          _availableAreas = snapshot.docs.map((doc) => {
            'areaId': doc.id,
            'areaName': doc.data()['areaName'] ?? doc.id,
          }).toList();
        });
      }
    } catch (e) {
      // Fallback areas if Firestore fails
      _availableAreas = [
        {'areaId': 'mumbai-central', 'areaName': 'Mumbai Central'},
        {'areaId': 'delhi-south', 'areaName': 'Delhi South'},
      ];
    }
  }

  void _onStateChanged(String? state) {
    setState(() {
      _selectedState = state;
      _selectedDistrict = null;
      _selectedCity = null;
      _availableDistricts = state != null ? (_indianLocations[state]?.keys.toList() ?? []) : [];
      _availableCities = [];
    });
  }

  void _onDistrictChanged(String? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedCity = null;
      _availableCities = (_selectedState != null && district != null)
          ? (_indianLocations[_selectedState]?[district] ?? [])
          : [];
    });
  }

  void _onCityChanged(String? city) {
    setState(() {
      _selectedCity = city;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _professionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.neutralGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.userRole == UserRole.citizen
              ? 'Citizen Registration'
              : 'Volunteer Registration',
          style: const TextStyle(
            color: AppTheme.neutralGray,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Role Badge
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.userRole == UserRole.citizen
                          ? AppTheme.citizenAccent.withValues(alpha: 0.1)
                          : AppTheme.volunteerAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.userRole == UserRole.citizen
                            ? AppTheme.citizenAccent
                            : AppTheme.volunteerAccent,
                      ),
                    ),
                    child: Text(
                      widget.userRole == UserRole.citizen
                          ? 'CITIZEN'
                          : 'VOLUNTEER',
                      style: TextStyle(
                        color: widget.userRole == UserRole.citizen
                            ? AppTheme.citizenAccent
                            : AppTheme.volunteerAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ).animate().fadeIn().scale(),

                const SizedBox(height: 32),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number *',
                    hintText: 'Enter 10-digit mobile number',
                    prefixIcon:
                        const Icon(Icons.phone, color: AppTheme.neutralGray),
                    prefixText: '+91 ',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 2),
                    ),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your mobile number';
                    }
                    if (value.length != 10) {
                      return 'Mobile number must be 10 digits';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Enter your full name',
                    prefixIcon:
                        const Icon(Icons.person, color: AppTheme.primaryRed),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Email
                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    hintText: 'Enter your email address',
                    prefixIcon:
                        const Icon(Icons.email, color: AppTheme.primaryRed),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Password
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    hintText: 'Create a password (min 6 characters)',
                    prefixIcon:
                        const Icon(Icons.lock, color: AppTheme.primaryRed),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.neutralGray,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !_isLoading,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.primaryRed),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.neutralGray,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Date of Birth
                InkWell(
                  onTap: _isLoading ? null : _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth *',
                      hintText: 'Select your date of birth',
                      prefixIcon: const Icon(Icons.calendar_today,
                          color: AppTheme.primaryRed),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryRed, width: 2),
                      ),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Select date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(
                        color: _selectedDate == null
                            ? AppTheme.neutralGray.withValues(alpha: 0.5)
                            : AppTheme.neutralGray,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Profession
                TextFormField(
                  controller: _professionController,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Profession *',
                    hintText: 'Enter your profession',
                    prefixIcon:
                        const Icon(Icons.work, color: AppTheme.primaryRed),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your profession';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // State Autocomplete
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _indianLocations.keys;
                    }
                    return _indianLocations.keys.where((state) =>
                        state.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    _onStateChanged(selection);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // Sync controller with selected state
                    if (_selectedState != null && controller.text != _selectedState) {
                      controller.text = _selectedState!;
                    }
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'State *',
                        hintText: 'Type to search state',
                        prefixIcon: const Icon(Icons.map, color: AppTheme.primaryRed),
                        suffixIcon: const Icon(Icons.arrow_drop_down, color: AppTheme.neutralGray),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _selectedState != null
                                  ? AppTheme.primaryRed
                                  : AppTheme.neutralGray.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryRed, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (_selectedState == null || _selectedState!.isEmpty) {
                          return 'Please select your state';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Clear selection if user types something different
                        if (_selectedState != null && value != _selectedState) {
                          setState(() {
                            _selectedState = null;
                            _selectedDistrict = null;
                            _selectedCity = null;
                            _availableDistricts = [];
                            _availableCities = [];
                          });
                        }
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                leading: const Icon(Icons.map, color: AppTheme.primaryRed, size: 20),
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 420.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // District Autocomplete
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (_availableDistricts.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    if (textEditingValue.text.isEmpty) {
                      return _availableDistricts;
                    }
                    return _availableDistricts.where((district) =>
                        district.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    _onDistrictChanged(selection);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // Sync controller with selected district
                    if (_selectedDistrict != null && controller.text != _selectedDistrict) {
                      controller.text = _selectedDistrict!;
                    } else if (_selectedDistrict == null && _selectedState != null && controller.text.isNotEmpty) {
                      controller.clear();
                    }
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: !_isLoading && _selectedState != null,
                      decoration: InputDecoration(
                        labelText: 'District *',
                        hintText: _selectedState == null ? 'Select state first' : 'Type to search district',
                        prefixIcon: const Icon(Icons.location_city, color: AppTheme.primaryRed),
                        suffixIcon: const Icon(Icons.arrow_drop_down, color: AppTheme.neutralGray),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _selectedDistrict != null
                                  ? AppTheme.primaryRed
                                  : AppTheme.neutralGray.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryRed, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (_selectedDistrict == null || _selectedDistrict!.isEmpty) {
                          return 'Please select your district';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Clear selection if user types something different
                        if (_selectedDistrict != null && value != _selectedDistrict) {
                          setState(() {
                            _selectedDistrict = null;
                            _selectedCity = null;
                            _availableCities = [];
                          });
                        }
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                leading: const Icon(Icons.location_city, color: AppTheme.primaryRed, size: 20),
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 440.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // City Autocomplete
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (_availableCities.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    if (textEditingValue.text.isEmpty) {
                      return _availableCities;
                    }
                    return _availableCities.where((city) =>
                        city.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    _onCityChanged(selection);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // Sync controller with selected city
                    if (_selectedCity != null && controller.text != _selectedCity) {
                      controller.text = _selectedCity!;
                    } else if (_selectedCity == null && _selectedDistrict != null && controller.text.isNotEmpty) {
                      controller.clear();
                    }
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: !_isLoading && _selectedDistrict != null,
                      decoration: InputDecoration(
                        labelText: 'City *',
                        hintText: _selectedDistrict == null ? 'Select district first' : 'Type to search city',
                        prefixIcon: const Icon(Icons.location_on, color: AppTheme.primaryRed),
                        suffixIcon: const Icon(Icons.arrow_drop_down, color: AppTheme.neutralGray),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: _selectedCity != null
                                  ? AppTheme.primaryRed
                                  : AppTheme.neutralGray.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryRed, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (_selectedCity == null || _selectedCity!.isEmpty) {
                          return 'Please select your city';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Clear selection if user types something different
                        if (_selectedCity != null && value != _selectedCity) {
                          setState(() {
                            _selectedCity = null;
                          });
                        }
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                leading: const Icon(Icons.location_on, color: AppTheme.primaryRed, size: 20),
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 460.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Volunteer Area Selection (only for volunteers)
                if (widget.userRole == UserRole.volunteer) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedArea != null 
                            ? AppTheme.volunteerAccent 
                            : AppTheme.neutralGray.withValues(alpha: 0.2),
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedAreaId,
                      decoration: const InputDecoration(
                        labelText: 'Select Area *',
                        hintText: 'Choose your volunteer area',
                        prefixIcon: Icon(Icons.map, color: AppTheme.volunteerAccent),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _availableAreas.isEmpty
                          ? [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Loading areas...'),
                              ),
                            ]
                          : _availableAreas.map((area) {
                              return DropdownMenuItem(
                                value: area['areaId'] as String,
                                child: Text(area['areaName'] as String),
                              );
                            }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          final area = _availableAreas.firstWhere(
                            (a) => a['areaId'] == value,
                            orElse: () => {'areaId': value, 'areaName': value},
                          );
                          setState(() {
                            _selectedAreaId = value;
                            _selectedArea = area['areaName'] as String;
                          });
                        }
                      },
                      validator: (value) {
                        if (widget.userRole == UserRole.volunteer && value == null) {
                          return 'Please select your volunteer area';
                        }
                        return null;
                      },
                    ),
                  ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 20),
                ],

                // Address
                TextFormField(
                  controller: _addressController,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Address *',
                    hintText: 'Enter your complete address',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child:
                          Icon(Icons.location_on, color: AppTheme.primaryRed),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    if (value.length < 10) {
                      return 'Please enter a complete address';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 24),

                // Document Upload Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.userRole == UserRole.citizen
                          ? AppTheme.citizenAccent.withValues(alpha: 0.3)
                          : AppTheme.volunteerAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: DocumentUploadWidget(
                    accentColor: widget.userRole == UserRole.citizen
                        ? AppTheme.citizenAccent
                        : AppTheme.volunteerAccent,
                    required: false,
                    onDocumentUploaded: (url, type) {
                      setState(() {
                        _documentUrl = url;
                        _documentType = type;
                      });
                    },
                  ),
                ).animate().fadeIn(delay: 550.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.userRole == UserRole.citizen
                          ? AppTheme.citizenAccent
                          : AppTheme.volunteerAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'COMPLETE REGISTRATION',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 600.ms).scale(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.userRole == UserRole.citizen
                  ? AppTheme.citizenAccent
                  : AppTheme.volunteerAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).register(
            fullName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            phone: _phoneController.text,
            role: widget.userRole == UserRole.citizen ? 'citizen' : 'volunteer',
            address: _addressController.text,
            profession: _professionController.text,
            dob: _selectedDate!,
            // Location details
            stateLocation: _selectedState,
            district: _selectedDistrict,
            city: _selectedCity,
            // Volunteer area assignment
            registeredArea: widget.userRole == UserRole.volunteer ? _selectedArea : _selectedCity,
            registeredAreaId: widget.userRole == UserRole.volunteer ? _selectedAreaId : null,
            // Identity document (optional for citizen/volunteer)
            identityDocumentUrl: _documentUrl,
            identityDocumentType: _documentType,
          );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.userRole == UserRole.citizen
                ? 'Citizen registration successful!'
                : 'Volunteer registration successful!',
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );

      // Navigate to home screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userRole: widget.userRole),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Debug: Print actual error
      print('Registration error: $e');

      // Check for specific error types
      String errorMessage = 'Registration Failed';
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('409') ||
          errorString.contains('conflict') ||
          errorString.contains('already exists') ||
          errorString.contains('already registered')) {
        errorMessage =
            'This email is already registered. Please use a different email or login instead.';
      } else if (errorString.contains('400') ||
          errorString.contains('bad request')) {
        errorMessage = 'Please check your information and try again.';
      } else if (errorString.contains('network') ||
          errorString.contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else {
        errorMessage = 'Registration failed. Please try again later.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.primaryRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
