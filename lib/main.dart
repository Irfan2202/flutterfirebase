import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  final CollectionReference _absensi =
  FirebaseFirestore.instance.collection("absensi");

  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = "update";
      _namaController.text = documentSnapshot['nama'];
      _statusController.text = documentSnapshot['status'];
    }

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Siswa',
                  ),
                ),
                TextField(
                  controller: _statusController,
                  decoration: const InputDecoration(
                    labelText: 'Status Siswa',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final String nama = _namaController.text;
                    final String status = _statusController.text;

                    if (nama.isNotEmpty && status.isNotEmpty) {
                      if (action == 'create') {
                        await _absensi.add({
                          "nama": nama,
                          "status": status,
                        });
                      } else {
                        await _absensi.doc(documentSnapshot!.id).update({
                          "nama": nama,
                          "status": status,
                        });
                      }

                      _namaController.clear();
                      _statusController.clear();

                      if (modalContext.mounted) {
                        Navigator.of(modalContext).pop();
                      }
                    }
                  },
                  child: Text(action == "create" ? "Create" : "Update"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, String absensiID) async {
    final messenger = ScaffoldMessenger.of(context);
    await _absensi.doc(absensiID).delete();

    messenger.showSnackBar(
      const SnackBar(content: Text("Data Berhasil Dihapus")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Firebase"),
      ),
      body: StreamBuilder(
        stream: _absensi.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(documentSnapshot['nama']),
                    subtitle: Text(documentSnapshot['status']),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              _createOrUpdate(documentSnapshot);
                            },
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () {
                              _delete(context, documentSnapshot.id);
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createOrUpdate,
        child: const Icon(Icons.add),
      ),
    );
  }
}
