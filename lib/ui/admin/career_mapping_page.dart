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
  List<String> _selectedCore = [];
  List<String> _selectedSupport = [];

  List<Map<String, String>> _allCareers = [];
  List<Map<String, String>> _allSubplos = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final careerSnap =
        await FirebaseFirestore.instance.collection('career').get();
    final subploSnap =
        await FirebaseFirestore.instance.collection('subplo').get();

    setState(() {
      _allCareers = careerSnap.docs.map((d) {
        final data = d.data();
        return {
          "career_id": data["career_id"]?.toString() ?? d.id,
          "career_thname": data["career_thname"]?.toString() ?? "",
          "career_enname": data["career_enname"]?.toString() ?? "",
        };
      }).toList();

      _allSubplos = subploSnap.docs.map((d) {
        final data = d.data();
        return {
          "subplo_id": data["subplo_id"]?.toString() ?? d.id,
          "subplo_description":
              data["subplo_description"]?.toString() ?? "",
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
        _selectedCore = List<String>.from(data["core_subplo_id"] ?? []);
        _selectedSupport = List<String>.from(data["support_subplo_id"] ?? []);
      });
    }
  }

  Future<void> _saveMapping() async {
    if (_selectedCareer == null) return;

    await FirebaseFirestore.instance
        .collection("career")
        .doc(_selectedCareer)
        .set({
      "core_subplo_id": _selectedCore,
      "support_subplo_id": _selectedSupport,
    }, SetOptions(merge: true));

    // ❌ ลบ SnackBar แจ้งเตือนออก
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Career ↔ SubPLO Mapping"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/config'),
        ),
      ),
      body: (_allCareers.isEmpty || _allSubplos.isEmpty)
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
                _selectedCore.clear();
                _selectedSupport.clear();
                        });
                        await _loadCareerMapping(value["career_id"]!);
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                  const Text("SubPLO Mapping",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom:
                            BorderSide(color: Colors.black.withOpacity(0.08)),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                            child: Text('SubPLO',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13))),
                        SizedBox(width: 8),
                        Text('Core',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        SizedBox(width: 20),
                        Text('Support',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: _allSubplos.map((sub) {
                        final sid = sub["subplo_id"]!;
                        final desc = sub["subplo_description"]!;
                        final isCore = _selectedCore.contains(sid);
                        final isSupport = _selectedSupport.contains(sid);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: Colors.black.withOpacity(0.05)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text("$sid • $desc"),
                              ),
                              Checkbox(
                                value: isCore,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      if (!_selectedCore.contains(sid)) {
                                        _selectedCore.add(sid);
                                      }
                                    } else {
                                      _selectedCore.remove(sid);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Checkbox(
                                value: isSupport,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      if (!_selectedSupport.contains(sid)) {
                                        _selectedSupport.add(sid);
                                      }
                                    } else {
                                      _selectedSupport.remove(sid);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
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
