import 'package:my_app/models/product_model.dart';
import 'package:my_app/pages/user/widgets/brand_section.dart';

class AdminData {
  static final List<Product> products = [
    Product(
      id: "1",
      name: "Nike Giannis Immortality 4 EP",
      brand: "Nike",
      price: 1499000.0,
      imageUrl: "assets/Nike_Giannis_Immortality_4.png",
      description:
          "Nike Giannis Immortality 4 EP (NIKFQ3681301) adalah sepatu basket low-top ringan dengan midsole empuk untuk kenyamanan, outsole karet berpola multidireksi untuk grip maksimal, serta upper mesh yang menjaga sirkulasi udara. Stabil dan fleksibel, cocok bagi pemain cepat yang mengejar performa optimal.",
      categories: ["basketball", "trending"],
      purchaseOptions: [
        PurchaseOption(
          storeName: "Shopee",
          price: 839300.0,
          logoUrl: "assets/logo_shopee.jpg",
          link:
              "https://shopee.co.id/-BEST-SELLER-Sepatu-Basket-Nike-giannis-immortality-4-ep-ORIGINAL-FQ3681-500-FQ3681-002-i.10262456.22351075298",
        ),
        PurchaseOption(
          storeName: "Tokopedia",
          price: 899150.0,
          logoUrl: "assets/logo_tokopedia.jpg",
          link:
              "https://www.tokopedia.com/indohypesneakers/nike-giannis-immortality-4-ep-halloween-xdr-1730194039838377455?extParam=ivf%3Dfalse%26keyword%3Dnike+giannis+immortality+4%26src%3Dsearch",
        ),
        PurchaseOption(
          storeName: "Blibli",
          price: 1079000.0,
          logoUrl: "assets/logo_blibli.jpg",
          link:
              "https://www.blibli.com/p/nike-men-basketball-giannis-immortality-4-halloween-ep-shoes-sepatu-basket-pria-fq3681-301/is--NIE-12227-12368-00012?pickupPointCode=PP-3537944",
        ),
        PurchaseOption(
          storeName: "Nike Official",
          price: 958000.0,
          logoUrl: "assets/logo_nike.png",
          link:
              "https://www.nike.com/id/t/giannis-immortality-4-ep-basketball-shoes-4MTsCH",
        ),
      ],
    ),
    Product(
      id: "2",
      name: "Nike Zoom Mercurial Superfly 9 Academy",
      brand: "Nike",
      price: 1549000.0,
      imageUrl: "assets/Nike_Mercurial_Superfly_9_Academy_CR7_AG_Blue_White.png",
      description:
          "Sepatu sepak bola terbaik dengan desain aerodinamis dan bahan ringan untuk kecepatan maksimal di lapangan.",
      categories: ["soccer", "trending"],
      purchaseOptions: [
        PurchaseOption(
          storeName: "Shopee",
          price: 1499000.0,
          logoUrl: "assets/logo_shopee.jpg",
          link: "",
        ),
        PurchaseOption(
          storeName: "Tokopedia",
          price: 1549000.0,
          logoUrl: "assets/logo_tokopedia.jpg",
          link: "",
        ),
        PurchaseOption(
          storeName: "Blibli",
          price: 1599000.0,
          logoUrl: "assets/logo_blibli.jpg",
          link: "",
        ),
        PurchaseOption(
          storeName: "Nike",
          price: 1549000.0,
          logoUrl: "assets/logo_nike.png",
          link:
              "https://www.nike.com/id/t/zoom-mercurial-superfly-9-academy-cr7-mg-multi-ground-football-boot-h8Xdz4",
        ),
      ],
    ),
    Product(
      id: "3",
      name: "Mizuno Wave Momentum 3",
      brand: "Mizuno",
      price: 1241047.0,
      imageUrl: "assets/Mizuno_Wave_Momentum_3.png",
      description:
          "Mizuno Wave Momentum 3 adalah sepatu voli mid-cut premium yang menggabungkan stabilitas, kenyamanan, dan respons cepat. Dilengkapi dengan teknologi Mizuno Enerzy untuk bantalan maksimal dan sistem Wave Plate untuk kestabilan optimal saat mendarat. Outsole karet non-marking memberikan grip kuat di setiap gerakan, sementara upper mesh modern menjaga sirkulasi udara agar kaki tetap sejuk. Cocok bagi pemain yang aktif, agresif, dan mengutamakan performa tinggi di setiap rally.",
      categories: ["volleyball", "trending"],
      purchaseOptions: [
        PurchaseOption(
          storeName: "Shopee",
          price: 395000.0,
          logoUrl: "assets/logo_shopee.jpg",
          link:
              "https://shopee.co.id/Sepatu-Volly-Mizuno-Wave-Momentum-3-Low-Sepatu-Mizuno-Momentum-2-Mizuno-Wlz-6-Mizuno-Wlz-7-i.13338465.23988737621",
        ),
        PurchaseOption(
          storeName: "Tokopedia",
          price: 399800.0,
          logoUrl: "assets/logo_tokopedia.jpg",
          link: "https://tk.tokopedia.com/ZSU67G499/",
        ),
        PurchaseOption(
          storeName: "Blibli",
          price: 1899000.0,
          logoUrl: "assets/logo_blibli.jpg",
          link:
              "https://www.blibli.com/p/sepatu-voli-mizuno-wave-momentum-3-mid-original/ps--ORS-70108-00797?ds=ORS-70108-00797-00001&source=SEARCH&sid=bd29f439e940af29&cnc=false&pickupPointCode=PP-3381326&pid1=ORS-70108-00797",
        ),
        PurchaseOption(
          storeName: "Mizuno Official",
          price: 1241047.0,
          logoUrl: "assets/logo_mizuno.png",
          link:
              "https://emea.mizuno.com/eu/en-gb/wave-momentum-3/V1GA231221.html",
        ),
      ],
    ),
    Product(
      id: "4",
      name: "Adidas Dame 8",
      brand: "Adidas",
      price: 1599000.0,
      imageUrl: "assets/images/adidas_dame_8.png",
      description:
          "Sepatu basket signature Damian Lillard dengan teknologi Bounce untuk respons cepat dan traksi maksimal.",
      categories: ["basketball", "terbaru"],
      purchaseOptions: [
        PurchaseOption(
          storeName: "Shopee",
          price: 1499000.0,
          logoUrl: "assets/logo_shopee.jpg",
          link: "",
        ),
        PurchaseOption(
          storeName: "Tokopedia",
          price: 1599000.0,
          logoUrl: "assets/logo_tokopedia.jpg",
          link: "",
        ),
        PurchaseOption(
          storeName: "Blibli",
          price: 1649000.0,
          logoUrl: "assets/logo_blibli.jpg",
          link: "",
        ),
        PurchaseOption(
          storeName: "Adidas Official",
          price: 1599000.0,
          logoUrl: "assets/logo_adidas.png",
          link: "",
        ),
      ],
    ),
    Product(
      id: "5",
      name: "Nike Air Zoom GT Cut 2",
      brand: "Nike",
      price: 2399000.0,
      imageUrl: "assets/images/nike_gt_cut_2.png",
      description:
          "Sepatu basket premium dengan teknologi Air Zoom untuk responsivitas dan traksi multidirectional.",
      categories: ["basketball", "terbaru"],
      purchaseOptions: [
        PurchaseOption(
          storeName: "Shopee",
          price: 2299000.0,
          logoUrl: "assets/logo_shopee.jpg",
          link: "",
        ),
        PurchaseOption(
          storeName: "Tokopedia",
          price: 2399000.0,
          logoUrl: "assets/logo_tokopedia.jpg",
          link: "",
        ),
        PurchaseOption(
          storeName: "Nike Official",
          price: 2399000.0,
          logoUrl: "assets/logo_nike.png",
          link: "",
        ),
      ],
    ),
    Product(
      id: "6",
      name: "Puma Future Z 1.4",
      brand: "Puma",
      price: 1899000.0,
      imageUrl: "assets/images/puma_future_z.png",
      description:
          "Sepatu sepak bola dengan FUZIONFIT+ compression band untuk support dan agility maksimal.",
      categories: ["soccer", "terbaru"],
      purchaseOptions: [
        PurchaseOption(
          storeName: "Shopee",
          price: 1799000.0,
          logoUrl: "assets/logo_shopee.jpg",
          link: "",
        ),
        PurchaseOption(
          storeName: "Tokopedia",
          price: 1899000.0,
          logoUrl: "assets/logo_tokopedia.jpg",
          link: "",
        ),
        PurchaseOption(
          storeName: "Puma Official",
          price: 1899000.0,
          logoUrl: "assets/logo_puma.png",
          link: "",
        ),
      ],
    ),
  ];

