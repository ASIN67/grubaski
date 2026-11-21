import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_release_info.dart';
import '../services/app_update_service.dart';
import '../utils/app_colors.dart';

/// Aesthetic Black OLED + Violet modal bottom sheet informing the user of an
/// available application update and providing direct download/installation.
class UpdatePromptDialog extends StatefulWidget {
  final AppReleaseInfo release;

  const UpdatePromptDialog({super.key, required this.release});

  /// Displays the update prompt as an aesthetic modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required AppReleaseInfo release,
  }) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: !release.isMandatory,
      enableDrag: !release.isMandatory,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => UpdatePromptDialog(release: release),
    );
  }

  @override
  State<UpdatePromptDialog> createState() => _UpdatePromptDialogState();
}

class _UpdatePromptDialogState extends State<UpdatePromptDialog> {
  bool _isDownloading = false;

  Future<void> _handleUpdate() async {
    setState(() => _isDownloading = true);

    final success =
        await AppUpdateService.instance.launchDownload(widget.release.downloadUrl);

    if (mounted) {
      setState(() => _isDownloading = false);
      if (success && !widget.release.isMandatory) {
        Navigator.of(context).pop();
      } else if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nie udało się otworzyć linku pobierania. Sprawdź połączenie z internetem.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDate =
        DateFormat('dd.MM.yyyy').format(widget.release.publishedAt);

    return PopScope(
      canPop: !widget.release.isMandatory,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              if (!widget.release.isMandatory)
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

              // Header Icon & Title
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Nowa wersja!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'v${widget.release.version}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              'Wydano: $formattedDate',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            if (widget.release.isMandatory) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.error.withOpacity(0.4),
                                  ),
                                ),
                                child: const Text(
                                  'Wymagana',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Changelog Box
              if (widget.release.releaseNotes != null &&
                  widget.release.releaseNotes!.trim().isNotEmpty) ...[
                Text(
                  'Co nowego w tej aktualizacji:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.release.releaseNotes!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isDownloading ? null : _handleUpdate,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, size: 20),
                  label: Text(
                    _isDownloading
                        ? 'Pobieranie aktualizacji...'
                        : 'Pobierz i zaktualizuj aplikację',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              if (!widget.release.isMandatory) ...[
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Przypomnij mi później',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
