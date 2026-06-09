import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/skill_chip.dart';
import '../../data/models/lecturer_model.dart';
import 'lecturer_detail_screen.dart';

class LecturerFinderScreen extends StatefulWidget {
  const LecturerFinderScreen({super.key});

  @override
  State<LecturerFinderScreen> createState() => _LecturerFinderScreenState();
}

class _LecturerFinderScreenState extends State<LecturerFinderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppStateScope.of(context).loadLecturers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dosen Pembimbing')),
      body: RefreshIndicator(
        color: AppColors.primaryBlue,
        backgroundColor: Colors.white,
        onRefresh: () async {
          // Mengambil ulang data dosen saat layar ditarik ke bawah
          await state.loadLecturers();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          // Memastikan list tetap bisa ditarik meski datanya sedikit/kosong
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (state.isLecturersLoading) ...[
              const LinearProgressIndicator(
                minHeight: 4,
                color: AppColors.primaryBlue,
                backgroundColor: AppColors.lightBlue,
              ),
              const SizedBox(height: 12),
            ],
            if (state.lecturerError != null) ...[
              CustomCard(
                color: AppColors.lightBlue,
                padding: const EdgeInsets.all(12),
                child: Text(
                  state.lecturerError!,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ...state.lecturers.map(
              (lecturer) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _LecturerCard(lecturer: lecturer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LecturerCard extends StatelessWidget {
  const _LecturerCard({required this.lecturer});

  final LecturerModel lecturer;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isActionEnabled = lecturer.isAvailable && !lecturer.hasRequested;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.lightBlue,
                child: Text(
                  lecturer.name.isEmpty
                      ? '?'
                      : lecturer.name.replaceFirst('Dr. ', '').characters.first,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lecturer.name, style: AppTextStyles.subtitle),
                    const SizedBox(height: 4),
                    Text(
                      'Kuota ${lecturer.currentQuota}/${lecturer.maxQuota}',
                      style: AppTextStyles.muted,
                    ),
                  ],
                ),
              ),
              SkillChip(
                label: lecturer.status,
                backgroundColor: lecturer.isAvailable
                    ? AppColors.successGreen.withAlpha(28)
                    : AppColors.alertCoral.withAlpha(26),
                textColor: lecturer.isAvailable
                    ? AppColors.successGreen
                    : AppColors.alertCoral,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lecturer.expertise
                .map((skill) => SkillChip(label: skill, compact: true))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Detail',
                  outlined: true,
                  icon: Icons.person_search_rounded,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LecturerDetailScreen(lecturerId: lecturer.id),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: lecturer.hasRequested
                      ? 'Request Terkirim'
                      : lecturer.isAvailable
                          ? 'Ajukan'
                          : 'Kuota Penuh',
                  icon: lecturer.hasRequested
                      ? Icons.check_circle_rounded
                      : Icons.send_rounded,
                  onPressed: isActionEnabled
                      ? () => _showProposalForm(context, state, lecturer)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Menampilkan form proposal: judul, ringkasan, dan upload PDF ≤ 10 MB.
  Future<void> _showProposalForm(
    BuildContext context,
    dynamic state,
    LecturerModel lecturer,
  ) async {
    final titleCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    File? pickedPdf;
    Uint8List? pdfBytes;
    String? pdfName;
    String? pdfError;
    
    // Variabel penampung data teks sebelum dialog dihancurkan/dismissed
    String finalTitle = '';
    String finalSummary = '';

    // Get teams where student is leader
    final ownedTeams = List.from(state.teams.where((t) => t.leaderId == state.student.id));
    String? selectedTeamId = ownedTeams.isNotEmpty ? ownedTeams.first.id : null;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Mencegah dialog tertutup tidak sengaja tanpa menekan batal
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> pickPdf() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );
              if (result == null) return;
              
              final file = result.files.single;
              final bytes = file.bytes;
              final size = bytes?.length ?? file.size; // Fallback ke file.size jika bytes null
              
              if (kIsWeb && bytes == null) return;
              if (!kIsWeb && file.path == null) return;
              
              const maxBytes = 10 * 1024 * 1024; // 10 MB
              if (size > maxBytes) {
                setDialogState(() {
                  pdfError = 'File melebihi batas 10 MB.';
                  pickedPdf = null;
                  pdfName = null;
                  pdfBytes = null;
                });
                return;
              }
              
              if (kIsWeb && bytes != null) {
                setDialogState(() {
                  pickedPdf = null;
                  pdfName = file.name;
                  pdfError = null;
                  pdfBytes = bytes;
                });
              } else if (file.path != null) {
                final fileObj = File(file.path!);
                setDialogState(() {
                  pickedPdf = fileObj;
                  pdfName = file.name;
                  pdfError = null;
                  pdfBytes = null;
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text('Ajukan ke ${lecturer.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team Selection
                    if (ownedTeams.length > 1) ...[
                      const Text('Pilih Tim', style: AppTextStyles.subtitle),
                      const SizedBox(height: 8),
                      ...ownedTeams.map((team) => RadioListTile<String>(
                            title: Text('${team.name} (${team.competitionName})'),
                            value: team.id,
                            groupValue: selectedTeamId,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedTeamId = value;
                              });
                            },
                          )),
                      const SizedBox(height: 16),
                    ],
                    // Judul Proposal
                    const Text('Judul Proposal', style: AppTextStyles.subtitle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleCtrl,
                      decoration: _inputDecor('Masukkan judul proposal...'),
                    ),
                    const SizedBox(height: 16),

                    // Ringkasan
                    const Text('Ringkasan Proposal', style: AppTextStyles.subtitle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: summaryCtrl,
                      minLines: 3,
                      maxLines: 6,
                      decoration: _inputDecor(
                        'Deskripsikan ide, tujuan, dan kebutuhan bimbingan...',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upload PDF
                    const Text('File Proposal (PDF)', style: AppTextStyles.subtitle),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: pickPdf,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSoftGray,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: pdfError != null
                                ? AppColors.alertCoral
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (pickedPdf != null || pdfBytes != null)
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.upload_file_rounded,
                              color: (pickedPdf != null || pdfBytes != null)
                                  ? AppColors.alertCoral
                                  : AppColors.primaryBlue,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                pdfName ?? 'Pilih file PDF (maks 10 MB)',
                                style: AppTextStyles.body.copyWith(
                                  color: (pickedPdf != null || pdfBytes != null)
                                      ? AppColors.textBody
                                      : AppColors.textHint,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (pickedPdf != null || pdfBytes != null)
                              GestureDetector(
                                onTap: () => setDialogState(() {
                                  pickedPdf = null;
                                  pdfBytes = null;
                                  pdfName = null;
                                  pdfError = null;
                                }),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.textGray,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (pdfError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        pdfError!,
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.alertCoral,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    // Amankan data ke variabel lokal sebelum memicu pop/dispose
                    finalTitle = titleCtrl.text.trim();
                    finalSummary = summaryCtrl.text.trim();
                    
                    if (finalTitle.isEmpty || finalSummary.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Judul dan ringkasan wajib diisi.'),
                        ),
                      );
                      return;
                    }
                    if (ownedTeams.length > 1 && selectedTeamId == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Silakan pilih tim untuk proposal.'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Kirim'),
                ),
              ],
            );
          },
        );
      },
    );

    // Membuang controller dengan aman dari memori karena dialog sudah ditutup
    titleCtrl.dispose();
    summaryCtrl.dispose();

    if (result != true) return;

    // Proses unggah file dokumen PDF ke server jika ada
    String proposalLink = '';
    if (pickedPdf != null) {
      proposalLink = await state.uploadProposalPdf(
        pickedPdf!,
        lecturer.id,
      ) ?? '';
    } else if (pdfBytes != null) {
      proposalLink = await state.uploadProposalPdfBytes(
        pdfBytes!,
        lecturer.id,
        pdfName ?? 'proposal.pdf',
      ) ?? '';
    }

    // Mengirimkan data final yang telah diamankan ke API
    final message = await state.requestLecturerApi(
      lecturer.id,
      proposalTitle: finalTitle,
      proposalSummary: finalSummary,
      proposalLink: proposalLink,
      teamId: selectedTeamId,
    );

    if (!context.mounted) return;
    
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Berhasil'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Oke'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.backgroundSoftGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
      );
}