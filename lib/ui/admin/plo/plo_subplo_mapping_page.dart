// lib/ui/admin/plo_subplo_mapping_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';

class PLOSubPLOMappingPage extends StatefulWidget {
  const PLOSubPLOMappingPage({super.key});

  @override
  State<PLOSubPLOMappingPage> createState() => _PLOSubPLOMappingPageState();
}

class _PLOSubPLOMappingPageState extends State<PLOSubPLOMappingPage> {
  static const _primary = Color(0xFF3D5CFF);

  String? _selectedPLO;
  List<String> _selectedSubPLOs = [];

  List<Map<String, String>> _allPLOs = [];
  List<Map<String, String>> _allSubPLOs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final ploSnap = await FirebaseFirestore.instance.collection('plo').get();
    final subploSnap =
        await FirebaseFirestore.instance.collection('subplo').get();

    setState(() {
      _allPLOs = ploSnap.docs.map((d) {
        final data = d.data();
        return {
          "plo_id": data["plo_id"]?.toString() ?? d.id,
          "plo_description": data["plo_description"]?.toString() ?? "",
        };
      }).toList();

      _allSubPLOs = subploSnap.docs.map((d) {
        final data = d.data();
        return {
          "subplo_id": data["subplo_id"]?.toString() ?? d.id,
          "subplo_description": data["subplo_description"]?.toString() ?? "",
        };
      }).toList();
    });
  }

  Future<void> _loadPloMapping(String ploId) async {
    final doc =
        await FirebaseFirestore.instance.collection("plo").doc(ploId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _selectedSubPLOs = List<String>.from(data["subplo_id"] ?? []);
      });
    }
  }

  Future<void> _saveMapping() async {
    if (_selectedPLO == null) return;

    await FirebaseFirestore.instance.collection("plo").doc(_selectedPLO).update({
      "subplo_id": _selectedSubPLOs,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ PLO ↔ SubPLO Mapping updated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("PLO ↔ SubPLO Mapping"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/config'),
        ),
      ),
      body: (_allPLOs.isEmpty || _allSubPLOs.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("เลือก PLO",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),

                  // ✅ Searchable Dropdown
                  DropdownSearch<Map<String, String>>(
                    items: _allPLOs,
                    itemAsString: (p) =>
                        "${p["plo_id"]} • ${p["plo_description"]}",
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "ค้นหา PLO...",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(8),
                        ),
                      ),
                    ),
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          _selectedPLO = value["plo_id"];
                          _selectedSubPLOs.clear();
                        });
                        await _loadPloMapping(value["plo_id"]!);
                      }
                    },
                  ),

                  const SizedBox(height: 20),
                  const Text("เลือก SubPLOs",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Expanded(
                    child: ListView(
                      children: _allSubPLOs.map((sub) {
                        final sid = sub["subplo_id"]!;
                        final desc = sub["subplo_description"]!;
                        final selected = _selectedSubPLOs.contains(sid);
                        return CheckboxListTile(
                          title: Text("$sid • $desc"),
                          value: selected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedSubPLOs.add(sid);
                              } else {
                                _selectedSubPLOs.remove(sid);
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