// Response shape for GET /api/mobile/seller/my-owner.
//
// Used by the mobile Profil tab when the logged-in user is a seller —
// we render the owner's identity (name/phone/avatar) on the top card
// instead of the seller's own, because every other card on that tab
// (Asosiy Balans, Referal hisob, SMS limiti, subscription) is
// owner-scoped data already.

class SellerOwnerResponse {
  final int? id;
  final String? name;
  final String? phoneNumber;
  final String? image;
  final int? shopId;
  final String? shopName;

  const SellerOwnerResponse({
    this.id,
    this.name,
    this.phoneNumber,
    this.image,
    this.shopId,
    this.shopName,
  });

  factory SellerOwnerResponse.fromJson(Map<String, dynamic> json) {
    // The endpoint nests the payload under `data`. Be forgiving in case
    // a future caller passes the inner map directly.
    final src = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    return SellerOwnerResponse(
      id: src['id'] as int?,
      name: src['name'] as String?,
      phoneNumber: src['phone_number'] as String?,
      image: src['image'] as String?,
      shopId: src['shop_id'] as int?,
      shopName: src['shop_name'] as String?,
    );
  }
}
