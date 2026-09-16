import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:posfrontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:posfrontend/features/auth/domain/repositories/auth_repository.dart' as auth;
import 'package:posfrontend/features/auth/domain/usecases/login.dart';
import 'package:posfrontend/features/auth/domain/usecases/register.dart';
import 'package:posfrontend/features/auth/domain/usecases/verify_account.dart';
import 'package:posfrontend/features/auth/domain/usecases/forgot_password.dart';
import 'package:posfrontend/features/product/data/datasources/product_remote_data_source.dart';
import 'package:posfrontend/features/product/data/repositories/product_repository_impl.dart';
import 'package:posfrontend/features/product/domain/repositories/product_repository.dart' as product;
import 'package:posfrontend/features/product/domain/repositories/product_detail_repository.dart' as product_detail;
import 'package:posfrontend/features/product/domain/repositories/product_manage_repository.dart' as product_manage;
import 'package:posfrontend/features/product/domain/usecases/get_products.dart';
import 'package:posfrontend/features/product/domain/usecases/get_product_detail.dart';
import 'package:posfrontend/features/product/domain/usecases/product_manage.dart';
import 'package:posfrontend/features/product/domain/usecases/category.dart';
import 'package:posfrontend/features/sale/data/datasources/sale_remote_data_source.dart';
import 'package:posfrontend/features/sale/data/repositories/sale_repository_impl.dart'
    as sale_impl;
