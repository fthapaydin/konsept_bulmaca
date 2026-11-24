/// İleride Google AdMob (google_mobile_ads) ödüllü video reklam entegrasyonu
/// için hazırlanmış soyut servis katmanı.
abstract class RewardAdService {
  bool get isAvailable;
  Future<bool> showRewardedAd();
}

/// Şu an çevrimdışı / reklamsız modda çalışan yer tutucu servis.
/// AdMob eklendiğinde yalnızca bu sınıfın yerine gerçek AdMob implementasyonu
/// bağlanarak jeton kazanma akışı anında aktif edilebilir.
class PlaceholderRewardAdService implements RewardAdService {
  const PlaceholderRewardAdService();

  @override
  bool get isAvailable => false;

  @override
  Future<bool> showRewardedAd() async => false;
}
