/// Burmese (မြန်မာ) translations.
///
/// Keys are the exact English strings used in the app, as produced by
/// `tool/extract_strings.dart`. Copy the value column of
/// `l10n/TRANSLATION_KEYS.md` in here, one entry per line:
///
/// ```dart
/// const Map<String, String> myStrings = {
///   'Cancel': 'ပယ်ဖျက်ရန်',
///   'Add Product': 'ထုတ်ကုန်ထည့်ရန်',
/// };
/// ```
///
/// Leave the map empty and the app falls back to English, so partial
/// translations are fine: anything missing simply stays English.
///
/// Two rules:
///  - Do not translate strings that are data rather than chrome, such as
///    variant sizes, customer data, or the `Regular` price type. Those are
///    matched literally by logic and stored in the database.
///  - Keep `{count}`-style placeholders if you use them, spelled exactly as
///    the English string.
const Map<String, String> myStrings = {
  // Auth
  'Welcome Back!': 'ပြန်လည်ကြိုဆိုပါတယ်',
  'Please login to your account': 'သင့်အကောင့်ထဲသို့ဝင်ရောက်ပါ',
  'Enter your email': 'သင့်အီးမေးလ်ထည့်ပါ',
  'Enter your password': 'သင့်စကားဝှက်ထည့်ပါ',
  'Forgot Password?': 'စကားဝှက်မေ့နေလား',
  'Login': 'လော့အင်ဝင်ရန်',
  'Register': 'မှတ်ပုံတင်ရန်',
  'Verify Email': 'အီးမေးလ်အတည်ပြုရန်',
  'OR': 'သို့',
  'Phone number': 'ဖုန်းနံပါတ်',
  'Enter full name': 'အမည်ဖြည့်ပါ',
  'Enter email address': 'အီးမေးလ်လိပ်စာဖြည့်ပါ',
  'Enter password': 'စကားဝှက်ဖြည့်ပါ',
  'Enter user address': 'အသုံးပြုသူလိပ်စာဖြည့်ပါ',
  'Enter user role': 'အသုံးပြုသူအခန်းကဏ္ဍဖြည့်ပါ',
  'Enter NRC number': 'NRC နံပါတ်ဖြည့်ပါ',
  'Enter service feed way': 'ငှားရမ်းရာတွင် ငွေပေးချေသည့် နည်းလမ်းဖြည့်ပါ',
  'Select gender': 'ကျား/မ ရွေးပါ',
  'Verify Your Email': 'သင့်အီးမေးလ်အတည်ပြုပါ',
  'We sent a 6-digit verification code to':
      'စတင် verification code 6 လုံးကိုပို့ပြီးပါပြီ',
  'Enter 6-digit code': 'နံပါတ် 6 လုံးရိုက်ထည့်ပါ',
  'Enter 6-digit OTP': 'OTP နံပါတ် 6 လုံးထည့်ပါ',
  'Verify OTP': 'OTP အတည်ပြုရန်',
  'Verify': 'အတည်ပြုရန်',
  'Resend OTP': 'OTP ပြန်ပို့ရန်',
  'Resend Code': 'ကုဒ်ပြန်ပို့ရန်',
  'Remember your password?': 'စကားဝှက်မမေ့ဘူးလား',
  'Back to Login': 'လော့အင်သို့ပြန်သွားရန်',
  'Enter new password': 'စကားဝှက်အသစ်ထည့်ပါ',
  'Confirm new password': 'စကားဝှက်အသစ်အတည်ပြုပါ',
  'Reset Password': 'စကားဝှက်ပြန်လည်သတ်မှတ်ရန်',
  'Already verified?': 'အလိုမရှိပါဘူးလား',

  // Dashboard
  'Dashboard': 'ဒက်ရှ်ဘုတ်',
  'Summary': 'အတိုချုပ်',
  'Product Trend': 'ကုန်ပစ္စည်းတိုးတက်မှု',
  'Monthly Sales': 'လစွဲရောင်းရမှတ်',
  'Product Distribution by Category': 'ကဏ္ဍအလိုက်ကုန်ပစ္စည်းဖြန့်ခွဲမှု',
  'Quantity Sold by Category': 'ကဏ္ဍအလိုက်ရောင်းခဲ့သည့်အရေတွက်',
  'View all': 'အားလုံးကြည့်ရန်',
  'Retry': 'ပြန်ကြိုးစားရန်',
  'No sales data': 'ရောင်းရမှတ်မရှိပါ',
  'No category data': 'ကဏ္ဍဒေတာမရှိပါ',
  'Count': 'အရေအတွက်',
  'Percentage': 'ရာခိုင်နှုန်း',
  'In Stock': 'ရှိ',
  'Low Stock': 'နည်း',
  'Out of Stock': 'စတော့ကုန်နေသည်',
  '{v1} left (threshold {v2})': '{v1} ကျန်သည် (သတ်မှတ်ချက် {v2})',
  '{v1} out of stock, {v2} low stock': '{v1} ခု စတော့ကုန်နေသည်၊ {v2} ခု တန်ဖိုးနည်း',
  'No product details in this message.': 'ဤအသိပေးချက်တွင် ကုန်ပစ္စည်း အသေးစိတ် မပါဝင်ပါ။',
  'Packages Out of Stock': 'ပက်ကေ့ဂျ်များ စတော့ကုန်နေသည်',
  'Total Products': 'ကုန်ပစ္စည်းစုစုပေါင်း',
  'Total Sales': 'ရောင်းရမှတ်စုစုပေါင်း',
  'Least Bought': 'အနည်းဆုံးဝယ်ယူခဲ့သည်',
  'Most Bought': 'အများဆုံးဝယ်ယူခဲ့သည်',
  'No Bought': 'ဝယ်ယူမထားပါ',
  'Month': 'လ',
  'Select month': 'လရွေးပါ',
  'All time': 'အချိန်အာလုံး',
  'Bought Stock': 'ဝယ်ယူထားသောတန်ဖိုး',
  'Price Per 1': 'တစ်ခုလျှာစျေး',
  'Total Price': 'စုစျေး',
  'Created': 'ဖန်တီးသည်',
  'Created Time': 'ဖန်တီးသောအချိန်',
  'Products In Sale': 'ရောင်းခြင်းကုန်ပစ္စည်းများ',
  'Could not load': 'ဖ_openFile မရပါ',
  'Nothing to show': 'ပြရန်မရှိပါ',
  'No matches': 'မကိုက်ညီပါ',

  // Products
  'Products': 'ကုန်ပစ္စည်းများ',
  'Product Detail': 'ကုန်ပစ္စည်းအသေးစိတ်',
  'Add Product': 'ကုန်ပစ္စည်းထည့်ရန်',
  'Quick Add Product': 'ကုန်ပစ္စည်းမြန်ဆန်းထည့်ရန်',
  'Product Image': 'ကုန်ပစ္စည်းပုံ',
  'Product image': 'ကုန်ပစ္စည်းပုံ',
  'Change photo': 'ပုံပြောင်းရန်',
  'JPG or PNG up to 5MB': 'JPG သို့မဟုတ် PNG သာလွဲ 5MB အထိ',
  'Take a photo or choose an image': 'ဓ tuyển snap လုပ်ပါ သို့မဟုတ် ပုံရွေးပါ',
  'Tap to choose an image file': 'ဖိုင်ပုံရွေးရန်နှိုပ်ပါ',
  'Upload a product photo from your device.': 'သင့်စက်မှကုန်ပစ္စည်းပုံတင်ပါ။',
  'Image uploaded': 'ပုံတင်ပြီးပါပြီ',
  'Overview': 'အကြမ်းဖက်ကြည့်',
  'Variants': 'အမျိုးအစားများ',
  'Attributes': 'အရည်အသွေးများ',
  'Stock Info': 'stockအချက်အလက်',
  'Units in Stock': 'stock ရှိသည်',
  'Add Stock': 'stock ထည့်ရန်',
  'Stock Add': 'stock ထည့်ရန်',
  'Current Stock Status': 'လက်ရှိတန်ဖိုးအခြေအနေ',
  'Choose Quantity': 'အရေတွက်ရွေးပါ',
  'Direct Buy': 'တိုက်ရိုက်ဝယ်ယူရန်',
  'Save Supplier': 'ပေးသွင်းသူသိမ်းရန်',
  'Supplier Information': 'ပေးသွင်းသူအချက်အလက်',
  'Supplier is optional.': 'ပေးသွင်းသးဖြစ်နိုင်ပါသည်။',
  'Search Purchase Item': 'ပေးသွင်းခြင်း ရှာဖွေရန်',
  'Purchase Item': 'ဝယ်ယူထားသည့် မှတ်တမ်း',
  'Purchase item copied into the form': 'ပေးသွင်းခြင်းကိုပုံစံထဲကူးယူပါပြီ',
  'Add New Supplier': 'ပေးသွင်းသူအသစ်',
  'Basic Info': 'အခြေခံအချက်အလက်',
  'Category & Package': 'ကဏ္ဍနှင့် package',
  'Variants, Stock & Price': 'အမျိုးအစား၊ တန်ဖိုးနှင့်စျေး',
  'Inventory Type': 'ငှားရမ်းအမျိုးအစား',
  'Total Stock': 'တန်ဖိုးစုစုပေါင်း',
  'Enter a valid price': 'မှန်ကန်သောစျေးထည့်ပါ',
  'Enter a valid stock amount': 'မှန်ကန်သောတန်ဖိုးထည့်ပါ',
  'Product name is required': 'ကုန်ပစ္စည်းအမည်လိုအပ်ပါသည်',
  'Search Product': 'ကုန်ပစ္စည်းရှာဖွေရန်',
  'Search...': 'ရှာဖွေရန်...',
  'Search products...': 'ကုန်ပစ္စည်းများရှာဖွေရန်...',
  'Try a different keyword or brand':
      'စကားလုံးသို့မဟုတ်အမှတ်အသားကိန်းပြန်လည်ရွေးပါ',
  'Add products to see categories here':
      'ကဏ္ဍများကြည့်ရန် ကုန်ပစ္စည်းများထည့်ပါ',
  'Delete Product': 'ကုန်ပစ္စည်းဖျက်ရန်',
  'Delete': 'ဖျက်ရန်',
  'Cancel': 'ပယ်ဖျက်ရန်',
  'View Details': 'အသေးစိတ်ကြည့်ရန်',
  'Edit variants': 'အမျိုးအစားများကို ပြုပြင်',
  'Choose Variants': 'အမျိုးအစားများရွေးပါ',
  'Quantity': 'အရေတွက်',
  'Total': 'စုစုပေါင်း',
  'Edit': 'ပြုပြင်',
  'Active': 'အသက်ဝင်ပြီး',
  'Inactive': 'မလုပ်ဆောင်ပါ',
  'Sort': 'စီစဉ်ရန်',
  'Newest': 'အသစ်ဆုံး',
  'Oldest': 'အဟောင်းဆုံး',
  'Search a product to add stock.': 'တန်ဖိုးထည့်ရန်ကုန်ပစ္စည်းရှာပါ။',
  'Stock added successfully': 'တန်ဖိုးထည့်ပြီးပါပြီ',

  // Category
  'Categories': 'ကဏ္ဍများ',
  'Category Name': 'ကဏ္ဍအမည်',
  'Enter category name': 'ကဏ္ဍအမည်ဖြည့်ပါ',
  'Enter a name for this category.': 'ဤကဏ္ဍအတွက်အမည်ဖြည့်ပါ။',
  'Description': 'အကြောင်းအရာ',
  'Enter category description': 'ကဏ္ဍအကြောင်းအရာဖြည့်ပါ',
  'No categories found.': 'ကဏ္ဍများမတွေ့ပါ',
  'Manage your category here...': 'သင့်ကဏ္ဍများကို ဤနေရာတွင်စီမံ...',

  // Package
  'Package Details': 'package အသေးစိတ်',
  'Package Name': 'package အမည်',
  'Enter package name': 'package အမည်ဖြည့်ပါ',
  'Enter a name for this package.': 'ဤ package အတွက်အမည်ဖြည့်ပါ။',
  'Enter package description': 'package အကြောင်းအရာဖြည့်ပါ',
  'Amount of Products (Limit)': 'ကုန်ပစ္စည်းအရေတွက် (ကန့်သတ်ချက်)',
  'Amount of Packages (Limit)': 'package အရေတွက် (ကန့်သတ်ချက်)',
  'Category': 'ကဏ္ဍ',
  'Location': 'တည်နေရာ',
  'Add Products to Package': 'package ထဲကုန်ပစ္စည်းများထည့်ရန်',
  'Add to Package': 'package ထဲထည့်ရန်',
  'All products are already in a package.': 'ကုန်ပစ္စည်းအားလုံးပါပြီးပါပြီ။',
  'No unassigned products found.': 'မသတ်မှတ်ထားသောကုန်ပစ္စည်းများမတွေ့ပါ',
  'No products found.': 'ကုန်ပစ္စည်းများမတွေ့ပါ',
  'Self Inventory': 'ကိုယ်ပိုင်ရုံ',
  'Stock Status': 'stock အခြေအနေ',
  'Remove from package': 'package မှဖယ်ထုတ်ရန်',
  'Remove Product': 'ကုန်ပစ္စည်းဖယ်ထုတ်ရန်',
  'Remove': 'ဖယ်ထုတ်ရန်',

  'Remove photo?': 'ပုံဖယ်ထုတ်မလား?',
  'The current photo will be deleted. You can pick a new one later.':
      'လက်ရှိပုံကို ဖယ်ထုတ်ပစ်မည်။ နောက်မှ ပုံအသစ် ထပ်ရွေးနိုင်ပါသည်။',
  // Inventory
  'Inventory': 'သိုလောင်ရုံ',
  'More': 'နောက်ထပ်',
  'Private': 'သီးသန့်',
  'Shared': 'မျှင်မှင်',
  'Open': 'ဖွင့်ရန်',
  'Choose an inventory to manage your items.':
      'ပစ္စည်းများကိုစီမံနိုင်ရန် ငှားရမ်းရွေးပါ။',
  "What's the difference?": 'ဘာကွာခြားလဲ။',
  'Self Inventory: Only you can view and manage.':
      'ကိုယ်ပိုင်ရုံ - မိမိသာ ကြည့်ရှုနှင့်စီမံနိုင်သည်။',
  'Public Inventory: Shared and visible to other users.':
      'အများပိုင်ရုံ - ဆိုင်တစ်ခုလုံး အခြားသုံးသူများ မြင်နိုင်သည်။',
  'Manage products and stocks only for your own shop.':
      'မိမိရုံများ၏ ကုန်ပစ္စည်းနှင့်ပစ္စည်းများကိုသာ စီမံပါ။',
  'View and manage products and stocks shared publicly.':
      'ဆိုင်တစ်ခုလုံး ဧ။် ကုန်ပစ္စည်းများကို ကြည့်ရှုနှင့်စီမံပါ။',

  // Cart
  'Add to Cart': 'cart ထဲထည့်ရန်',
  'Sale cancelled. Your products are saved in Add to Cart.':
      'အရောင်းပယ်ဖျက်ပြီးပါပြီ။ သင့်ပစ္စည်းများကို cart ထဲတွင် သိမ်းဆည်းထားပါသည်။',
  'Cart is empty': 'cart က လွတ်နေပါသည်',
  'Proceed to Checkout': 'ငွေပေးချေမူ လုပ်ဆောင်ရန်',
  'Checkout': 'ငွေရှင်းရန်',
  'No more items': 'နောက်ထပ်ပစ္စည်းမရှိပါ',
  'Fill all stock': 'တန်ဖိုးအားလုံးဖြည့်ပါ',
  'Create a new cart card for these items':
      'ဤပစ္စည်းများအတွက် cart အသစ်ဖန်တီးပါ',
  'New Card': 'ကဒ်အသစ်',
  'Existing Card': 'လက်ရှိကဒ်',
  'Existing Cards': 'လက်ရှိကဒ်များ',
  'Add': 'ထည့်ရန်',
  'Delete Cart': 'cart ဖျက်ရန်',

  // Customer
  'Customer Data': 'ဖောက်သည်ဒေတာ',
  'Search customers...': 'ဖောက်သည်များရှာဖွေရန်...',
  'Top 3 Customers': 'အထိရှိသောဖောက်သည်များ ၃ ဦး',
  'Top Products': 'အထိရှိသောကုန်ပစ္စည်းများ',
  'Purchase Behavior': 'ဝယ်ယူသုံးစွဲပြဿနာ',
  'Sales Trend': 'ရောင်းရမှတ်တိုးတက်မှု',
  'Sales by Location': 'တည်နေရာအလိုက်ရောင်းရမှတ်',
  'No customer data yet.': 'ဖောက်သည်ဒေတာမရှိသေးပါ',
  'New vs Returning Customers': 'မကြာသေးတွေ့သူနှင့်ပြန်လာသူ',
  'Orders & Customers': 'မှာခြင်းနှင့်ဖောက်သည်များ',

  // Profile
  'My Profile': 'ကျွန်ုပ်၏ပရိုဖိုင်း',
  'Full Name': 'အမည်အပြည့်အစုံ',
  'Email': 'အီးမေးလ်',
  'Phone': 'ဖုန်းနံပါတ်',
  'Date of Birth': 'မွေးသက္ကရာဇာ',
  'Gender': 'လိပ်စာ',
  'NRC No': 'NRC နံပါတ်',
  'Address': 'လိပ်စာ',
  'Role': 'အခန်းကဏ္ဍ',
  'Owner': 'ပိုင်ရှင်',
  'Owner Name': 'ပိုင်ရှင်အမည်',
  'Owner Email': 'ပိုင်ရှင်အီးမေးလ်',
  'Owner Phone': 'ပိုင်ရှင်ဖုန်း',
  'Save Profile': 'ပရိုဖိုင်းသိမ်းရန်',
  'Save Shop': 'သိမ်းရန်',
  'Shop Name': 'ဆိုင်အမည်',
  'Shop Type': 'ဆိုင်အမျိုးအစား',
  'Type': 'အမျိုးအစား',
  'Social Media': 'လူမှုမီဒီယာ',
  'Change Password': 'စကားဝှက်ပြောင်းရန်',
  'Current password': 'လက်ရှိစကားဝှက်',
  'New password': 'စကားဝှက်အသစ်',

  // Settings
  'Setting': 'ဆက်တင်',
  'Language': 'ဘာသာစကား',
  'Select Language': 'ဘာသာစကားရွေးပါ',
  'Privacy Policy': 'ကိုယ်ရေးအချက်အလက်',
  'Terms of Service': 'ဝန်ဆောင်မှုများအကြောင်း',
  'About': 'အကြောင်း',
  'App Name': 'အက်ပ်အမည်',
  'Version': 'ဗားရှင်း',
  'Developer': 'ဖန်တီးသူ',
  'Logout': 'ထွက်ရန်',
  'Rate App': 'အက်ပ်အဆင့်သတ်မှတ်ရန်',
  'Feedback': 'Feedback ပေးရန်',
  'Write your feedback...': 'သင့်ပြောရန်မှတ်တမ်းရေးပါ...',
  'Submit': 'တင်ပြရန်',
  'Feedback submitted!': 'ပြောရန်မှတ်တမ်းတင်ပြပြီးပါပြီ',
  'Comment': 'မှတ်ချက်',
  'Suggestion': 'အကြံပြုချက်',
  'Bug Report': 'အမှားတင်ပြချက်',
  'Redirecting to app rating...': 'အက်ပအဆင့်သတ်မှတ်မှုသို့ပြောင်းရွေ့နေသည်...',
  'Are you sure you want to logout?': 'ထွက်မည်ဟုသေချာပါသည်၊',
  'OK': 'OK',
  'Shop Image': 'ဆိုင်ပုံ',
  'Tap to change shop image': 'ဆိုင်ပုံပြောင်းရန်နှိုပ်ပါ',
  'Upload shop image': 'ဆိုင်ပုံတင်ပါ',

  // Sale
  'New Sale': 'အသစ်ရောင်းရန်',
  'Sale Detail': 'မှတ်တမ်းအသေးစိတ်',
  'Sales Items': 'ရောင်းထားသည့် မှတ်တမ်း',
  'Items': 'ပစ္စည်းများ',
  'No items added yet.': 'ပစ္စည်းများမထည့်သေးပါ',
  'Total Amount': 'စုစုပေါင်းငွေကြေး',
  'Qty:': 'အရေတွက်',
  'Total:': 'စုစုပေါင်း',
  'Payment Method': 'ငွေပေးချေမှုနည်းလမ်း',
  'Cash': 'ငွေပြန်လဲ',
  'Card': 'ကဒ်',
  'Mobile Pay': 'မိုဘိုင်းငွေပေး',
  'Other': 'အခြား',
  'Auto-print after sale': 'ရောင်းပြီးလျှင်  print',
  'Print Voucher': 'print လုပ်ရန်',
  'Print Settings': 'print ဆက်တင်များ',
  'Paper Size': 'စာရွက်အရွယ်အစား',
  'Print Format': 'print ပုံစံ',
  'Save PDF file after sale': 'ရောင်းပြီးလျှင် PDF သိမ်းရန်',
  'Invoice Preview': 'ဝယ်ပီး မှတ်တမ်း အကြို',
  'Invoice': 'ဝယ်ပီးမှတ်တမ်း',
  'Item': 'ပစ္စည်း',
  'Price': 'တန်ဖိုး',
  'Qty': 'အရေတွက်',
  'Payment': 'ငွေပေးချေမှု',
  'Notes': 'မှတ်ချက်များ',
  'Total Payable': 'ပေးရန်ငွေစုစုပေါင်း',
  'Thank you for your purchase!': 'ဝယ်ယူအားပေးကျေးဇူးတင်ပါတယ်!',
  'Customer': 'ဖောက်သည်',
  'Date': 'ရက်စွဲ',
  'Time': 'အချိန်',
  'Voucher ID': 'Voucher ID',
  'Shop name': 'ဆိုင်အမည်',
  'Shop Contact': 'ဆိုင်အားဆက်သွယ်ရန်',
  'Staff': 'ဝန်ထမ်း',
  'Subtotal': 'စုစုပေါင်း',
  'TOTAL': 'စုစုပေါင်း',
  'Thank you!': 'ကျေးဇူးတင်ပါတယ်!',
  'Order ID': 'မှာခြင်းအမှတ်စဉ်',
  'INVOICE': 'ဝယ်ပီးမှတ်တမ်း',
  'Up to Sale': 'ရောင်းရန်',
  'Delete Item': 'ပစ္စည်းဖျက်ရန်',

  // Purchase
  'Purchase Items': 'ဝယ်ယူထားသည့်ပစ္စည်းများ',
  'Purchase Detail': 'ပစ္စည်းအသေးစိတ်',
  'Manage purchase orders from your suppliers':
      'ပေးသွင်းသူများမှငှားရမ်းမှတ်တမ်းများစီမံပါ',
  'New Purchase Order': 'ငှားရမ်းမှတ်တမ်းအသစ်',
  'Create Purchase Order': 'ငှားရမ်းမှတ်တမ်းဖန်တီးရန်',
  'Mark Completed': 'ပြီးပြီဟုမှတ်ရန်',
  '+ Add Supplier': '+ ပေးသွင်းသူထည့်ရန်',
  'Select a supplier...': 'ပေးသွင်းသူရွေးပါ...',
  'Supplier': 'ပေးသွင်းသူ',

  // Shop
  'Create Shop': 'ဆိုင်ဖန်တီးရန်',
  'Create Shop?': 'ဆိုင်ဖန်တီးမလား',
  'Link Shop?': 'ဆိုင်နဲ့ ချိတ်ဆက်မလား',
  'Continue': 'ဆက်လက်လုပ်ဆောင်ရန်',
  'Enter shop name': 'ဆိုင်အမည်ဖြည့်ပါ',
  'Select type': 'အမျိုးအစားရွေးပါ',
  'Search shop by name, address or owner':
      'အမည်၊လိပ်စာ သို့မဟုတ် ပိုင်ရှင်အလိုက်ရှာပါ',
  'JPG or PNG · up to 5MB': 'JPG သို့မဟုတ် PNG သာလွဲ 5MB အထိ',
  'Tap to browse your gallery': 'သင့်ပရိဘောဂရွေးရန်နှိုပ်ပါ',

  // Onboarding
  'MDRK POS': 'MDRK အရောင်း software',
  'INVENTORY MANAGEMENT': 'ငှားရမ်းစီမံမှု',
  'SMART POS': 'စမတ် POS',
  'Powered by MDRK': 'MDRK မှပြုလုပ်ထားသည်',
  'Swipe to get started': 'စတင်ရန်လှမ်းလျှော့ပါ',
  'Manage sales, stock, and reports from your pocket.':
      'ရောင်းချမှု၊ ပစ္စည်းနှင့် အစာရင်းအညွှန်းများကို ဖုန်းဖြင့် စီမံပါ',
  'Fast checkout': 'အမြန်မြန် ငွေပေးချေမှု',
  'Live inventory tracking':
      'ပစ္စည်းလက်ကမား အချက်အလက်ကို အချက်ချင်းခန့်ကြည့်ခြင်း',
  'Daily sales reports': 'နေ့စဉ် ရောင်းချမှု အစာရင်းအညွှန်းများ',
  'Get Started': 'စတင်ပါ',

  // Shared drawer
  'Product': 'ကုန်ပစ္စည်း',
  'Sale': 'ရောင်းရမှတ်',
  'Sale Item': 'ရောင်းထားသည့် မှတ်တမ်း',
  'TOTAL PAYABLE': 'ပေးရန်ငွေစုစုပေါင်း',

  // Stock / Inventory forms
  'Stock': 'အရေအတွက်',

  // Package screen
  'No packages found.': 'package များမတွေ့ပါ',
  'Delete Package': 'package ဖျက်ရန်',

  // Shared
  'Error': 'အမှား',
  'Success': 'အောင်မြင်ပါသည်',
  '+ Add': '+ ထည့်ရန်',
  '+ Add Variant': '+ အမျိုးအစားထည့်ရန်',
  'Add products to your cart': 'ခရက်လွှာထဲကုန်ပစ္စည်းများထည့်ပါ',
  'Audit Information': 'စစ်ဆေးခြင်းအချက်အလက်',
  'Choose how you want to add a product': 'ကုန်ပစ္စည်းထည့်နည်းရွေးပါ',
  'Color': 'အရောင်',
  'Delete Category': 'ကဏ္ဍဖျက်ရန်',
  'Enter notes...': 'မှတ်ချက်များထည့်ပါ...',
  'Export PDF': 'PDF ထုတ်ပြရန်',
  'Express Item': 'အမြန်ပစ္စည်း',
  'Failed to add product': 'ကုန်ပစ္စည်းထည့်မရပါ',
  'Failed to add stock': 'stock ထည့်မရပါ',
  'Identification': 'စီမံခွင့်ရှိသူ',
  'Invoice no': 'အမှာချေမှတ်တမ်းနံပါတ်',
  'New Product': 'ကုန်ပစ္စည်းအသစ်',
  'No categories available': 'ကဏ္ဍများမရှိပါ',
  'No products': 'ကုန်ပစ္စည်းမရှိပါ',
  'No products found': 'ကုန်ပစ္စည်းမတွေ့ပါ',
  'No products in this category': 'ဤကဏ္ဍတွင်ကုန်ပစ္စည်းမရှိပါ',
  'Normal Add': 'ပထမဦးစားပုံ',
  'Please wait for image upload to finish': 'ပုံတင်ပြီးမချိန်ပါနှင့်',
  'Quick Add': 'မြန်ဆန်းထည့်ရန်',
  'Select': 'ရွေးပါ',
  'Select category': 'ကဏ္ဍရွေးပါ',
  'Send OTP': 'OTP ပို့ရန်',
  'Supply Chain': 'ပေးသွင်းခြင်း',
  'Update Stock': 'တန်ဖိုးပြင်ဆင်ရန်',
  '{v1} product': '{v1} ပစ္စည်း',
  '{v1} products': '{v1} ပစ္စည်းများ',

  // Notifications
  'Notifications': 'အသိပေးချက်များ',
  'Mark all read': 'အားလုံးကို ဖတ်ပြီးပြီဟု မှတ်ရန်',
  'Clear all': 'အားလုံးဖျက်ရန်',
  'No notifications yet': 'အသိပေးချက်များ မရှိသေးပါ',
  'Stock alerts will appear here.': 'စတော့အသိပေးချက်များ ဤနေရာတွင် ပေါ်လာပါမည်။',
  'Thank-you messages will appear here.':
      'ကျေးဇူးတင်စကားများ ဤနေရာတွင် ပေါ်လာပါမည်။',
  'Thank you for your feedback, {v1}!':
      'ပြောရန်မှတ်တမ်းအတွက် ကျေးဇူးတင်ပါတယ်၊ {v1}!',
  'Thank you for your feedback!': 'ပြောရန်မှတ်တမ်းအတွက် ကျေးဇူးတင်ပါတယ်!',
  'Your message': 'သင်ရေးသားသော စာသား',
  'Reference': 'ကိုးကား',
  'System': 'စနစ်',
  'Alert': 'သတိပေးချက်',
  'News': 'သတင်း',
  'Clear all notifications?': 'အသိပေးချက်အားလုံး ဖျက်မည်လား?',
  'This removes the saved notification history.':
      'ဒါက သိမ်းထားတဲ့ အသိပေးချက်မှတ်တမ်းကို ဖျက်ပစ်မယ်။',
  'Just now': 'အခုလေးတင်',
  '{v1} min ago': '{v1} မိနစ် အကြာက',
  '{v1} hr ago': '{v1} နာရီ အကြာက',
  'Yesterday': 'မနေ့က',

  // Offline sync
  'Offline — showing saved data':
      'အော့ဖ်လိုင်း — သိမ်းဆည်းထားသော ဒေတာကို ပြန်လည်ပြသနေသည်',
  'Syncing…': 'မွမ်းမံနေသည်…',
  'Refresh failed': 'အသစ်ပြန်တင်၍ မရပါ',
  'Waiting to sync': 'ပေးပို့ရန် စောင့်ဆိုင်းနေသည်',
  '{v1} queued': '{v1} စောင့်ဆိုင်းနေသည်',
  '{v1} failed': '{v1} မအောင်မြင်ပါ',
  'Saved on this device': 'ဤစက်တွင် သိမ်းဆည်းထားသည်',

  // Quick sale
  'Quick Sale': 'အမြန်ရောင်းချရန်',
  'Current Sale': 'လက်ရှိ ရောင်းချမှု',
  'Complete Sale': 'ရောင်းချမှု ပြီးဆုံးရန်',
  'View Cart': 'ခြင်းတောင်း ကြည့်ရန်',
  'Customer (optional)': 'ဖောက်သည် (မထည့်လည်းရသည်)',
  'Discount': 'လျှော့ဈေး',
  'Saving...': 'သိမ်းဆည်းနေသည်...',
  'Sale saved successfully!': 'ရောင်းချမှု အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ!',
  'Remove all items from this sale?':
      'ဤရောင်းချမှုမှ ပစ္စည်းအားလုံး ဖယ်ရှားမည်လား?',
  'Tap a product to add it to this sale':
      'ဤရောင်းချမှုထဲ ထည့်ရန် ကုန်ပစ္စည်းကို နှိပ်ပါ',
  'Try a different keyword or category':
      'အခြားစာလုံး သို့မဟုတ် ကဏ္ဍဖြင့် စမ်းကြည့်ပါ',
  'All': 'အားလုံး',
  'Clear': 'ရှင်းလင်းရန်',
  'Close': 'ပိတ်ရန်',
  'Stock: {v1}': 'စတော့: {v1}',
  '{v1} items': 'ပစ္စည်း {v1} ခု',
  '{v1} is out of stock': '{v1} စတော့ကုန်နေသည်',
  '{v1} has only {v2} in stock': '{v1} တွင် {v2} ခုသာ ကျန်သည်',
  '{v1} variants': 'အမျိုးအစား {v1}',
  'No products found for "{v1}"': '"{v1}" အတွက် ကုန်ပစ္စည်း မတွေ့ပါ',
  'Photo saved on this shop server only. Other devices may not load it.':
      'ဓာတ်ပုံကို သိမ်းပြီးပါပြီ။ ဤစက်တွင်သာ သိမ်းဆည်းထားပါသည် — အခြားစက်များတွင် မပေါ်နိုင်ပါ။',
  'This photo could not be reduced and is uploading at full size.':
      'ဤဓာတ်ပုံကို အရွယ်အစား မလျှော့နိုင်ပါ — မူလအရွယ်အစားအတိုင်း တင်ပို့နေပါသည်။',

  // ── Tabs & status chips ──
  'Sold': 'ရောင်းပြီး',
  'Order': 'မှာယူမှု',
  'Completed': 'ပြီးဆုံး',
  'Pending': 'ဆိုင်းငံ့',
  'Paid': 'ပေးချေပြီး',
  'Already Sale': 'ရောင်းပြီး',
  'Will Be Sale': 'ရောင်းရန်ကျန်',

  // ── Sale / purchase detail cards ──
  'Customer Information': 'ဖောက်သည်အချက်အလက်',
  'Saler Information': 'ရောင်းချသူအချက်အလက်',
  'Ordered Items': 'မှာယူထားသော ပစ္စည်းများ',
  'Ordered Items ({v1})': 'မှာယူထားသော ပစ္စည်းများ ({v1})',
  'Payment Information': 'ငွေပေးချေမှု အချက်အလက်',
  'Order Status & History': 'အမှာအခြေအနေနှင့် မှတ်တမ်း',
  'Purchaser Information': 'ဝယ်ယူသူ အချက်အလက်',
  'Product Details': 'ကုန်ပစ္စည်း အသေးစိတ်',

  // ── Sale / purchase detail rows ──
  'Customer Name': 'ဖောက်သည်အမည်',
  'Saler Name': 'ရောင်းချသူအမည်',
  'Created At': 'ဖန်တီးသည့်အချိန်',
  'Created By': 'ဖန်တီးသူ',
  'Updated At': 'ပြင်ဆင်သည့်အချိန်',
  'Updated By': 'ပြင်ဆင်သူ',
  'Payment Status': 'ငွေပေးချေမှုအခြေအနေ',
  'Order Date': 'အမှာတင်သည့်ရက်စွဲ',
  'Order Status': 'အမှာအခြေအနေ',
  'Voucher Ref': 'ဘောင်ခတ်နံပါတ်',
  'Purchaser Name': 'ဝယ်ယူသူအမည်',
  'Supplier Name': 'ပေးသွင်းသူအမည်',
  'Supplier ID': 'ပေးသွင်းသူ နံပါတ်',
  'Unit Price': 'တစ်ခုချင်း စျေးနှုန်း',
  'Order #{v1}': 'အမှာအမှတ်စဉ် #{v1}',

  // ── Totals panel (new sale / quick sale) ──
  'Total Items': 'စုစုပေါင်း ပစ္စည်းအရေအတွက်',
  'Discount Amount': 'လျှော့ဈေးပမာဏ',
  'Discount ({v1}%)': 'လျှော့ဈေး ({v1}%)',

  // ── Settings appearance toggle ──
  'Dark Mode': 'အမှောင်မုဒ်',
  'Light Mode': 'အလင်းမုဒ်',

  // ── Profile sections ──
  'Personal Information': 'ကိုယ်ရေး အချက်အလက်',
  'Account Details': 'အကောင့် အသေးစိတ်',
  'Personal Details': 'ကိုယ်ရေး အသေးစိတ်',
  'About Shop': 'ဆိုင်အကြောင်း',

  // ── Add product option cards ──
  'Add a product with minimal details — name, price, and stock only.':
      'အနည်းငယ်သော အချက်အလက်များဖြင့် ကုန်ပစ္စည်း ထည့်ရန် — အမည်၊ စျေးနှုန်းနှင့် အရေအတွက်သာ။',
  'Add stock to an existing product or create with detailed inventory tracking.':
      'ရှိပြီးသား ကုန်ပစ္စည်းထဲ စတော့ ထည့်ရန် သို့မဟုတ် စတော့ခြေရာခံမှု အသေးစိတ်ဖြင့် အသစ် ဖန်တီးရန်။',
  'Full product creation with all details — image, variants, categories, and supply chain.':
      'အချက်အလက်အားလုံး ပါဝင်သော ကုန်ပစ္စည်း အပြည့်အစုံ ဖန်တီးရန် — ပုံ၊ မျိုးကွဲများ၊ အမျိုးအစားများနှင့် ထောက်ပံ့ရေးကွင်းဆက်။',

  // ── Product form helpers ──
  'Choose which inventory this product belongs to.':
      'ဤကုန်ပစ္စည်း ပါဝင်မည့် သိုလှောင်မှုအမျိုးအစားကို ရွေးချယ်ပါ။',
  'Split total stock into sizes and colors. Each variant has its own quantity and price.':
      'စုစုပေါင်း စတော့ကို အရွယ်အစားနှင့် အရောင်များအဖြစ် ခွဲပါ။ မျိုးကွဲတိုင်းတွင် ၎င်း၏ အရေအတွက်နှင့် စျေးနှုန်း ရှိပါမည်။',

  // ── Add-to-cart dialog ──
  'Load an old card and add items to it (merge categories)':
      'ယခင် ကဒ်တစ်ခုကို တင်ပြီး ပစ္စည်းများ ထည့်ရန် (အမျိုးအစားများ ပေါင်းရန်)',

  // ── Inventory labels ──
  'Public Inventory': 'အများပိုင်ရုံ',

  // ── Product form fields ──
  'Product Name': 'ကုန်ပစ္စည်းအမည်',
  'Brand': 'အမှတ်တံဆိပ်',
  'Contact / Phone': 'ဆက်သွယ်ရန် / ဖုန်း',

  // ── Legal document header ──
  'Last Updated: {v1}': 'နောက်ဆုံးပြင်ဆင်သည့်ရက်: {v1}',

  // ── Privacy Policy ──
  '1. Introduction': '၁။ နိဒါန်း',
  'This Privacy Policy explains how Smart POS & Inventory ("we", "our", or "us") collects, uses, stores, and protects your information when you use our point-of-sale and inventory management application (the "Service"). By accessing or using the Service, you agree to the practices described in this Privacy Policy.':
      'ဤကိုယ်ရေးအချက်အလက်မူဝါဒသည် Smart POS & Inventory (ကျွန်ုပ်တို့) မှ သင်၏ ငွေရောင်းငွေယူစနစ်နှင့် ပစ္စည်းစီမံခန့်ခွဲမှု ဝန်ဆောင်မှုကို အသုံးပြုစဉ် သင့်အချက်အလက်များကို မည်သို့ စုဆောင်း၊ အသုံးပြု၊ သိမ်းဆည်းနှင့် ကာကွယ်ဆောင်ရွက်ကြောင်း ဖော်ပြပါသည်။ ဤဝန်ဆောင်မှုကို ဝင်ရောက်အသုံးပြုခြင်းဖြင့် ဤမူဝါဒတွင် ဖော်ပြထားသော လုပ်ဆောင်ချက်များကို သဘောတူညီပါသည်။',
  '2. Information We Collect': '၂။ ကျွန်ုပ်တို့ စုဆောင်းသော အချက်အလက်များ',
  'Account Information: When you register and log in to the Service, we collect your name, email address, shop name, and the credentials needed to access your account.':
      'အကောင့်အချက်အလက် - ဝန်ဆောင်မှုတွင် စာရင်းသွင်းခြင်းနှင့် ဝင်ရောက်သောအခါ သင့်အမည်၊ အီးမေးလ်လိပ်စာ၊ ဆိုင်အမည်နှင့် အကောင့်ဝင်ရန် လိုအပ်သော အထောက်အထားများကို ကျွန်ုပ်တို့ စုဆောင်းပါသည်။',
  'Business Data: To operate the point-of-sale and inventory features, we store information you enter, including products, categories, packages, pricing, stock levels, purchases, sales, and customer details.':
      'လုပ်ငန်းဒေတာ - ငွေရောင်းငွေယူစနစ်နှင့် ပစ္စည်းစီမံခန့်ခွဲမှု လုပ်ဆောင်ချက်များ အလုပ်လုပ်စေရန် သင်ထည့်သွင်းသော ကုန်ပစ္စည်းများ၊ အမျိုးအစားများ၊ ပက်ကေ့များ၊ စျေးနှုန်းများ၊ စတော့အတိုင်းအတာများ၊ ဝယ်ယူမှုများ၊ ရောင်းချမှုများနှင့် ဖောက်သည်အသေးစိတ်များ အပါအဝင် အချက်အလက်များကို သိမ်းဆည်းပါသည်။',
  'Usage Information: We may collect basic technical information such as device type, operating system, app version, and general usage patterns to maintain and improve the Service.':
      'အသုံးပြုမှုအချက်အလက် - ဝန်ဆောင်မှုကို ထိန်းသိမ်းပြီး ပိုမိုကောင်းမွန်စေရန် စက်အမျိုးအစား၊ လည်ပတ်စနစ်၊ အက်ပ်ဗားရှင်းနှင့် အသုံးပြုပုံများကဲ့သို့သော အခြေချ နည်းပညာအချက်အလက်များကို စုဆောင်းနိုင်ပါသည်။',
  '3. How We Use Your Information': '၃။ သင့်အချက်အလက်ကို ကျွန်ုပ်တို့ အသုံးပြုပုံ',
  'We use your information to provide, maintain, and improve the Service, including processing sales, tracking inventory and stock, generating reports, and managing your account. We may also use your contact information to send important notices about the Service, such as security alerts, updates, or changes to these terms.':
      'ကျွန်ုပ်တို့သည် ဝန်ဆောင်မှု ပေးအပ်ခြင်း၊ ထိန်းသိမ်းခြင်းနှင့် ပိုမိုကောင်းမွန်စေခြင်းအတွက် — ရောင်းချမှုများ ဆောင်ရွက်ခြင်း၊ ပစ္စည်းနှင့် စတော့များ ခြေရာခံခြင်း၊ အစီရင်ခံစာများ ထုတ်ယူခြင်းနှင့် သင့်အကောင့် စီမံခြင်းအပါအဝင် သင့်အချက်အလက်ကို အသုံးပြုပါသည်။ လုံခြုံရေးသတိပေးချက်များ၊ အသစ်များ သို့မဟုတ် ဤစည်းမျဉ်းများ ပြောင်းလဲမှုများကဲ့သို့ ဝန်ဆောင်မှုနှင့် ပတ်သက်သော အရေးကြီး အကြောင်းကြားချက်များ ပေးပို့ရန် သင့်ဆက်သွယ်ရန်အချက်အလက်ကိုလည်း အသုံးပြုနိုင်ပါသည်။',
  'We do not sell your personal information. We only use the data you provide to operate the Service as described in this Privacy Policy.':
      'ကျွန်ုပ်တို့သည် သင့်ကိုယ်ရေးအချက်အလက်ကို ရောင်းချခြင်း မပြုပါ။ ဤကိုယ်ရေးအချက်အလက်မူဝါဒတွင် ဖော်ပြထားသည့်အတိုင်း ဝန်ဆောင်မှု အလုပ်လုပ်စေရန် သင်ပေးအပ်သော ဒေတာကိုသာ အသုံးပြုပါသည်။',
  '4. Data Storage and Security': '၄။ ဒေတာ သိုလှောင်မှုနှင့် လုံခြုံရေး',
  'Your data is stored on secure servers and protected using reasonable administrative, technical, and physical safeguards. We apply industry-standard security measures to prevent unauthorized access, alteration, disclosure, or destruction of your information.':
      'သင့်ဒေတာကို လုံခြုံသော ဆာဗာများတွင် သိမ်းဆည်းပြီး စီမံခန့်ခွဲမှု၊ နည်းပညာနှင့် ရုပ်ပိုင်းဆိုင်ရာ ကာကွယ်မှုများဖြင့် စနစ်တကျ ကာကွယ်ထားပါသည်။ သင့်အချက်အလက်ကို ခွင့်ပြုချက်မဲ့ ဝင်ရောက်ခြင်း၊ ပြင်ဆင်ခြင်း၊ ဖော်ပြခြင်း သို့ ဖျက်ပစ်ခြင်းကို တားဆီးရန် လုပ်ငန်းနယ်ပယ် စံနှုန်း လုံခြုံရေး နည်းလမ်းများကို အသုံးပြုပါသည်။',
  'You are responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account. Please notify us immediately if you suspect any unauthorized use of your account.':
      'သင့်အကောင့်ဝင်ရန် အထောက်အထားများ၏ လျှို့ဝှက်မှုကို ထိန်းသိမ်းခြင်းနှင့် သင့်အကောင့်အောက်တွင် ဖြစ်ပွားသမျှ လှုပ်ရှားမှုအားလုံးအတွက် သင်တာဝန်ရှိပါသည်။ သင့်အကောင့်ကို ခွင့်ပြုချက်မဲ့ အသုံးပြုနေသည်ဟု သံသယရှိပါက ချက်ချင်း အကြောင်းကြားပါ။',
  '5. Data Sharing and Disclosure': '၅။ ဒေတာ မျှဝေမှုနှင့် ဖော်ပြမှု',
  'We do not share your personal information with third parties except where it is necessary to operate the Service, to comply with legal obligations, to protect the rights and safety of our users or the public, or with your consent.':
      'ဝန်ဆောင်မှု အလုပ်လုပ်ရန်၊ ဥပဒေတာဝန်များနှင့် ကိုက်ညီရန်၊ အသုံးပြုသူများနှင့် ပြည်သူ့အခွင့်အရေးနှင့် ဘေးကင်းရေးကို ကာကွယ်ရန် သို့ သင့်သဘောတူညီချက်ဖြင့် လိုအပ်သောအခါမှအပ သင့်ကိုယ်ရေးအချက်အလက်ကို တတိယပါတီနှင့် မျှဝေခြင်း မပြုပါ။',
  'If we engage third-party service providers to help operate the Service (such as hosting or cloud infrastructure), we require them to protect your information and to use it only for the services we request.':
      'ဝန်ဆောင်မှု အလုပ်လုပ်ရန် တတိယပါတီ ဝန်ဆောင်မှုပေးသူများ (ဟိုစတင်းန်သို့မဟုတ် ကလောဒ် အခြေခံအဆောက်အအုံ) ကို အသုံးပြုပါက ၎င်းတို့အား သင့်အချက်အလက်ကို ကာကွယ်စေပြီး ကျွန်ုပ်တို့ တောင်းဆိုသော ဝန်ဆောင်မှုများအတွက်သာ အသုံးပြုစေပါသည်။',
  '6. Data Retention': '၆။ ဒေတာ သိမ်းဆည်းမှု',
  'We retain your information for as long as your account is active or as needed to provide the Service, comply with legal obligations, resolve disputes, and enforce our agreements. You may request deletion of your account and associated data at any time by contacting us.':
      'သင့်အကောင့် အသုံးပြုနေသ၍ သို့ ဝန်ဆောင်မှုပေးအပ်ရန်၊ ဥပဒေတာဝန်များနှင့် ကိုက်ညီရန်၊ အငြင်းပွားမှုများ ဖြေရှင်းရန်နှင့် သဘောတူညီချက်များ အကောင်အထည်ဖော်ရန် လိုအပ်သ၍ သင့်အချက်အလက်ကို သိမ်းဆည်းထားပါသည်။ အချိန်မရွေး ကျွန်ုပ်တို့ထံ ဆက်သွယ်ပြီး သင့်အကောင့်နှင့် ဆက်စပ်ဒေတာများ ဖျက်ပေးရန် တောင်းဆိုနိုင်ပါသည်။',
  '7. Your Rights': '၇။ သင့်အခွင့်အရေးများ',
  'Depending on your jurisdiction, you may have the right to access, correct, update, export, or delete your personal information, and to object to or restrict certain processing activities. To exercise any of these rights, please contact us using the details below and we will respond within a reasonable time.':
      'သင့်နိုင်ငံ/ဥပဒေ ကွာခြားမှုရှိနိုင်သော်လည်း သင့်ကိုယ်ရေးအချက်အလက်ကို ဝင်ရောက်ကြည့်ရှုခြင်း၊ ပြင်ဆင်ခြင်း၊ အသစ်ပြင်ဆင်ခြင်း၊ ထုတ်ယူခြင်း သို့ ဖျက်ပစ်ခြင်း ပြုလုပ်ခွင့်၊ အချို့ ဆောင်ရွက်ချက်များကို ကန့်ကွက်ခြင်း သို့ ကန့်သတ်ခြင်း ပြုလုပ်ခွင့် ရှိနိုင်ပါသည်။ ဤအခွင့်အရေးများ အသုံးပြုရန် အောက်ပါအချက်အလက်များဖြင့် ကျွန်ုပ်တို့ထံ ဆက်သွယ်ပါ — သင့်လျော်သော အချိန်အတွင်း ပြန်လည်ဖြေကြားပါမည်။',
  '8. Changes to This Privacy Policy': '၈။ ဤကိုယ်ရေးအချက်အလက်မူဝါဒ ပြောင်းလဲမှုများ',
  'We may update this Privacy Policy from time to time to reflect changes in our practices or applicable law. When we make changes, we will update the "Last Updated" date at the top of this policy and notify you where appropriate. Your continued use of the Service after changes take effect constitutes your acceptance of the revised policy.':
      'ကျွန်ုပ်တို့၏ လုပ်ဆောင်ပုံများ သို့ သက်ဆိုင်သော ဥပဒေ ပြောင်းလဲမှုများကို ထင်ဟပ်စေရန် ဤကိုယ်ရေးအချက်အလက်မူဝါဒကို အခါအားလျော်စွာ ပြင်ဆင်နိုင်ပါသည်။ ပြောင်းလဲမှု ပြုလုပ်သောအခါ ဤမူဝါဒ၏ ထိပ်တွင်ရှိ "နောက်ဆုံးပြင်ဆင်သည့်ရက်"ကို အသစ်ပြင်ဆင်ပြီး သင့်လျော်သလို အကြောင်းကြားပါမည်။ ပြောင်းလဲမှုများ အကျုံးဝင်ပြီးနောက် ဝန်ဆောင်မှုကို ဆက်လက်အသုံးပြုခြင်းသည် ပြင်ဆင်ထားသော မူဝါဒကို သင်လက်ခံကြောင်း ဖြစ်ပါသည်။',
  '9. Contact Us': '၉။ ကျွန်ုပ်တို့ထံ ဆက်သွယ်ရန်',
  'If you have any questions or concerns about this Privacy Policy or how your information is handled, please contact us through the support channels provided within the application.':
      'ဤကိုယ်ရေးအချက်အလက်မူဝါဒ သို့ သင့်အချက်အလက်ကို မည်သို့ကိုင်တွယ်ဆောင်ရွက်သည်နှင့် ပတ်သက်၍ မေးခွန်း သို့ စိုးရိမ်ချက် ရှိပါက အက်ပ်အတွင်း ပေးအပ်ထားသော အထောက်အကူပြု လမ်းကြောင်းများမှတစ်ဆင့် ကျွန်ုပ်တို့ထံ ဆက်သွယ်ပါ။',

  // ── Terms of Service ──
  '1. Acceptance of Terms': '၁။ စည်းမျဉ်းများ လက်ခံခြင်း',
  'By accessing or using Smart POS & Inventory (the "Service"), you agree to be bound by these Terms of Service. If you do not agree to these terms, you may not access or use the Service. Any new features, tools, or content added to the Service are also subject to these terms.':
      'Smart POS & Inventory (ဝန်ဆောင်မှု) ကို ဝင်ရောက်အသုံးပြုခြင်းဖြင့် ဤဝန်ဆောင်မှုစည်းမျဉ်းများနှင့် ချုပ်ကိုင်ခံရမည်ကို သဘောတူညီပါသည်။ ဤစည်းမျဉ်းများနှင့် မသဘောတူပါက ဝန်ဆောင်မှုကို ဝင်ရောက်အသုံးပြု၍ မရပါ။ ဝန်ဆောင်မှုသို့ ထည့်သွင်းသော အသစ်သော လုပ်ဆောင်ချက်များ၊ ကိရိယာများ သို့ အကြောင်းအရာများသည်လည်း ဤစည်းမျဉ်းများနှင့် လိုက်နာရမည် ဖြစ်ပါသည်။',
  '2. Description of Service': '၂။ ဝန်ဆောင်မှု ဖော်ပြချက်',
  'The Service is a point-of-sale and inventory management application that allows you to manage sales, products, categories, packages, stock levels, purchases, and reports for your business. We provide the Service on the terms set out in this agreement.':
      'ဝန်ဆောင်မှုသည် သင့်လုပ်ငန်းအတွက် ရောင်းချမှုများ၊ ကုန်ပစ္စည်းများ၊ အမျိုးအစားများ၊ ပက်ကေ့များ၊ စတော့အတိုင်းအတာများ၊ ဝယ်ယူမှုများနှင့် အစီရင်ခံစာများကို စီမံခန့်ခွဲနိုင်သော ငွေရောင်းငွေယူစနစ်နှင့် ပစ္စည်းစီမံခန့်ခွဲမှု အက်ပ် ဖြစ်ပါသည်။ ကျွန်ုပ်တို့သည် ဤသဘောတူစာချုပ်တွင် ဖော်ပြထားသော စည်းမျဉ်းများဖြင့် ဝန်ဆောင်မှု ပေးအပ်ပါသည်။',
  '3. Account Responsibilities': '၃။ အကောင့် တာဝန်များ',
  'You are responsible for maintaining the confidentiality of your account credentials and for all activity that occurs under your account. You agree to provide accurate and complete information during registration and to keep such information up to date. You must notify us promptly if you suspect any unauthorized use of your account.':
      'သင့်အကောင့် အထောက်အထားများ၏ လျှို့ဝှက်မှုနှင့် အကောင့်အောက်တွင် ဖြစ်ပွားသမျှ လှုပ်ရှားမှုအားလုံးအတွက် သင်တာဝန်ရှိပါသည်။ စာရင်းသွင်းစဉ် မှန်ကန်ပြည့်စုံသော အချက်အလက် ပေးအပ်ပြီး ထိုအချက်အလက်ကို နောက်ဆုံးမြင့်မားအောင် ထိန်းသိမ်းမည်ကို သဘောတူညီပါသည်။ သင့်အကောင့်ကို ခွင့်ပြုချက်မဲ့ အသုံးပြုနေသည်ဟု သံသယရှိပါက ချက်ချင်း အကြောင်းကြားပါ။',
  '4. Acceptable Use': '၄။ လက်ခံနိုင်သော အသုံးပြုပုံ',
  'You agree not to misuse the Service, including attempting to access it using a method other than the interface and instructions we provide, interfering with the Service or its servers, or using the Service to violate any applicable law or regulation. You must not use the Service for any unlawful, harmful, or fraudulent purpose.':
      'ဝန်ဆောင်မှုကို အလွဲသုံးစား မပြုလုပ်မည်ကို သဘောတူညီပါသည် — ကျွန်ုပ်တို့ပေးအပ်သော မျက်နှာပြင်နှင့် ညွှန်ကြားချက်များ မှအပ အခြားနည်းလမ်းဖြင့် ဝင်ရောက်ကြိုးစားခြင်း၊ ဝန်ဆောင်မှု သို့ ဆာဗာများကို နှောင့်ယှက်ခြင်း၊ သက်ဆိုင်သော ဥပဒေနှင့် နည်းဥပဒေများကို ချိုးဖောက်ရန် ဝန်ဆောင်မှုကို အသုံးပြုခြင်း မပါဝင်ပါ။ ဥပဒေမဲ့၊ အန္တရာယ်ရှိ သို့ လှည့်ဖြားသော ရည်ရွယ်ချက်ဖြင့် ဝန်ဆောင်မှုကို အသုံးပြု၍ မရပါ။',
  '5. Your Data and Content': '၅။ သင့်ဒေတာနှင့် အကြောင်းအရာများ',
  'You retain ownership of the business data you enter into the Service. By using the Service, you grant us a limited license to store, process, and display that data solely to provide the Service to you. We do not sell your data and do not use it for any purpose other than operating the Service.':
      'သင် ဝန်ဆောင်မှုထဲ ထည့်သွင်းသော လုပ်ငန်းဒေတာ၏ ပိုင်ဆိုင်မှုကို သင် ဆက်လက်ပိုင်ဆိုင်ပါသည်။ ဝန်ဆောင်မှု အသုံးပြုခြင်းဖြင့် ထိုဒေတာကို သိမ်းဆည်း၊ စီမံနှင့် ပြသရန် သင့်အတွက် ဝန်ဆောင်မှု ပေးအပ်ရုံသာ ကန့်သတ်ထားသော လိုင်စင်ကို ကျွန်ုပ်တို့အား ပေးအပ်ပါသည်။ ကျွန်ုပ်တို့သည် သင့်ဒေတာကို မရောင်းချဘဲ ဝန်ဆောင်မှု အလုပ်လုပ်ရန်မှအပ အခြားရည်ရွယ်ချက်အတွက် အသုံးမပြုပါ။',
  '6. Intellectual Property': '၆။ ပညာရပ်ဆိုင်ရာ ပိုင်ဆိုင်မှု',
  'The Service, including its software, design, text, graphics, and logos, is owned by us or our licensors and is protected by applicable intellectual property laws. You may not copy, modify, distribute, sell, or reverse engineer any part of the Service without our prior written consent.':
      'ဝန်ဆောင်မှု (၎င်း၏ ဆော့ဖ်ဝဲ၊ ဒီဇိုင်း၊ စာသား၊ ဂရပ်ဖစ်နှင့် လိုဂိုများ အပါအဝင်) ကို ကျွန်ုပ်တို့ သို့ ကျွန်ုပ်တို့၏ လိုင်စင်ပေးသူများ ပိုင်ဆိုင်ပြီး သက်ဆိုင်သော ပညာရပ်ဆိုင်ရာ ပိုင်ဆိုင်မှုဥပဒေများဖြင့် ကာကွယ်ထားပါသည်။ ကျွန်ုပ်တို့၏ ယခင်စာဖြင့် သဘောတူညီချက် မရဘဲ ဝန်ဆောင်မှု၏ မည်သည့်အပိုင်းကိုမဆို ကူးယူခြင်း၊ ပြင်ဆင်ခြင်း၊ ဖြန့်ဝေခြင်း၊ ရောင်းချခြင်း သို့ နောက်ပြန်ခွဲခြမ်းစိတ်ဖြာခြင်း မပြုလုပ်ရပါ။',
  '7. Disclaimer of Warranties': '၇။ အာမခံချက် ငြင်းပယ်ခြင်း',
  'The Service is provided on an "as is" and "as available" basis, without warranties of any kind, whether express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, and non-infringement. We do not warrant that the Service will be uninterrupted, timely, secure, or error-free.':
      'ဝန်ဆောင်မှုကို "ရှိသည့်အတိုင်း" နှင့် "ရနိုင်သည့်အတိုင်း" အခြေအနေဖြင့်သာ ပေးအပ်ပြီး မည်သည့်အမျိုးအစား အာမခံချက်မျှ (ဖော်ပြထားသည်ဖြစ်စေ ရိုးရိုးသားသား ယူဆထားသည်ဖြစ်စေ) မပေးပါ — စီးပွားရေးလုပ်ငန်းသုံးနိုင်မှု၊ အထူးရည်ရွယ်ချက်နှင့် ကိုက်ညီမှု၊ ချိုးဖောက်မှုမရှိခြင်း ကဲ့သို့ ရိုးရိုးသားသား ယူဆထားသော အာမခံချက်များ အပါအဝင် (သို့) ကန့်သတ်ချက်မဲ့ပါ။ ဝန်ဆောင်မှု မပြတ်တောက်ဘဲ၊ အချိန်မီ၊ ဘေးကင်းပြီး အမှားကင်းမည်ဟု ကျွန်ုပ်တို့ အာမခံခြင်း မပြုပါ။',
  '8. Limitation of Liability': '၈။ တာဝန်ရှိမှု ကန့်သတ်ချက်',
  'To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits, revenue, data, or goodwill, arising out of or in connection with your use of the Service. Our total aggregate liability to you shall not exceed the amount you paid to use the Service during the twelve months preceding the claim.':
      'ဥပဒေက ခွင့်ပြုထားသော အများဆုံးအတိုင်းအတာအထိ ဝန်ဆောင်မှုအသုံးပြုမှုနှင့် စပ်လျဉ်း၍ ဖြစ်ပေါ်သော သွယ်ဝှက်သော၊ တိုက်ဆိုင်သော၊ အထူးသဖြင့် ဆက်စပ်ဖြစ်ပေါ်သော၊ ပြစ်ဒဏ်ပေးရည်ရွယ်သော ထိခိုက်မှုများ သို့ အမြတ်ငွေ၊ ဝင်ငွေ၊ ဒေတာ သို့ ကောင်းသောနာမည် ဆုံးရှုံးမှုအတွက် ကျွန်ုပ်တို့ တာဝန်မရှိပါ။ တောင်းဆိုမှုမတိုင်မီ ဆယ်လီအတွင်း ဝန်ဆောင်မှုအသုံးပြုရန် သင်ပေးချေခဲ့သော ပမာဏထက် ကျွန်ုပ်တို့၏ စုစုပေါင်း တာဝန်ရှိမှု မကျော်လွန်ပါ။',
  '9. Indemnification': '၉။ လျေ်ာနစ်ပေးချေမှု',
  'You agree to indemnify and hold us harmless from any claims, losses, liabilities, damages, costs, and expenses arising out of your use of the Service, your violation of these Terms, or your infringement of any rights of a third party.':
      'သင့်ဝန်ဆောင်မှုအသုံးပြုမှု၊ ဤစည်းမျဉ်းများ ချိုးဖောက်မှု သို့ တတိယပါတီ၏ အခွင့်အရေးကို ချိုးဖောက်မှုကြောင့် ဖြစ်ပေါ်သော တောင်းဆိုမှုများ၊ ဆုံးရှုံးမှုများ၊ တာဝန်များ၊ ထိခိုက်မှုများ၊ ကုန်ကျစရိတ်များနှင့် အသုံးစရိတ်များအတွက် ကျွန်ုပ်တို့ကို ကာကွယ်ပေးပြီး တာဝန်မဲ့စေမည်ကို သဘောတူညီပါသည်။',
  '10. Termination': '၁၀။ ရပ်ဆိုင်းခြင်း',
  'We may suspend or terminate your access to the Service at any time, with or without notice, if you breach these Terms or if we believe such action is necessary to protect the Service or other users. You may stop using the Service at any time. Upon termination, your right to use the Service ceases immediately.':
      'သင် ဤစည်းမျဉ်းများကို ချိုးဖောက်ပါက သို့ ဝန်ဆောင်မှု သို့ အခြားအသုံးပြုသူများကို ကာကွယ်ရန် ထိုအရေးယူမှု လိုအပ်သည်ဟု ကျွန်ုပ်တို့ ယူဆပါက အချိန်မရွေး၊ အကြောင်းကြားချက် ရှိမရှိ သင့်ဝန်ဆောင်မှု ဝင်ရောက်မှုကို ရပ်ဆိုင်း သို့ အဆုံးသတ်နိုင်ပါသည်။ သင် အချိန်မရွေး ဝန်ဆောင်မှု အသုံးပြုခြင်း ရပ်တန့်နိုင်ပါသည်။ အဆုံးသတ်သောအခါ ဝန်ဆောင်မှုကို အသုံးပြုခွင့် ချက်ချင်း ရပ်တန့်သွားပါသည်။',
  '11. Changes to These Terms': '၁၁။ ဤစည်းမျဉ်းများ ပြောင်းလဲမှုများ',
  'We may revise these Terms of Service from time to time. When we do, we will update the "Last Updated" date at the top of this document and notify you where appropriate. Continued use of the Service after changes take effect constitutes your acceptance of the revised terms.':
      'ကျွန်ုပ်တို့သည် ဤဝန်ဆောင်မှုစည်းမျဉ်းများကို အခါအားလျော်စွာ ပြင်ဆင်နိုင်ပါသည်။ ပြင်ဆင်သောအခါ ဤစာရွက်၏ ထိပ်တွင်ရှိ "နောက်ဆုံးပြင်ဆင်သည့်ရက်"ကို အသစ်ပြင်ဆင်ပြီး သင့်လျော်သလို အကြောင်းကြားပါမည်။ ပြောင်းလဲမှုများ အကျုံးဝင်ပြီးနောက် ဝန်ဆောင်မှု ဆက်လက်အသုံးပြုခြင်းသည် ပြင်ဆင်ထားသော စည်းမျဉ်းများကို သင်လက်ခံကြောင်း ဖြစ်ပါသည်။',
  '12. Governing Law': '၁၂။ လက်နက်ကိုင်ဆောင်ရွက်မှု ဥပဒေ',
  'These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which we operate, without regard to its conflict of law provisions. Any legal action arising out of these Terms shall be brought in the competent courts of that jurisdiction.':
      'ဤစည်းမျဉ်းများကို ကျွန်ုပ်တို့ လုပ်ဆောင်ရာ နိုင်ငံ/နေရာ၏ ဥပဒေများနှင့် အညီ အဓိပ္ပာယ်ဖွင့်ဆိုပြီး စီမံပါမည် — ဥပဒေ ပဋိပက္ခ ပြဋ္ဌာန်းချက်များကို ထည့်မတွက်ဘဲ။ ဤစည်းမျဉ်းများနှင့် စပ်လျဉ်း၍ ဖြစ်ပေါ်သော ဥပဒေအရ အရေးယူမှုကို ထိုနိုင်ငံ/နေရာ၏ တာဝန်ရှိတရားရုံးများတွင် ဦးတိုင်းပြုပါမည်။',
  '13. Contact Us': '၁၃။ ကျွန်ုပ်တို့ထံ ဆက်သွယ်ရန်',
  'If you have any questions about these Terms of Service, please contact us through the support channels provided within the application.':
      'ဤဝန်ဆောင်မှုစည်းမျဉ်းများနှင့် ပတ်သက်၍ မေးခွန်းရှိပါက အက်ပ်အတွင်း ပေးအပ်ထားသော အထောက်အကူပြု လမ်းကြောင်းများမှတစ်ဆင့် ကျွန်ုပ်တို့ထံ ဆက်သွယ်ပါ။',
};
