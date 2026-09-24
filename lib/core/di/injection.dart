import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:posfrontend/core/network/api_client.dart';

// Auth
import 'package:posfrontend/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:posfrontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:posfrontend/features/auth/domain/repositories/auth_repository.dart' as auth;
import 'package:posfrontend/features/auth/domain/usecases/login.dart';
import 'package:posfrontend/features/auth/domain/usecases/register.dart';
import 'package:posfrontend/features/auth/domain/usecases/verify_account.dart';
import 'package:posfrontend/features/auth/domain/usecases/forgot_password.dart';

// Product
import 'package:posfrontend/features/product/data/datasources/product_remote_data_source.dart';
import 'package:posfrontend/features/product/data/repositories/product_repository_impl.dart'
    as product_impl;
import 'package:posfrontend/features/product/domain/repositories/product_repository.dart' as product;
import 'package:posfrontend/features/product/domain/repositories/product_detail_repository.dart' as product_detail;
import 'package:posfrontend/features/product/domain/repositories/product_manage_repository.dart' as product_manage;
import 'package:posfrontend/features/product/domain/usecases/get_products.dart';
import 'package:posfrontend/features/product/domain/usecases/get_product_detail.dart';
import 'package:posfrontend/features/product/domain/usecases/product_manage.dart';
import 'package:posfrontend/features/product/domain/usecases/category.dart' as product_cat;

// Sale
import 'package:posfrontend/features/sale/data/datasources/sale_remote_data_source.dart';
import 'package:posfrontend/features/sale/data/repositories/sale_repository_impl.dart' as sale_impl;
import 'package:posfrontend/features/sale/domain/repositories/sale_repository.dart' as sale;
import 'package:posfrontend/features/sale/domain/usecases/sale_usecases.dart';

// Dashboard
import 'package:posfrontend/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:posfrontend/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:posfrontend/features/dashboard/domain/repositories/dashboard_repository.dart';

// Category (standalone)
import 'package:posfrontend/features/category/data/datasources/category_remote_data_source.dart';
import 'package:posfrontend/features/category/data/repositories/category_repository_impl.dart' as cat_impl;
import 'package:posfrontend/features/category/domain/repositories/category_repository.dart';

// Inventory
import 'package:posfrontend/features/inventory/data/datasources/inventory_remote_data_source.dart';
import 'package:posfrontend/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:posfrontend/features/inventory/domain/repositories/inventory_repository.dart';

// Customer
import 'package:posfrontend/features/customer/data/datasources/customer_remote_data_source.dart' as cust_ds;
import 'package:posfrontend/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:posfrontend/features/customer/domain/repositories/customer_repository.dart';

// Profile
import 'package:posfrontend/features/profile/data/datasources/profile_remote_data_source.dart' as prof_ds;
import 'package:posfrontend/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:posfrontend/features/profile/domain/repositories/profile_repository.dart';

// Settings
import 'package:posfrontend/features/settings/data/datasources/settings_remote_data_source.dart' as sett_ds;
import 'package:posfrontend/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:posfrontend/features/settings/domain/repositories/settings_repository.dart';

// Shop
import 'package:posfrontend/features/shop/data/datasources/shop_api_data_source.dart';
import 'package:posfrontend/features/shop/data/datasources/shop_local_data_source.dart';
import 'package:posfrontend/features/shop/data/repositories/shop_api_repository_impl.dart';
import 'package:posfrontend/features/shop/data/repositories/shop_local_repository_impl.dart';
import 'package:posfrontend/features/shop/domain/repositories/shop_repository.dart';

// Package
import 'package:posfrontend/features/package/data/datasources/package_remote_data_source.dart';
import 'package:posfrontend/features/package/data/repositories/package_repository_impl.dart';
import 'package:posfrontend/features/package/domain/repositories/package_repository.dart';

// Purchase
import 'package:posfrontend/features/purchase/data/datasources/purchase_remote_data_source.dart';
import 'package:posfrontend/features/purchase/data/repositories/purchase_repository_impl.dart';
import 'package:posfrontend/features/purchase/domain/repositories/purchase_repository.dart';