  static void addProduct(Product product) {
    products.add(product);
  }

  static List<Product> getAllProducts() => products;

  static void updateProduct(String id, Product updatedProduct) {
    final index = products.indexWhere((p) => p.id == id);
    if (index != -1) {
      products[index] = updatedProduct;
    }
  }

  static void deleteProduct(String id) {
    products.removeWhere((p) => p.id == id);
  }
}

class UserData {
  static final List<Product> products = [...AdminData.products];

  static List<Product> getAllProducts() => products;

  static List<Product> getByCategory(String category) =>
      products.where((p) => p.categories.contains(category)).toList();
}

class AppData {
  static final List<Map<String, String>> categories = [
    {"display": "Basketball Shoes", "filter": "basketball"},
    {"display": "Soccer Shoes", "filter": "soccer"},
    {"display": "Volleyball Shoes", "filter": "volleyball"},
    {"display": "Trending", "filter": "trending"},
  ];

  static final List<Map<String, dynamic>> brands = [
    {"name": "Nike", "icon": "check_circle"},
    {"name": "Jordan", "icon": "sports_basketball"},
    {"name": "Adidas", "icon": "sports_soccer"},
    {"name": "Under Armour", "icon": "sports"},
    {"name": "Puma", "icon": "sports_tennis"},
    {"name": "Mizuno", "icon": "sports_volleyball"},
  ];
}