import 'package:posfrontend/features/sale/domain/repositories/sale_repository.dart' as sale;
import 'package:posfrontend/features/sale/domain/usecases/sale_usecases.dart';
import 'package:posfrontend/features/sale/presentation/viewmodels/sale_history_view_model.dart';
import 'package:posfrontend/modules/customer/repository/customer_repository.dart';
import 'package:posfrontend/modules/customer/repository/customer_repository_impl.dart';
import 'package:posfrontend/modules/product/repository/catalog_product_repository.dart';
import 'package:posfrontend/modules/product/repository/catalog_product_repository_impl.dart';
import 'package:posfrontend/modules/product/repository/product_create_repository.dart';
import 'package:posfrontend/modules/product/repository/product_create_repository_impl.dart';
import 'package:posfrontend/modules/inventory/repository/inventory_repository.dart';
import 'package:posfrontend/modules/inventory/repository/inventory_repository_impl.dart';
import 'package:posfrontend/modules/sale/repository/sale_product_repository.dart';
import 'package:posfrontend/modules/sale/repository/sale_product_repository_impl.dart';
import 'package:posfrontend/modules/sale_items/repository/sale_item_repository.dart';
import 'package:posfrontend/modules/sale_items/repository/sale_item_repository_impl.dart';
import 'package:posfrontend/modules/package/repository/package_repository.dart';
import 'package:posfrontend/modules/package/repository/package_repository_impl.dart';
import 'package:posfrontend/modules/shop/repository/shop_api_repository.dart';
import 'package:posfrontend/modules/shop/repository/shop_api_repository_impl.dart';
import 'package:posfrontend/modules/shop/repository/shop_local_repository.dart';
import 'package:posfrontend/modules/shop/repository/shop_local_repository_impl.dart';
import 'package:posfrontend/modules/dashboard/repository/dashboard_repository.dart';
import 'package:posfrontend/modules/dashboard/repository/dashboard_repository_impl.dart';
import 'package:posfrontend/modules/settings/repository/setting_repository.dart';
import 'package:posfrontend/modules/settings/repository/setting_repository_impl.dart';
import 'package:posfrontend/modules/login/repository/login_repository.dart';
import 'package:posfrontend/modules/login/repository/login_repository_impl.dart';
import 'package:posfrontend/modules/verify_account/repository/verify_account_repository.dart';
import 'package:posfrontend/modules/verify_account/repository/verify_account_repository_impl.dart';
import 'package:posfrontend/modules/forgot_password/repository/forgot_password_repository.dart';
import 'package:posfrontend/modules/forgot_password/repository/forgot_password_repository_impl.dart';
import 'package:posfrontend/modules/profile/repository/profile_repository.dart';
import 'package:posfrontend/modules/profile/repository/profile_repository_impl.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository_impl.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // ---------------------------------------------------------------------------
  // Core
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<Dio>(() => ApiClient.instance);

  // ---------------------------------------------------------------------------
  // Shared repositories
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<ImgbbRepository>(() => ImgbbRepositoryImpl());

  // ---------------------------------------------------------------------------
  // Auth / Login / Register / Verify / ForgotPassword
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<LoginRepository>(() => LoginRepositoryImpl());
  getIt.registerLazySingleton<auth.AuthRepository>(() => AuthRepositoryImpl());
  getIt.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource());
  getIt.registerLazySingleton<LoginUseCase>(() => LoginUseCase(getIt<auth.AuthRepository>()));
  getIt.registerLazySingleton<RegisterUseCase>(() => RegisterUseCase(getIt<auth.AuthRepository>()));
  getIt.registerLazySingleton<SendOtpUseCase>(() => SendOtpUseCase(getIt<auth.AuthRepository>()));
  getIt.registerLazySingleton<VerifyOtpUseCase>(() => VerifyOtpUseCase(getIt<auth.AuthRepository>()));
  getIt.registerLazySingleton<SendForgotPasswordOtpUseCase>(() => SendForgotPasswordOtpUseCase(getIt<auth.AuthRepository>()));
  getIt.registerLazySingleton<VerifyForgotPasswordOtpUseCase>(() => VerifyForgotPasswordOtpUseCase(getIt<auth.AuthRepository>()));
  getIt.registerLazySingleton<ResetPasswordUseCase>(() => ResetPasswordUseCase(getIt<auth.AuthRepository>()));
  getIt.registerLazySingleton<VerifyAccountRepository>(() => VerifyAccountRepositoryImpl());
  getIt.registerLazySingleton<ForgotPasswordRepository>(() => ForgotPasswordRepositoryImpl());

  // ---------------------------------------------------------------------------
  // Shop
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<ShopApiRepository>(() => ShopApiRepositoryImpl());
  getIt.registerLazySingleton<ShopLocalRepository>(() => ShopLocalRepositoryImpl());

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl());

  // ---------------------------------------------------------------------------
  // Customer
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<CustomerRepository>(() => CustomerRepositoryImpl());

  // ---------------------------------------------------------------------------
  // Product
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<ProductRemoteDataSource>(() => ProductRemoteDataSource());
  getIt.registerLazySingleton<product.ProductRepository>(() => ProductRepositoryImpl(remoteDataSource: getIt()));
  getIt.registerLazySingleton<product_detail.ProductDetailRepository>(() => ProductDetailRepositoryImpl(remoteDataSource: getIt()));
  getIt.registerLazySingleton<product_manage.ProductManageRepository>(() => ProductManageRepositoryImpl(remoteDataSource: getIt()));
  getIt.registerLazySingleton<CatalogProductRepository>(() => CatalogProductRepositoryImpl());
  getIt.registerLazySingleton<ProductCreateRepository>(() => ProductCreateRepositoryImpl());

  // Use cases
  getIt.registerLazySingleton<GetProductsUseCase>(() => GetProductsUseCase(getIt<product.ProductRepository>()));
  getIt.registerLazySingleton<DeleteProductUseCase>(() => DeleteProductUseCase(getIt<product.ProductRepository>()));
  getIt.registerLazySingleton<GetProductDetailUseCase>(() => GetProductDetailUseCase(getIt<product_detail.ProductDetailRepository>()));
  getIt.registerLazySingleton<SearchProductsUseCase>(() => SearchProductsUseCase(getIt<product_manage.ProductManageRepository>()));
  getIt.registerLazySingleton<GetSuppliersUseCase>(() => GetSuppliersUseCase(getIt<product_manage.ProductManageRepository>()));
  getIt.registerLazySingleton<GetPackagesForProductUseCase>(() => GetPackagesForProductUseCase(getIt<product_manage.ProductManageRepository>()));
  getIt.registerLazySingleton<CreateProductUseCase>(() => CreateProductUseCase(getIt<product_manage.ProductManageRepository>()));
  getIt.registerLazySingleton<UpdateProductUseCase>(() => UpdateProductUseCase(getIt<product_manage.ProductManageRepository>()));

  // ---------------------------------------------------------------------------
  // Category
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<product_manage.CategoryRepository>(() => CategoryRepositoryImpl(remoteDataSource: getIt()));
  getIt.registerLazySingleton<GetCategoriesUseCase>(() => GetCategoriesUseCase(getIt<product_manage.CategoryRepository>()));
  getIt.registerLazySingleton<CreateCategoryUseCase>(() => CreateCategoryUseCase(getIt<product_manage.CategoryRepository>()));
  getIt.registerLazySingleton<UpdateCategoryUseCase>(() => UpdateCategoryUseCase(getIt<product_manage.CategoryRepository>()));

  // ---------------------------------------------------------------------------
  // Inventory
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<InventoryRepository>(() => InventoryRepositoryImpl());

  // ---------------------------------------------------------------------------
  // Sale (new feature layer)
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<SaleRemoteDataSource>(() => SaleRemoteDataSource());
  getIt.registerLazySingleton<sale.SaleRepository>(() => sale_impl.SaleRepositoryImpl());
  getIt.registerLazySingleton<sale.OrderRepository>(() => sale_impl.OrderRepositoryImpl());
  getIt.registerLazySingleton<sale.SaleHistoryRepository>(() => sale_impl.SaleHistoryRepositoryImpl());
  getIt.registerLazySingleton<SaleProductRepository>(() => SaleProductRepositoryImpl());

  // Sale use cases
  getIt.registerLazySingleton<CreateSaleUseCase>(() => CreateSaleUseCase(getIt<sale.SaleRepository>()));
  getIt.registerLazySingleton<CreateOrderUseCase>(() => CreateOrderUseCase(getIt<sale.OrderRepository>()));
  getIt.registerLazySingleton<DeleteOrderUseCase>(() => DeleteOrderUseCase(getIt<sale.OrderRepository>()));
  getIt.registerLazySingleton<GetSalesUseCase>(() => GetSalesUseCase(getIt<sale.SaleHistoryRepository>()));
  getIt.registerLazySingleton<GetOrdersUseCase>(() => GetOrdersUseCase(getIt<sale.SaleHistoryRepository>()));
  getIt.registerLazySingleton<DeleteSaleUseCase>(() => DeleteSaleUseCase(getIt<sale.SaleHistoryRepository>()));
  getIt.registerLazySingleton<DeleteSaleItemUseCase>(() => DeleteSaleItemUseCase(getIt<sale.SaleHistoryRepository>()));

  // Sale history ViewModel
  getIt.registerLazySingleton<SaleHistoryViewModel>(() => SaleHistoryViewModel(
        getSalesUseCase: getIt(),
        getOrdersUseCase: getIt(),
        deleteSaleUseCase: getIt(),
        deleteOrderUseCase: getIt(),
        deleteSaleItemUseCase: getIt(),
      ));

  // ---------------------------------------------------------------------------
  // Sale Items (history) — legacy, kept for screens not yet migrated
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<SaleItemRepository>(() => SaleItemRepositoryImpl());

  // ---------------------------------------------------------------------------
  // Package
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<PackageRepository>(() => PackageRepositoryImpl());

  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl());

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<SettingRepository>(() => SettingRepositoryImpl());
}
