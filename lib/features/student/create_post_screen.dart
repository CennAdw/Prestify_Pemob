import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();

  // Mencari Anggota fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillsController = TextEditingController(text: 'Flutter, UI/UX, Pitching');
  final _competitionController = TextEditingController(text: 'GEMASTIK XVII');
  final _notesController = TextEditingController();
  final _maxMembersController = TextEditingController(text: '5'); // Controller baru untuk input angka

  // Mencari Tim fields
  final _cariTimTitleController = TextEditingController();
  final _cariTimDescController = TextEditingController();
  final _cariTimSkillsController = TextEditingController(text: 'Flutter, UI/UX');
  final _cariTimCompetitionController = TextEditingController(text: 'GEMASTIK XVII');
  final _cariTimNotesController = TextEditingController();

  String _postType = 'Mencari Anggota';
  bool _isPublishing = false;

  final _postTypes = const ['Mencari Anggota', 'Mencari Tim'];
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _posterBytes;
  String? _posterFileName;
  String? _posterContentType;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    _competitionController.dispose();
    _notesController.dispose();
    _maxMembersController.dispose();
    _cariTimTitleController.dispose();
    _cariTimDescController.dispose();
    _cariTimSkillsController.dispose();
    _cariTimCompetitionController.dispose();
    _cariTimNotesController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final state = AppStateScope.of(context);
    setState(() => _isPublishing = true);

    final maxMembers = int.tryParse(_maxMembersController.text) ?? 5;
    String message;
    
    if (_postType == 'Mencari Anggota') {
      message = await state.publishRecruitmentPost(
        type: _postType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        skills: _skillsController.text.trim(),
        competition: _competitionController.text.trim(),
        maxMembers: maxMembers,
        posterBytes: _posterBytes,
        posterFileName: _posterFileName,
        posterContentType: _posterContentType,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _posterBytes = null;
          _posterFileName = null;
          _posterContentType = null;
          _maxMembersController.text = '5';
        });
        _titleController.clear();
        _descriptionController.clear();
        _notesController.clear();
      }
    } else {
      message = await state.publishAnggotaPost(
        title: _cariTimTitleController.text.trim(),
        description: _cariTimDescController.text.trim(),
        skills: _cariTimSkillsController.text.trim(),
        competition: _cariTimCompetitionController.text.trim(),
        notes: _cariTimNotesController.text.trim().isEmpty
            ? null
            : _cariTimNotesController.text.trim(),
      );
      if (mounted) {
        _cariTimTitleController.clear();
        _cariTimDescController.clear();
        _cariTimNotesController.clear();
      }
    }

    if (!mounted) return;
    setState(() => _isPublishing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPoster() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 84,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _posterBytes = bytes;
      _posterFileName = picked.name;
      _posterContentType = picked.mimeType ?? 'image/jpeg';
    });
  }

    void _updateMembersCount(int delta) {
        // Amankan pengambilan teks agar tidak memicu error 'undefined' di web
        final String currentText = _maxMembersController.text;
        final int current = int.tryParse(currentText) ?? 5;
        
        final int updated = current + delta;
        
        // Batasi minimal 2 dan maksimal 20 orang
        if (updated >= 2 && updated <= 20) {
          setState(() {
            _maxMembersController.text = updated.toString();
          });
        }
      }

  InputDecoration _inputDecoration(String label, {String? hint, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: prefix,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.alertCoral),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final recentTeams = state.teams.take(3).toList();

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Background abu-abu tipis premium ala iOS/Web modern
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER UTAMA ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Buat Postingan', style: AppTextStyles.headline.copyWith(fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          'Publikasikan kebutuhan mencari tim atau anggota kompetisi.',
                          style: AppTextStyles.body.copyWith(color: AppColors.textGray, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.maps_ugc_rounded, color: AppColors.primaryBlue, size: 24),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // ── TAB SELECTOR (MENCARI ANGGOTA / TIM) ───────────────────────
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: _postTypes.map((type) {
                    final selected = _postType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _postType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: selected
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                type == 'Mencari Tim' ? Icons.person_search_rounded : Icons.group_add_rounded,
                                color: selected ? AppColors.primaryBlue : AppColors.textGray,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                type,
                                style: TextStyle(
                                  color: selected ? Colors.black87 : AppColors.textGray,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // ── CONTAINER FORM UTAMA (DIBUNGKUS CARD ELEVATED) ─────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _postType == 'Mencari Anggota' ? _buildCariAnggotaForm() : _buildCariTimForm(),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── RECRUITMENT TERBARU SECTION ────────────────────────────────
              const SectionHeader(title: 'Tim Recruitment Terbaru'),
              const SizedBox(height: 12),

              if (state.isTeamsLoading) ...[
                const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    color: AppColors.primaryBlue,
                    backgroundColor: AppColors.borderLight,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              if (recentTeams.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(
                      'Belum ada tim terbaru.',
                      style: AppTextStyles.body.copyWith(color: AppColors.textGray, fontStyle: FontStyle.italic),
                    ),
                  ),
                )
              else
                ...recentTeams.map(
                  (team) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.groups_rounded, color: AppColors.primaryBlue, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(team.name, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                Text(team.competitionName, style: AppTextStyles.small.copyWith(color: AppColors.textGray)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.successGreenLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              team.status,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.successGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form: Mencari Anggota ─────────────────────────────────────────────────
  Widget _buildCariAnggotaForm() {
    return Column(
      key: const ValueKey('CariAnggotaForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _titleController,
          decoration: _inputDecoration(
            'Nama tim',
            hint: 'Contoh: Tim Prestify Dev',
            prefix: const Icon(Icons.badge_outlined, color: AppColors.primaryBlue, size: 20),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Nama tim wajib diisi' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          minLines: 3,
          maxLines: 5,
          decoration: _inputDecoration(
            'Deskripsi tim & kebutuhan',
            hint: 'Ceritakan tentang visi tim dan kriteria spesifik anggota yang dicari.',
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _skillsController,
          decoration: _inputDecoration(
            'Skill yang dibutuhkan',
            hint: 'Pisahkan dengan koma (contoh: Flutter, UI/UX)',
            prefix: const Icon(Icons.psychology_outlined, color: AppColors.primaryBlue, size: 20),
          ),
        ),
        const SizedBox(height: 18),

        // 🔢 BAGIAN INPUT JUMLAH ANGGOTA BARU (+ / - DAN TEXT FIELD)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Maksimal Anggota', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Rentang batasan: 2 - 20 orang', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Memastikan ukuran kontainer pas
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18, color: Colors.black87),
                    onPressed: () => _updateMembersCount(-1),
                  ),
                  SizedBox(
                    width: 50,
                    child: TextField( // Diubah dari TextFormField ke TextField biasa agar lebih ringan di Web
                      controller: _maxMembersController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryBlue),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (v) {
                        // Jaga-jaga jika user mengetik manual angka di luar batas
                        final val = int.tryParse(v);
                        if (val != null && (val < 2 || val > 20)) {
                          // Kembalikan ke angka aman jika ngaco
                          _maxMembersController.text = '5'; 
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18, color: Colors.black87),
                    onPressed: () => _updateMembersCount(1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        
        TextFormField(
          controller: _competitionController,
          decoration: _inputDecoration(
            'Nama kompetisi/lomba',
            hint: 'Contoh: GEMASTIK XVII 2026',
            prefix: const Icon(Icons.emoji_events_outlined, color: AppColors.primaryBlue, size: 20),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Nama lomba wajib diisi' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          minLines: 2,
          maxLines: 3,
          decoration: _inputDecoration(
            'Catatan tambahan (opsional)',
            hint: 'Bisa berupa benefit, id line/WA, link grup dsb.',
          ),
        ),
        const SizedBox(height: 20),

        // 🖼️ POSTER PICKER RE-DESIGNED
        GestureDetector(
          onTap: _pickPoster,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: _posterBytes != null ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _posterBytes != null ? const Color(0xFFBBF7D0) : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _posterBytes != null ? const Color(0xFFDCFCE7) : Colors.grey.shade200,
                  radius: 20,
                  child: Icon(
                    _posterBytes != null ? Icons.done_all_rounded : Icons.cloud_upload_outlined,
                    color: _posterBytes != null ? const Color(0xFF16A34A) : AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _posterBytes != null ? 'Poster berhasil diunggah' : 'Tambahkan Brosur / Poster',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: _posterBytes != null ? const Color(0xFF15803D) : Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _posterBytes != null ? _posterFileName ?? '' : 'Format JPG/PNG (Opsional)',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_posterBytes != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                    onPressed: () => setState(() {
                      _posterBytes = null;
                      _posterFileName = null;
                      _posterContentType = null;
                    }),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: _isPublishing ? 'Memproses...' : 'Publikasikan Lomba',
            icon: Icons.check_circle_rounded,
            onPressed: _isPublishing ? null : _publish,
          ),
        ),
      ],
    );
  }

  // ── Form: Mencari Tim ─────────────────────────────────────────────────────
  Widget _buildCariTimForm() {
    return Column(
      key: const ValueKey('CariTimForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _cariTimTitleController,
          decoration: _inputDecoration(
            'Judul postingan iklan',
            hint: 'Contoh: UI/UX Designer siap gabung tim Gemastik',
            prefix: const Icon(Icons.rocket_launch_outlined, color: AppColors.primaryBlue, size: 20),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cariTimDescController,
          minLines: 3,
          maxLines: 5,
          decoration: _inputDecoration(
            'Perkenalan diri & keunggulanmu',
            hint: 'Tulis keahlianmu, riwayat portofolio singkat, atau antusiasme lombamu.',
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cariTimSkillsController,
          decoration: _inputDecoration(
            'Keahlian / Tech Stack utama',
            hint: 'Contoh: Figma, Flutter, Golang',
            prefix: const Icon(Icons.workspace_premium_outlined, color: AppColors.primaryBlue, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cariTimCompetitionController,
          decoration: _inputDecoration(
            'Lomba target utama',
            hint: 'Contoh: GEMASTIK, PKM-KC, Hackathon',
            prefix: const Icon(Icons.flag_outlined, color: AppColors.primaryBlue, size: 20),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Nama lomba wajib diisi' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cariTimNotesController,
          minLines: 2,
          maxLines: 3,
          decoration: _inputDecoration(
            'Ketersediaan & kontak (opsional)',
            hint: 'Contoh: Fleksibel setelah jam kuliah, Kontak WA: 0812...',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: _isPublishing ? 'Memproses...' : 'Sebarkan Profil Saya',
            icon: Icons.send_rounded,
            onPressed: _isPublishing ? null : _publish,
          ),
        ),
      ],
    );
  }
}