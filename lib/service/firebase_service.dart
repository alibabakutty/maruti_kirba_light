// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:maruti_kirba_lighting_solutions/models/executive_master_data.dart';

// class FirebaseService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;

//   // constructor creating object
//   FirebaseService();

//   // add executive data to firestore
//   Future<bool> addExecutiveMasterData(
//     ExecutiveMasterData executiveMasterData,
//   ) async {
//     try {
//       await _db
//           .collection('executive_master_data')
//           .add(executiveMasterData.toStoreFirestore());
//       return true;
//     } catch (e) {
//       // ignore: avoid_print
//       print('Error adding executive master data: $e');
//       return false;
//     }
//   }

//   // fetch executivemasterdata by executivename
//   Future<ExecutiveMasterData?> getExecutiveByExecutiveName(
//     String executiveName,
//   ) async {
//     final snapshot = await FirebaseFirestore.instance
//         .collection('executive_master_data')
//         .where('executive_name', isEqualTo: executiveName)
//         .limit(1)
//         .get();

//     if (snapshot.docs.isNotEmpty) {
//       return ExecutiveMasterData.fromFetchFirestore(snapshot.docs.first.data());
//     }
//     return null;
//   }

//   // fetch Executivemasterdata by mobilenumber
//   Future<ExecutiveMasterData?> getExecutiveByMobileNumber(
//     String mobileNumber,
//   ) async {
//     final snapshot = await FirebaseFirestore.instance
//         .collection('executive_master_data')
//         .where('mobile_number', isEqualTo: mobileNumber)
//         .limit(1)
//         .get();

//     if (snapshot.docs.isNotEmpty) {
//       return ExecutiveMasterData.fromFetchFirestore(snapshot.docs.first.data());
//     }
//     return null;
//   }

//   // fetch all executives
//   Future<List<ExecutiveMasterData>> getAllExecutives() async {
//     try {
//       QuerySnapshot snapshot = await _db
//           .collection('executive_master_data')
//           .get();

//       return snapshot.docs
//           .map(
//             (doc) => ExecutiveMasterData.fromFetchFirestore(
//               doc.data() as Map<String, dynamic>,
//             ),
//           )
//           .toList();
//     } catch (e) {
//       return [];
//     }
//   }

//   // update executive master data by executive name
//   Future<bool> updateExecutiveMasterDataByExecutiveName(
//     String oldExecutiveName,
//     ExecutiveMasterData updatedData,
//   ) async {
//     try {
//       // first check if the new no is already taken by another executive
//       if (oldExecutiveName != updatedData.executiveName) {
//         QuerySnapshot duplicateCheck = await _db
//             .collection('executive_master_data')
//             .where('executive_name', isEqualTo: updatedData.executiveName)
//             .limit(1)
//             .get();

//         if (duplicateCheck.docs.isNotEmpty) {
//           return false;
//         }
//       }

//       // Find the document by the old executive name
//       QuerySnapshot snapshot = await _db
//           .collection('executive_master_data')
//           .where('executive_name', isEqualTo: oldExecutiveName)
//           .limit(1)
//           .get();

//       if (snapshot.docs.isNotEmpty) {
//         String docId = snapshot.docs.first.id;
//         await _db.collection('executive_master_data').doc(docId).update({
//           'executive_name': updatedData.executiveName,
//           'mobile_number': updatedData.mobileNumber,
//           'email': updatedData.email,
//           'password': updatedData.password,
//           'created_at': FieldValue.serverTimestamp(),
//         });
//         return true;
//       } else {
//         return false;
//       }
//     } catch (e) {
//       return false;
//     }
//   }

//   // update executive master data by mobile number
//   Future<bool> updateExecutiveMasterDataByMobileNumber(
//     String oldMobileNumber,
//     ExecutiveMasterData updatedData,
//   ) async {
//     try {
//       // first check if the new no is already taken by another executive
//       if (oldMobileNumber != updatedData.mobileNumber) {
//         QuerySnapshot duplicateCheck = await _db
//             .collection('executive_master_data')
//             .where('mobile_number', isEqualTo: updatedData.mobileNumber)
//             .limit(1)
//             .get();

//         if (duplicateCheck.docs.isNotEmpty) {
//           return false;
//         }
//       }

//       // Find the document by the old executive name
//       QuerySnapshot snapshot = await _db
//           .collection('executive_master_data')
//           .where('mobile_number', isEqualTo: oldMobileNumber)
//           .limit(1)
//           .get();

//       if (snapshot.docs.isNotEmpty) {
//         String docId = snapshot.docs.first.id;
//         await _db.collection('executive_master_data').doc(docId).update({
//           'executive_name': updatedData.executiveName,
//           'mobile_number': updatedData.mobileNumber,
//           'email': updatedData.email,
//           'password': updatedData.password,
//           'created_at': FieldValue.serverTimestamp(),
//         });
//         return true;
//       } else {
//         return false;
//       }
//     } catch (e) {
//       return false;
//     }
//   }
// }
