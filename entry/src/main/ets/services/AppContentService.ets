import { CategorySourceType, FoodCategory } from '../models/FoodCategory';
import { Restaurant, RestaurantSourceType } from '../models/Restaurant';
import { LocalStorageAdapter, LocalStorageKeys } from '../storage/LocalStorageContract';

export interface DeleteCategoryResult {
  affectedRestaurantCount: number;
  orphanRestaurantCount: number;
}

export class AppContentService {
  private readonly storage: LocalStorageAdapter;
  private favoriteCategoryIds: string[] = [];
  private favoriteRestaurantIds: string[] = [];
  private customCategories: FoodCategory[] = [];
  private customRestaurants: Restaurant[] = [];

  constructor(storage: LocalStorageAdapter) {
    this.storage = storage;
  }

  async load(): Promise<void> {
    this.favoriteCategoryIds = JSON.parse(await this.storage.getString(LocalStorageKeys.FAVORITE_CATEGORY_IDS, '[]'));
    this.favoriteRestaurantIds =
      JSON.parse(await this.storage.getString(LocalStorageKeys.FAVORITE_RESTAURANT_IDS, '[]'));
    this.customCategories = JSON.parse(await this.storage.getString(LocalStorageKeys.CUSTOM_CATEGORIES, '[]'));
    this.customRestaurants = JSON.parse(await this.storage.getString(LocalStorageKeys.CUSTOM_RESTAURANTS, '[]'));
  }

  getFavoriteCategoryIds(): string[] {
    return this.favoriteCategoryIds.slice();
  }

  getFavoriteRestaurantIds(): string[] {
    return this.favoriteRestaurantIds.slice();
  }

  getCustomCategories(): FoodCategory[] {
    return this.customCategories.slice();
  }

  getCustomRestaurants(): Restaurant[] {
    return this.customRestaurants.slice();
  }

  isFavoriteCategory(categoryId: string): boolean {
    return this.favoriteCategoryIds.indexOf(categoryId) !== -1;
  }

  isFavoriteRestaurant(restaurantId: string): boolean {
    return this.favoriteRestaurantIds.indexOf(restaurantId) !== -1;
  }

  async toggleFavoriteCategory(categoryId: string): Promise<void> {
    this.favoriteCategoryIds = this.toggleId(this.favoriteCategoryIds, categoryId);
    await this.persistFavoriteCategoryIds();
  }

  async toggleFavoriteRestaurant(restaurantId: string): Promise<void> {
    this.favoriteRestaurantIds = this.toggleId(this.favoriteRestaurantIds, restaurantId);
    await this.persistFavoriteRestaurantIds();
  }

  async saveCategory(category: FoodCategory): Promise<void> {
    const normalized: FoodCategory = {
      id: category.id,
      sourceType: CategorySourceType.CUSTOM,
      name: category.name,
      mealPeriods: category.mealPeriods.slice(),
      foodFeelings: category.foodFeelings.slice(),
      spiceLevels: category.spiceLevels.slice(),
      breakfastTraits: category.breakfastTraits.slice()
    };
    const index: number = this.customCategories.findIndex((item: FoodCategory) => item.id === normalized.id);
    if (index === -1) {
      this.customCategories.push(normalized);
    } else {
      this.customCategories[index] = normalized;
    }
    await this.persistCustomCategories();
  }

  async deleteCategory(categoryId: string): Promise<DeleteCategoryResult> {
    this.customCategories = this.customCategories.filter((category: FoodCategory) => category.id !== categoryId);
    this.favoriteCategoryIds = this.favoriteCategoryIds.filter((id: string) => id !== categoryId);
    let affectedRestaurantCount: number = 0;
    let orphanRestaurantCount: number = 0;
    this.customRestaurants = this.customRestaurants.map((restaurant: Restaurant): Restaurant => {
      if (restaurant.categoryIds.indexOf(categoryId) === -1) {
        return restaurant;
      }
      affectedRestaurantCount++;
      const categoryIds: string[] = restaurant.categoryIds.filter((id: string) => id !== categoryId);
      if (categoryIds.length === 0) {
        orphanRestaurantCount++;
      }
      return {
        id: restaurant.id,
        sourceType: restaurant.sourceType,
        name: restaurant.name,
        latitude: restaurant.latitude,
        longitude: restaurant.longitude,
        categoryIds: categoryIds,
        averagePrice: restaurant.averagePrice,
        rating: restaurant.rating,
        businessHours: restaurant.businessHours,
        isOpen: restaurant.isOpen
      };
    });
    await this.persistCustomCategories();
    await this.persistCustomRestaurants();
    await this.persistFavoriteCategoryIds();
    return {
      affectedRestaurantCount: affectedRestaurantCount,
      orphanRestaurantCount: orphanRestaurantCount
    };
  }

  async saveRestaurant(restaurant: Restaurant): Promise<void> {
    const normalized: Restaurant = {
      id: restaurant.id,
      sourceType: RestaurantSourceType.CUSTOM,
      name: restaurant.name,
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      categoryIds: restaurant.categoryIds.slice(),
      averagePrice: restaurant.averagePrice,
      rating: restaurant.rating,
      businessHours: restaurant.businessHours,
      isOpen: restaurant.isOpen
    };
    const index: number = this.customRestaurants.findIndex((item: Restaurant) => item.id === normalized.id);
    if (index === -1) {
      this.customRestaurants.push(normalized);
    } else {
      this.customRestaurants[index] = normalized;
    }
    await this.persistCustomRestaurants();
  }

  async deleteRestaurant(restaurantId: string): Promise<void> {
    this.customRestaurants = this.customRestaurants.filter((restaurant: Restaurant) => restaurant.id !== restaurantId);
    this.favoriteRestaurantIds = this.favoriteRestaurantIds.filter((id: string) => id !== restaurantId);
    await this.persistCustomRestaurants();
    await this.persistFavoriteRestaurantIds();
  }

  private toggleId(ids: string[], id: string): string[] {
    return ids.indexOf(id) === -1 ? ids.concat(id) : ids.filter((item: string) => item !== id);
  }

  private async persistFavoriteCategoryIds(): Promise<void> {
    await this.storage.putString(LocalStorageKeys.FAVORITE_CATEGORY_IDS, JSON.stringify(this.favoriteCategoryIds));
  }

  private async persistFavoriteRestaurantIds(): Promise<void> {
    await this.storage.putString(LocalStorageKeys.FAVORITE_RESTAURANT_IDS, JSON.stringify(this.favoriteRestaurantIds));
  }

  private async persistCustomCategories(): Promise<void> {
    await this.storage.putString(LocalStorageKeys.CUSTOM_CATEGORIES, JSON.stringify(this.customCategories));
  }

  private async persistCustomRestaurants(): Promise<void> {
    await this.storage.putString(LocalStorageKeys.CUSTOM_RESTAURANTS, JSON.stringify(this.customRestaurants));
  }
}