// Shared
import 'package:posfrontend/shared/repositories/imgbb_repository.dart';
import 'package:posfrontend/shared/repositories/imgbb_repository_impl.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // Core
  getIt.registerLazySingleton<Dio>(() => ApiClient.instance);

  // Shared
  getIt.registerLazySingleton<ImgbbRepository>(() => ImgbbRepositoryImpl());

  // Auth
  getIt.registerLazySingleton<auth.AuthRepository>(() => AuthRepositoryImpl());
  getIt.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource());
  getIt.registerLazySingleton<LoginUseCase>(() => LoginUseCase(getIt<auth.AuthRepository>()));
  getIt.registerLazySingleton<RegisterUseCase>(() => RegisterUseCase(getIt<auth.AuthRepository>()));
  getIt.registerLazySingleton<SendOtpUseCase>(() => SendOtpUseCase(getIt<auth.AuthRepository>()));
  getIt.registerLazySingleton<VerifyOtpUseCase>(() => VerifyOtpUseCase(getIt<auth.AuthRepository>()));
  getIt.registerLazySingleton<SendForgotPasswordOtpUseCase>(() => SendForgotPasswordOtpUseCase(getIt<auth.AuthRepository>()));
  getIt.registerLazySingleton<VerifyForgotPasswordOtpUseCase>(() => VerifyForgotPasswordOtpUseCase(getIt<auth.AuthRepository>()));
  getIt.registerLazySingleton<ResetPasswordUseCase>(() => ResetPasswordUseCase(getIt<auth.AuthRepository>()));

  // Product
  getIt.registerLazySingleton<ProductRemoteDataSource>(() => ProductRemoteDataSource());
  getIt.registerLazySingleton<product.ProductRepository>(() => product_impl.ProductRepositoryImpl(remoteDataSource: getIt()));
  getIt.registerLazySingleton<product_detail.ProductDetailRepository>(() => product_impl.ProductDetailRepositoryImpl(remoteDataSource: getIt()));
  getIt.registerLazySingleton<product_manage.ProductManageRepository>(() => product_impl.ProductManageRepositoryImpl(remoteDataSource: getIt()));
  getIt.registerLazySingleton<GetProductsUseCase>(() => GetProductsUseCase(getIt<product.ProductRepository>()));
  getIt.registerLazySingleton<DeleteProductUseCase>(() => DeleteProductUseCase(getIt<product.ProductRepository>()));
  getIt.registerLazySingleton<GetProductDetailUseCase>(() => GetProductDetailUseCase(getIt<product_detail.ProductDetailRepository>()));
  getIt.registerLazySingleton<SearchProductsUseCase>(() => SearchProductsUseCase(getIt<product_manage.ProductManageRepository>()));
  getIt.registerLazySingleton<GetSuppliersUseCase>(() => GetSuppliersUseCase(getIt<product_manage.ProductManageRepository>()));
  getIt.registerLazySingleton<GetPackagesForProductUseCase>(() => GetPackagesForProductUseCase(getIt<product_manage.ProductManageRepository>()));
  getIt.registerLazySingleton<CreateProductUseCase>(() => CreateProductUseCase(getIt<product_manage.ProductManageRepository>()));
  getIt.registerLazySingleton<UpdateProductUseCase>(() => UpdateProductUseCase(getIt<product_manage.ProductManageRepository>()));

  // Product Category
  getIt.registerLazySingleton<product_manage.CategoryRepository>(() => product_impl.CategoryRepositoryImpl(remoteDataSource: getIt()));
  getIt.registerLazySingleton<product_cat.GetCategoriesUseCase>(() => product_cat.GetCategoriesUseCase(getIt<product_manage.CategoryRepository>()));
  getIt.registerLazySingleton<product_cat.CreateCategoryUseCase>(() => product_cat.CreateCategoryUseCase(getIt<product_manage.CategoryRepository>()));
  getIt.registerLazySingleton<product_cat.UpdateCategoryUseCase>(() => product_cat.UpdateCategoryUseCase(getIt<product_manage.CategoryRepository>()));

  // Sale
  getIt.registerLazySingleton<SaleRemoteDataSource>(() => SaleRemoteDataSource());
  getIt.registerLazySingleton<sale.SaleRepository>(() => sale_impl.SaleRepositoryImpl());
  getIt.registerLazySingleton<sale.OrderRepository>(() => sale_impl.OrderRepositoryImpl());
  getIt.registerLazySingleton<sale.SaleHistoryRepository>(() => sale_impl.SaleHistoryRepositoryImpl());
  getIt.registerLazySingleton<CreateSaleUseCase>(() => CreateSaleUseCase(getIt<sale.SaleRepository>()));
  getIt.registerLazySingleton<CreateOrderUseCase>(() => CreateOrderUseCase(getIt<sale.OrderRepository>()));
  getIt.registerLazySingleton<DeleteOrderUseCase>(() => DeleteOrderUseCase(getIt<sale.OrderRepository>()));
  getIt.registerLazySingleton<GetSalesUseCase>(() => GetSalesUseCase(getIt<sale.SaleHistoryRepository>()));
  getIt.registerLazySingleton<GetOrdersUseCase>(() => GetOrdersUseCase(getIt<sale.SaleHistoryRepository>()));
  getIt.registerLazySingleton<DeleteSaleUseCase>(() => DeleteSaleUseCase(getIt<sale.SaleHistoryRepository>()));
  getIt.registerLazySingleton<DeleteSaleItemUseCase>(() => DeleteSaleItemUseCase(getIt<sale.SaleHistoryRepository>()));

  // Dashboard
  getIt.registerLazySingleton<DashboardRemoteDataSource>(() => DashboardRemoteDataSource());
  getIt.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl());

  // Category (standalone)
  getIt.registerLazySingleton<CategoryRemoteDataSource>(() => CategoryRemoteDataSource());
  getIt.registerLazySingleton<CategoryRepository>(() => cat_impl.CategoryRepositoryImpl());

  // Inventory
  getIt.registerLazySingleton<InventoryRemoteDataSource>(() => InventoryRemoteDataSource());
  getIt.registerLazySingleton<InventoryRepository>(() => InventoryRepositoryImpl());

  // Customer
  getIt.registerLazySingleton<cust_ds.CustomerRemoteDataSource>(() => cust_ds.CustomerRemoteDataSourceImpl(getIt<Dio>()));
  getIt.registerLazySingleton<CustomerRepository>(() => CustomerRepositoryImpl());

  // Profile
  getIt.registerLazySingleton<prof_ds.ProfileRemoteDataSource>(() => prof_ds.ProfileRemoteDataSourceImpl(getIt<Dio>()));
  getIt.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl());

  // Settings
  getIt.registerLazySingleton<sett_ds.SettingsRemoteDataSource>(() => sett_ds.SettingsRemoteDataSourceImpl(getIt<Dio>()));
  getIt.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl());

  // Shop
  getIt.registerLazySingleton<ShopApiDataSource>(() => ShopApiDataSource());
  getIt.registerLazySingleton<ShopLocalDataSource>(() => ShopLocalDataSource());
  getIt.registerLazySingleton<ShopApiRepository>(() => ShopApiRepositoryImpl());
  getIt.registerLazySingleton<ShopLocalRepository>(() => ShopLocalRepositoryImpl());

  // Package
  getIt.registerLazySingleton<PackageRemoteDataSource>(() => PackageRemoteDataSource());
  getIt.registerLazySingleton<PackageRepository>(() => PackageRepositoryImpl());

  // Purchase
  getIt.registerLazySingleton<PurchaseRemoteDataSource>(() => PurchaseRemoteDataSource());
  getIt.registerLazySingleton<PurchaseItemRepository>(() => PurchaseRepositoryImpl());
}
