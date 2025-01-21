import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social/features/profile/domain/entities/profile_user.dart';
import 'package:social/features/search/domain/repo/search_repo.dart';

class FirebaseSearchRepo implements SearchRepo {

  @override
  Future<List<ProfileUser?>> searchusers(String query) async {
    try {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      return result.docs.map((e) => ProfileUser.fromJson(e.data())).toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
