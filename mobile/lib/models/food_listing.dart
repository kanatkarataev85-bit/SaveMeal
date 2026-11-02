class FoodListing {
  const FoodListing({
    required this.id,
    required this.title,
    required this.titleKy,
    required this.titleEn,
    required this.description,
    required this.descriptionKy,
    required this.descriptionEn,
    required this.category,
    required this.price,
    required this.originalPrice,
    required this.portions,
    required this.pickupWindow,
    required this.imageUrl,
    required this.restaurant,
    required this.pickupAddress,
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String titleKy;
  final String titleEn;
  final String description;
  final String descriptionKy;
  final String descriptionEn;
  final String category;
  final int price;
  final int originalPrice;
  final int portions;
  final String pickupWindow;
  final String imageUrl;
  final String restaurant;
  final String pickupAddress;
  final bool isFeatured;

  String localizedTitle(String language) => switch (language) {
    'ky' => titleKy,
    'en' => titleEn,
    _ => title,
  };

  String localizedDescription(String language) => switch (language) {
    'ky' => descriptionKy,
    'en' => descriptionEn,
    _ => description,
  };

  int get discountPercent =>
      originalPrice == 0 ? 0 : ((1 - price / originalPrice) * 100).round();
}

class BasketLine {
  const BasketLine({required this.listing, required this.quantity});

  final FoodListing listing;
  final int quantity;

  int get total => listing.price * quantity;
}

const _demoPickupAddress = 'ул. Киевская, 114, Бишкек (демо-адрес)';

const previewListings = <FoodListing>[
  FoodListing(
    id: 'preview-chicken-rice',
    title: 'Курица с рисом',
    titleKy: 'Күрүч менен тоок',
    titleEn: 'Chicken with rice',
    description: 'Запечённая курица с рисом и сезонными овощами.',
    descriptionKy: 'Күрүч жана мезгилдүү жашылчалар менен бышырылган тоок.',
    descriptionEn: 'Roasted chicken with rice and seasonal vegetables.',
    category: 'lunch_category',
    price: 300,
    originalPrice: 600,
    portions: 3,
    pickupWindow: 'Сегодня, 18:00–20:00',
    restaurant: 'SaveMeal партнёр',
    pickupAddress: _demoPickupAddress,
    imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=1000&q=85',
    isFeatured: true,
  ),
  FoodListing(
    id: 'preview-bakery',
    title: 'Булочка с корицей',
    titleKy: 'Корица кошулган токоч',
    titleEn: 'Cinnamon bun',
    description: 'Мягкая булочка с корицей и лёгкой глазурью.',
    descriptionKy: 'Корица жана жеңил глазурь кошулган жумшак токоч.',
    descriptionEn: 'A soft cinnamon bun finished with a light glaze.',
    category: 'bakery_category',
    price: 120,
    originalPrice: 240,
    portions: 4,
    pickupWindow: 'Сегодня, 17:30–19:30',
    restaurant: 'SaveMeal партнёр',
    pickupAddress: _demoPickupAddress,
    imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1000&q=85',
  ),
  FoodListing(
    id: 'preview-bowl',
    title: 'Паста с томатами',
    titleKy: 'Помидор кошулган паста',
    titleEn: 'Tomato pasta',
    description: 'Паста с томатным соусом, зеленью и сыром.',
    descriptionKy: 'Помидор соусу, көк чөп жана сыр кошулган паста.',
    descriptionEn: 'Pasta with tomato sauce, fresh herbs and cheese.',
    category: 'dinner_category',
    price: 250,
    originalPrice: 420,
    portions: 2,
    pickupWindow: 'Сегодня, 18:00–19:00',
    restaurant: 'SaveMeal партнёр',
    pickupAddress: _demoPickupAddress,
    imageUrl: 'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1000&q=85',
  ),
  FoodListing(
    id: 'preview-fruit',
    title: 'Фруктовый десерт',
    titleKy: 'Мөмө-жемиш десерти',
    titleEn: 'Fresh fruit dessert',
    description: 'Сочная тарелка из свежих сезонных фруктов.',
    descriptionKy: 'Жаңы мезгилдүү мөмөлөрдөн жасалган ширелүү десерт.',
    descriptionEn: 'A juicy plate of fresh seasonal fruit.',
    category: 'dessert_category',
    price: 160,
    originalPrice: 250,
    portions: 5,
    pickupWindow: 'Сегодня, 16:00–20:00',
    restaurant: 'SaveMeal партнёр',
    pickupAddress: _demoPickupAddress,
    imageUrl: 'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?auto=format&fit=crop&w=1000&q=85',
  ),
  FoodListing(
    id: 'preview-burger',
    title: 'Бургер с говядиной',
    titleKy: 'Уй эти кошулган бургер',
    titleEn: 'Beef burger',
    description: 'Сочный бургер с говяжьей котлетой и свежими овощами.',
    descriptionKy: 'Уй эти жана жаңы жашылчалар кошулган бургер.',
    descriptionEn: 'A juicy beef patty burger with fresh vegetables.',
    category: 'dinner_category',
    price: 220,
    originalPrice: 400,
    portions: 4,
    pickupWindow: 'Сегодня, 18:00–20:00',
    restaurant: 'SaveMeal партнёр',
    pickupAddress: _demoPickupAddress,
    imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=1000&q=85',
  ),
  FoodListing(
    id: 'preview-pizza',
    title: 'Пицца «Маргарита»',
    titleKy: '«Маргарита» пиццасы',
    titleEn: 'Margherita pizza',
    description: 'Тонкое тесто, томаты, моцарелла и базилик.',
    descriptionKy: 'Жука камыр, помидор, моцарелла жана райхан.',
    descriptionEn: 'Thin crust with tomatoes, mozzarella and basil.',
    category: 'dinner_category',
    price: 350,
    originalPrice: 600,
    portions: 2,
    pickupWindow: 'Сегодня, 19:00–20:30',
    restaurant: 'SaveMeal партнёр',
    pickupAddress: _demoPickupAddress,
    imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=1000&q=85',
  ),
  FoodListing(
    id: 'preview-salad',
    title: 'Боул с авокадо',
    titleKy: 'Авокадо боулу',
    titleEn: 'Avocado bowl',
    description: 'Боул с авокадо, сезонной зеленью, томатами и заправкой.',
    descriptionKy: 'Авокадо, көк чөп, помидор жана жеңил соус кошулган боул.',
    descriptionEn:
        'A bowl with avocado, seasonal greens, tomatoes and dressing.',
    category: 'lunch_category',
    price: 240,
    originalPrice: 480,
    portions: 3,
    pickupWindow: 'Сегодня, 18:00–20:00',
    restaurant: 'SaveMeal партнёр',
    pickupAddress: _demoPickupAddress,
    imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=1000&q=85',
  ),
  FoodListing(
    id: 'preview-coffee',
    title: 'Холодный кофе',
    titleKy: 'Муздак кофе',
    titleEn: 'Iced coffee',
    description: 'Охлаждённый кофе с молоком и мягким вкусом.',
    descriptionKy: 'Сүт кошулган муздак, жумшак даамдуу кофе.',
    descriptionEn: 'Chilled coffee with milk and a smooth finish.',
    category: 'drinks_category',
    price: 140,
    originalPrice: 230,
    portions: 3,
    pickupWindow: 'Сегодня, 16:00–19:00',
    restaurant: 'SaveMeal партнёр',
    pickupAddress: _demoPickupAddress,
    imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&w=1000&q=85',
  ),
];

const welcomeImage =
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1400&q=90';
