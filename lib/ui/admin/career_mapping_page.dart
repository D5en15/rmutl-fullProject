// lib/ui/admin/career_mapping_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';

class CareerMappingPage extends StatefulWidget {
  const CareerMappingPage({super.key});

  @override
  State<CareerMappingPage> createState() => _CareerMappingPageState();
}

class _CareerMappingPageState extends State<CareerMappingPage> {
  static const _primary = Color(0xFF3D5CFF);

  String? _selectedCareer;
  List<String> _selectedPLOs = [];

  List<Map<String, String>> _allCareers = [];
  List<Map<String, String>> _allPLOs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final careerSnap =
        await FirebaseFirestore.instance.collection('career').get();
    final ploSnap =
        await FirebaseFirestore.instance.collection('plo').get();

    setState(() {
      _allCareers = careerSnap.docs.map((d) {
        final data = d.data();
        return {
          "career_id": data["career_id"]?.toString() ?? d.id,
          "career_thname": data["career_thname"]?.toString() ?? "",
          "career_enname": data["career_enname"]?.toString() ?? "",
        };
      }).toList();

      _allPLOs = ploSnap.docs.map((d) {
        final data = d.data();
        return {
          "plo_id": data["plo_id"]?.toString() ?? d.id,
          "plo_description": data["plo_description"]?.toString() ?? "",
        };
      }).toList();
    });
  }

  Future<void> _loadCareerMapping(String careerId) async {
    final doc = await FirebaseFirestore.instance
        .collection("career")
        .doc(careerId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _selectedPLOs = List<String>.from(data["plo_id"] ?? []);
      });
    }
  }

  Future<void> _saveMapping() async {
    if (_selectedCareer == null) return;

    await FirebaseFirestore.instance
        .collection("career")
        .doc(_selectedCareer)
        .update({
      "plo_id": _selectedPLOs,
    });

    // ❌ ลบ SnackBar แจ้งเตือนออก
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Career ↔ PLO Mapping"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/config'),
        ),
      ),
      body: (_allCareers.isEmpty || _allPLOs.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("เลือก Career",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),

                  // ✅ Searchable Dropdown
                  DropdownSearch<Map<String, String>>(
                    items: _allCareers,
                    itemAsString: (c) =>
                        "${c["career_id"]} • ${c["career_thname"]} (${c["career_enname"]})",
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "ค้นหา Career...",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(8),
                        ),
                      ),
                    ),
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          _selectedCareer = value["career_id"];
                          _selectedPLOs.clear();
                        });
                        await _loadCareerMapping(value["career_id"]!);
                      }
                    },
                  ),

                  const SizedBox(height: 20),
                  const Text("เลือก PLOs",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Expanded(
                    child: ListView(
                      children: _allPLOs.map((plo) {
                        final pid = plo["plo_id"]!;
                        final desc = plo["plo_description"]!;
                        final selected = _selectedPLOs.contains(pid);
                        return CheckboxListTile(
                          title: Text("$pid • $desc"),
                          value: selected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedPLOs.add(pid);
                              } else {
                                _selectedPLOs.remove(pid);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveMapping,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text("บันทึก Mapping"),
                  )
                ],
              ),
            ),
    );
  }
}